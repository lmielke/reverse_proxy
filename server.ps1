<#
.EXAMPLE
Uses params.json for tunnel config and prompts once for SSH login:
  .\server.ps1
#>

param(
    [string]$p,
    [string]$ip
)

$ErrorActionPreference = 'Stop'
$hostname = (hostname).ToLower()

if ($hostname -notin @('while-ai-0','while-ai-1')) {
    throw "Must run on while-ai-0 or while-ai-1 (current: $hostname)"
}

# Load from params.json if available
$paramFile = Join-Path $PSScriptRoot 'params.json'
if (Test-Path $paramFile) {
    $params = Get-Content $paramFile | ConvertFrom-Json
    $UI_PORT       = $params.TUNNEL_UI_PORT
    $localUI_PORT  = $params.LOCAL_UI_PORT
    $ip            = $params.ipMapping
}

# Fallback if no params
if (-not $UI_PORT -or -not $localUI_PORT) {
    if (-not $p) { $p = "3333:3000" }
    $UI_PORT, $localUI_PORT = $p -split ':'
}
if (-not $ip) { $ip = "0.0.0.0:localhost" }
$remoteIP, $localIP = $ip -split ':'

# Print all config
Write-Host "`n\033[1;33mNOTE: These are the parameters we will use:\033[0m"
Write-Host "  Remote (UI_PORT):     $UI_PORT"
Write-Host "  Local (LOCAL_UI_PORT):$localUI_PORT"
Write-Host "  Remote IP:            $remoteIP"
Write-Host "  Local IP:             $localIP"

# Preview connection string
$sshPreview = "ssh -o GatewayPorts=yes -o ServerAliveInterval=30 -N -R " +
              "$remoteIP:$UI_PORT:$localIP:$localUI_PORT SSH_login"
Write-Host "`nThis is the connection string:"
Write-Host $sshPreview

# Single prompt
$sshLogin = Read-Host "`nTo continue, enter the SSH login (e.g. root@1.2.3.4). Press Enter to abort"
if (-not $sshLogin) {
    Write-Host "Aborted."
    exit 0
}
if ($sshLogin -notmatch '^\S+@\d{1,3}(\.\d{1,3}){3}$') {
    throw "Invalid SSH login format (expected user@ip)"
}

# Test SSH login
Write-Host "🔐 Testing SSH login to $sshLogin ..."
$check = ssh -o BatchMode=yes -o ConnectTimeout=
