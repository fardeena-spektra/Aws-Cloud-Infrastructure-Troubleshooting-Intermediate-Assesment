# =====================================================================
# PAYNOTIFY AWS Troubleshooting Assessment
# Scenario 1 - Task 1 : Repair the PAYNOTIFY Statements Bucket
#
# Checks performed (all must pass):
#   1. The pn-statements bucket exists
#   2. All four Block Public Access settings are On
#   3. Bucket versioning is Enabled
#   4. The bucket policy no longer denies uploads to statements/
#   5. statements/test-statement.txt has been uploaded
#
# Read-only: this validator never changes the environment.
# =====================================================================

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------
# Region auto-detect: works in any AWS Region.
# 1. Use $region if CloudLabs passes it, else AWS_REGION / AWS_DEFAULT_REGION.
# 2. Otherwise read the Region of the pn-statements bucket (same stack).
# ---------------------------------------------------------------------
$did = "$deploymentid".Trim()
Write-Host "Deployment ID: $did"

$region = "$region".Trim()
if (-not $region) { $region = "$env:AWS_REGION".Trim() }
if (-not $region) { $region = "$env:AWS_DEFAULT_REGION".Trim() }
if (-not $region) {
    $bucketPattern = if ($did) { "pn-statements-$did-*" } else { 'pn-statements-*' }
    $lookup = Get-S3Bucket -Region 'us-east-1' | Where-Object { $_.BucketName -like $bucketPattern } | Select-Object -First 1
    if ($lookup) {
        $loc = "$((Get-S3BucketLocation -BucketName $lookup.BucketName -Region 'us-east-1').Value)"
        if (-not $loc -or $loc -eq 'US') { $region = 'us-east-1' }
        elseif ($loc -eq 'EU') { $region = 'eu-west-1' }
        else { $region = $loc }
    }
}
if (-not $region) { $region = 'us-east-1' }
Set-DefaultAWSRegion -Region $region
Write-Host "Region: $region"

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

    $bucket = Get-S3Bucket | Where-Object { $_.BucketName -like ((Get-Pattern 'pn-statements') + '-*') } | Select-Object -First 1
    Add-Check ([bool]$bucket) 'The pn-statements bucket was not found. Contact your instructor.'
    if ($bucket) {
        $b = $bucket.BucketName
        Write-Host "Bucket: $b"

        $pab = $null
        try { $pab = Get-S3PublicAccessBlock -BucketName $b } catch { $pab = $null }
        $pabOk = $pab -and $pab.BlockPublicAcls -and $pab.IgnorePublicAcls -and $pab.BlockPublicPolicy -and $pab.RestrictPublicBuckets
        Add-Check ([bool]$pabOk) 'Block all public access is not fully turned On for the bucket. Turn on all four settings.'

        $ver = Get-S3BucketVersioning -BucketName $b
        Add-Check ("$($ver.Status)" -eq 'Enabled') 'Bucket versioning is not Enabled.'

        $policyText = ''
        try { $policyText = Get-S3BucketPolicy -BucketName $b } catch { $policyText = '' }
        $denyUpload = $false
        if ($policyText) {
            $doc = $policyText | ConvertFrom-Json
            foreach ($st in @($doc.Statement)) {
                $acts = @($st.Action) -join ' '
                if ("$($st.Effect)" -eq 'Deny' -and ($acts -match 's3:PutObject' -or $acts -match 's3:\*')) { $denyUpload = $true }
            }
        }
        Add-Check (-not $denyUpload) 'The bucket policy still denies s3:PutObject (statement FreezeStatementUploads). Remove it.'

        $obj = Get-S3Object -BucketName $b -Prefix 'statements/' | Where-Object { $_.Key -eq 'statements/test-statement.txt' }
        Add-Check ([bool]$obj) 'statements/test-statement.txt was not found in the bucket. Upload the file into the statements folder.'
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
