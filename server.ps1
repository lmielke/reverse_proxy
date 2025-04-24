<#
.EXAMPLE
Uses params.json for port/IP config, but always asks for SSH login:
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
    }
}

# Fallbacks if not set
if (-not $UI_PORT -or -not $localUI_PORT) {
    if (-not $p) { $p = "3333:3000" }
    $UI_PORT, $localUI_PORT = $p -split ':'
}

if (-not $ip) { $ip = "0.0.0.0:localhost" }
$remoteIP, $localIP = $ip -split ':'

# Always ask for SSH login
Write-Host "`n🟡 SSH login (user@host):"
do {
    $sshLogin = Read-Host "Enter SSH login"
} until ($sshLogin -match '^\S+@\d{1,3}(\.\d{1,3}){3}$')

Write-Host "`nUsing parameters:"
Write-Host "  UI_PORT       (remote): $UI_PORT"
Write-Host "  localUI_PORT  (local):  $localUI_PORT"
Write-Host "  remote IP:              $remoteIP"
Write-Host "  local IP:               $localIP"
Write-Host "  SSH login:              $sshLogin`n"

if ((Read-Host "Press Y to continue, anything else to cancel").ToLower() -ne 'y') {
    Write-Host "Aborted."
    exit
}

Write-Host "🔐 Testing SSH login to $sshLogin ..."
$check = ssh -o BatchMode=yes -o ConnectTimeout=5 $sshLogin 'echo SSH_OK' 2>&1
if ($LASTEXITCODE -ne 0 -or $check -notmatch 'SSH_OK') {
    Write-Host "❌ SSH test failed:`n$check"
    exit 1
}
Write-Host "✔ SSH login succeeded.`n"

$sshCommand = "ssh -o GatewayPorts=yes -o ServerAliveInterval=30 -N " +
              "-R $remoteIP`:$UI_PORT`:$localIP`:$localUI_PORT $sshLogin"
Write-Host "⚠️  About to run this reverse tunnel:"
Write-Host $sshCommand "`n"

Invoke-Expression $sshCommand
