<#
.EXAMPLE
Uses params.json if present:
  {
    "tunnelTarget": "root@134.122.65.220",
    "ipMapping": "0.0.0.0:localhost",
    "portMapping": "3333:3000",
    "UI_IP": "192.168.0.235",
    "LOCAL_UI_PORT": "3000",
    "TUNNEL_UI_PORT": "3333"
  }

Fallback:
  .\server.ps1 -p 3333:3000 -ip 0.0.0.0:localhost -tunnelTarget root@134.122.65.220
#>

param(
    [string]$p,
    [string]$ip,
    [string]$tunnelTarget
)

$ErrorActionPreference = 'Stop'
$hostname = (hostname).ToLower()

if ($hostname -notin @('while-ai-0','while-ai-1')) {
    throw "Must run on while-ai-0 or while-ai-1 (current: $hostname)"
}

# Load from params.json if available and approved
$paramFile = Join-Path $PSScriptRoot 'params.json'
if (Test-Path $paramFile) {
    Write-Host "📄 Found params.json:"
    Get-Content $paramFile | Write-Host

    $choice = Read-Host "Use these parameters? (Y/N)"
    if ($choice.ToLower() -eq 'y') {
        $params = Get-Content $paramFile | ConvertFrom-Json
        $UI_PORT       = $params.TUNNEL_UI_PORT
        $localUI_PORT  = $params.LOCAL_UI_PORT
        $ip            = $params.ipMapping
        $tunnelTarget  = $params.tunnelTarget

    }
}

# Fallbacks if still not set
if (-not $p) { $p = "3333:3000" }
if (-not $ip) { $ip = "0.0.0.0:localhost" }

# Parse port and IP
$UI_PORT, $localUI_PORT = $p -split ':'
$remoteIP, $localIP = $ip -split ':'

Write-Host "Using parameters:"
Write-Host "  UI_PORT       (remote): $UI_PORT"
Write-Host "  localUI_PORT  (local):  $localUI_PORT"
Write-Host "  remote IP:              $remoteIP"
Write-Host "  local IP:               $localIP"
Write-Host "  tunnel target:          $tunnelTarget`n"

if ((Read-Host "Press Y to continue, anything else to cancel").ToLower() -ne 'y') {
    Write-Host "Aborted."
    exit
}

if (-not $tunnelTarget) {
    $tunnelTarget = Read-Host "Enter SSH target (e.g. root@123.45.67.89)"
}
if ($tunnelTarget -notmatch '^\S+@\d{1,3}(\.\d{1,3}){3}$') {
    throw "Invalid format; expected user@IP"
}

Write-Host "🔐 Testing SSH login to $tunnelTarget ..."
$check = ssh -o BatchMode=yes -o ConnectTimeout=5 $tunnelTarget 'echo SSH_OK' 2>&1
if ($LASTEXITCODE -ne 0 -or $check -notmatch 'SSH_OK') {
    Write-Host "❌ SSH test failed:`n$check"
    exit 1
}
Write-Host "✔ SSH login succeeded.`n"

$sshCommand = "ssh -o GatewayPorts=yes -o ServerAliveInterval=30 -N " +
              "-R $remoteIP`:$UI_PORT`:$localIP`:$localUI_PORT $tunnelTarget"
Write-Host "⚠️  About to run this reverse tunnel:"
Write-Host $sshCommand "`n"

Invoke-Expression $sshCommand
