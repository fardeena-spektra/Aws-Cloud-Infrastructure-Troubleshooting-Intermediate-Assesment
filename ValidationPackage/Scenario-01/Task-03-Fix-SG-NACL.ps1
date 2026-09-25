# =====================================================================
# PAYNOTIFY AWS Troubleshooting Assessment
# Scenario 1 - Task 3 : Fix the Web Tier Security Group and Network ACL
#
# Checks performed (all must pass):
#   1. pn-web-sg allows TCP 8080 from pn-alb-sg
#   2. The stale 10.99.0.0/16 rule on TCP 8080 is removed
#   3. pn-web-nacl allows inbound TCP 8080 from every ALB node
#   4. pn-web-nacl allows outbound return traffic to ephemeral ports on every ALB node
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

    $webSg = Get-TaggedSG 'pn-web-sg'
    $albSg = Get-TaggedSG 'pn-alb-sg'
    if (-not $webSg -or -not $albSg) { Add-Check $false 'The security groups pn-web-sg or pn-alb-sg were not found. Contact your instructor.' }
    else {
        $fromAlb = Test-SGRule $webSg.IpPermissions 8080 $albSg.GroupId $null
        Add-Check $fromAlb 'Task 3 - pn-web-sg has no inbound rule for TCP 8080 with pn-alb-sg as the source.'
        $stale = Test-SGRule $webSg.IpPermissions 8080 $null '10.99.0.10'
        Add-Check (-not $stale) 'Task 3 - the stale inbound rule for TCP 8080 from 10.99.0.0/16 is still present on pn-web-sg. Remove it.'
    }

    $sn = Get-TaggedSubnet 'pn-web-subnet'
    if (-not $sn) { Add-Check $false 'The subnet pn-web-subnet was not found. Contact your instructor.' }
    else {
        $nacl = Get-EC2NetworkAcl -Filter @{ Name = 'association.subnet-id'; Values = @($sn.SubnetId) } | Select-Object -First 1
        $albName = if ($did) { "pn-alb-$did" } else { $null }
        $lb = if ($albName) { Get-ELB2LoadBalancer -Name $albName -ErrorAction SilentlyContinue } else { Get-ELB2LoadBalancer | Where-Object { $_.LoadBalancerName -like 'pn-alb-*' } | Select-Object -First 1 }
        $ips = @()
        if ($lb) {
            $eni = Get-EC2NetworkInterface -Filter @{ Name = 'description'; Values = @("ELB app/$($lb.LoadBalancerName)/*") }
            $ips = @($eni | ForEach-Object { $_.PrivateIpAddress } | Where-Object { $_ })
        }
        if ($ips.Count -eq 0) {
            foreach ($b in @('pn-public-subnet-a', 'pn-public-subnet-b')) { $s = Get-TaggedSubnet $b; if ($s) { $ips += (Get-SampleIP $s.CidrBlock) } }
        }
        $inOk = $true; $outOk = $true
        foreach ($ip in $ips) {
            if ((Get-NaclDecision $nacl.Entries $false $ip 8080) -ne 'allow') { $inOk = $false }
            if ((Get-NaclDecision $nacl.Entries $true $ip 40000) -ne 'allow') { $outOk = $false }
        }
        Add-Check $inOk 'Task 3 - pn-web-nacl blocks inbound TCP 8080 from the load balancer subnets.'
        Add-Check $outOk 'Task 3 - pn-web-nacl still blocks outbound return traffic to ephemeral ports (1024-65535) inside the VPC.'
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
