# =====================================================================
# PAYNOTIFY AWS Troubleshooting Assessment
# Scenario 2 - Task 4 : Run the End-to-End Health Check
#
# Checks performed (all must pass):
#   1. reports/healthcheck-latest.txt exists in the app data bucket
#   2. The report was produced by pn-app-01
#   3. INTERNET, S3_LIST, S3_WRITE, S3_READ and RDS_TCP are all PASS
#
# Read-only: this validator never changes the environment.
# =====================================================================

$ErrorActionPreference = 'Stop'

$region = 'us-east-1'
Set-DefaultAWSRegion -Region $region

$did = "$deploymentid".Trim()
Write-Host "Deployment ID: $did"

$status = 'Failed'
$script:passes = 0
$script:fails  = New-Object System.Collections.Generic.List[string]

function Get-Pattern([string]$base) { if ($did) { return "$base-$did" } else { return "$base-*" } }
function Add-Check([bool]$ok, [string]$failText) {
    if ($ok) { $script:passes++ } else { $script:fails.Add($failText) }
}
function Get-TaggedInstance([string]$base) {
    $f = @(
        @{ Name = 'tag:Name'; Values = @(Get-Pattern $base) },
        @{ Name = 'instance-state-name'; Values = @('pending', 'running', 'stopping', 'stopped') }
    )
    return (Get-EC2Instance -Filter $f).Instances | Select-Object -First 1
}
function Get-TaggedSG([string]$base) {
    return Get-EC2SecurityGroup -Filter @{ Name = 'tag:Name'; Values = @(Get-Pattern $base) } | Select-Object -First 1
}
function Get-TaggedSubnet([string]$base) {
    return Get-EC2Subnet -Filter @{ Name = 'tag:Name'; Values = @(Get-Pattern $base) } | Select-Object -First 1
}
function Get-InstanceRoleArn($inst) {
    if (-not $inst.IamInstanceProfile) { return $null }
    $profName = ($inst.IamInstanceProfile.Arn -split '/')[-1]
    $prof = Get-IAMInstanceProfile -InstanceProfileName $profName
    if ($prof.Roles.Count -gt 0) { return $prof.Roles[0].Arn }
    return $null
}
function Test-Allowed([string]$roleArn, [string]$action, [string]$resource) {
    $r = Test-IAMPrincipalPolicy -PolicySourceArn $roleArn -ActionName $action -ResourceArn $resource
    return (@($r | Where-Object { "$($_.EvalDecision)" -eq 'allowed' }).Count -gt 0)
}
function Test-SSMOnline([string]$instanceId) {
    $info = Get-SSMInstanceInformation -Filter @{ Key = 'InstanceIds'; Values = @($instanceId) }
    return ($info -and "$($info.PingStatus)" -eq 'Online')
}
function Invoke-SSMShell([string]$instanceId, [string[]]$commands, [int]$waitSec = 30) {
    $cmd = Send-SSMCommand -InstanceId $instanceId -DocumentName 'AWS-RunShellScript' -Parameter @{ commands = $commands } -TimeoutSecond 30
    $deadline = (Get-Date).AddSeconds($waitSec)
    $st = ''; $inv = $null
    do {
        Start-Sleep -Seconds 3
        $inv = Get-SSMCommandInvocation -CommandId $cmd.CommandId -InstanceId $instanceId -Details $true -ErrorAction SilentlyContinue
        $st = "$($inv.Status)"
    } while (($st -in @('', 'Pending', 'InProgress', 'Delayed')) -and ((Get-Date) -lt $deadline))
    $outText = ''
    if ($inv -and $inv.CommandPlugins) { $outText = "$($inv.CommandPlugins[0].Output)" }
    return @{ Status = $st; Output = $outText }
}
function ConvertTo-IPNumber([string]$ip) {
    $b = [System.Net.IPAddress]::Parse($ip).GetAddressBytes(); [Array]::Reverse($b)
    return [BitConverter]::ToUInt32($b, 0)
}
function Test-InCidr([string]$ip, [string]$cidr) {
    $p = $cidr.Split('/'); $bits = [int]$p[1]
    if ($bits -eq 0) { return $true }
    $mask = [uint32]([math]::Pow(2, 32) - [math]::Pow(2, 32 - $bits))
    return (((ConvertTo-IPNumber $ip) -band $mask) -eq ((ConvertTo-IPNumber $p[0]) -band $mask))
}
function Get-SampleIP([string]$cidr) {
    $n = (ConvertTo-IPNumber ($cidr.Split('/')[0])) + 10
    $b = [BitConverter]::GetBytes([uint32]$n); [Array]::Reverse($b)
    return ([System.Net.IPAddress]::new($b)).ToString()
}
# $perms: IpPermission list. Returns true if TCP $port is allowed from/to the SG id or a CIDR containing $ip.
function Test-SGRule($perms, [int]$port, [string]$sgId, [string]$ip) {
    foreach ($p in $perms) {
        $proto = "$($p.IpProtocol)"
        $portOk = ($proto -eq '-1') -or (($proto -eq 'tcp' -or $proto -eq '6') -and $p.FromPort -le $port -and $p.ToPort -ge $port)
        if (-not $portOk) { continue }
        if ($sgId -and ($p.UserIdGroupPairs | Where-Object { $_.GroupId -eq $sgId })) { return $true }
        if ($ip) { foreach ($r in $p.Ipv4Ranges) { if ($r.CidrIp -and (Test-InCidr $ip $r.CidrIp)) { return $true } } }
    }
    return $false
}
function Get-NaclDecision($entries, [bool]$egress, [string]$ip, [int]$port) {
    $rules = $entries | Where-Object { $_.Egress -eq $egress -and $_.RuleNumber -lt 32767 -and $_.CidrBlock } | Sort-Object RuleNumber
    foreach ($r in $rules) {
        $proto = "$($r.Protocol)"
        if ($proto -ne '-1' -and $proto -ne '6') { continue }
        if ($proto -eq '6' -and $r.PortRange -and ($port -lt $r.PortRange.From -or $port -gt $r.PortRange.To)) { continue }
        if (-not (Test-InCidr $ip $r.CidrBlock)) { continue }
        return "$($r.RuleAction)".ToLower()
    }
    return 'deny'
}

$message = ''
try {

    $app = Get-TaggedInstance 'pn-app-01'
    $bucket = Get-S3Bucket | Where-Object { $_.BucketName -like ((Get-Pattern 'pn-appdata') + '-*') } | Select-Object -First 1
    if (-not $app -or -not $bucket) { Add-Check $false 'pn-app-01 or the pn-appdata bucket was not found. Contact your instructor.' }
    else {
        $key = 'reports/healthcheck-latest.txt'
        $obj = Get-S3Object -BucketName $bucket.BucketName -Key $key | Where-Object { $_.Key -eq $key }
        if (-not $obj) { Add-Check $false 'Task 4 - reports/healthcheck-latest.txt is not in the bucket. Run sudo /opt/paynotify/healthcheck.sh on pn-app-01.' }
        else {
            Add-Check $true ''
            $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("pn-hc-" + [guid]::NewGuid().ToString() + ".txt")
            Read-S3Object -BucketName $bucket.BucketName -Key $key -File $tmp | Out-Null
            $txt = Get-Content -Path $tmp -Raw
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
            Write-Host $txt
            Add-Check ($txt -match "INSTANCE=$($app.InstanceId)") 'Task 4 - the report was not produced by pn-app-01. Run the health check on pn-app-01.'
            $bad = @()
            foreach ($c in @('INTERNET', 'S3_LIST', 'S3_WRITE', 'S3_READ', 'RDS_TCP')) { if ($txt -notmatch "$c=PASS") { $bad += $c } }
            Add-Check ($bad.Count -eq 0) ("Task 4 - the latest report still shows a failure for: " + ($bad -join ', ') + '. Fix it and run the health check again.')
        }
    }

    $total = $script:passes + $script:fails.Count
    if ($script:fails.Count -eq 0 -and $script:passes -gt 0) {
        $status  = 'Succeeded'
        $message = "All $total checks passed."
    }
    else {
        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add("$($script:passes) of $total checks passed. To fix:")
        $n = 0
        foreach ($f in $script:fails) {
            $n++
            if ($script:fails.Count -gt 1) { $lines.Add("$n) $f") } else { $lines.Add($f) }
        }
        $message = ($lines -join "`n")
    }
}
catch {
    $status  = 'Failed'
    $message = "The validation could not complete: $($_.Exception.Message). Try again shortly, and contact your instructor if it persists."
}

Write-Host $message
$body = @{ Status = $status; Message = $message } | ConvertTo-Json -Compress

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [System.Net.HttpStatusCode]::OK
        Body       = $body
    })
