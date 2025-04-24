<#
 server.ps1   –  start/maintain an SSH reverse tunnel
 • Reads LOCAL_UI_PORT, TUNNEL_UI_PORT and ipMapping from params.json.
 • Prompts once for the SSH-login string (user@ip).
 • Shows the exact SSH command that will be spawned.
 • Starts the tunnel detached; the script returns immediately.
#>

param(
    [string]$p,   # fallback "TUNNEL:LOCAL"  e.g. 3333:3000
    [string]$ip   # fallback "0.0.0.0:localhost"
)

$ErrorActionPreference = 'Stop'

# ── Host guard ───────────────────────────────────────────────────────────
$safeHosts = @('while-ai-0','while-ai-1')
if ( ($env:COMPUTERNAME).ToLower() -notin $safeHosts ) {
    throw "Must run on while-ai-0 or while-ai-1 (current: $env:COMPUTERNAME)"
}

# ── Load params.json if present ──────────────────────────────────────────
$paramFile = Join-Path $PSScriptRoot 'params.json'
if (Test-Path $paramFile) {
    $params        = Get-Content $paramFile | ConvertFrom-Json
    $UI_PORT       = $params.TUNNEL_UI_PORT
    $localUI_PORT  = $params.LOCAL_UI_PORT
    $ip            = $params.ipMapping
}

# ── Fallbacks ────────────────────────────────────────────────────────────
if (-not $UI_PORT -or -not $localUI_PORT) {
    if (-not $p) { $p = '3333:3000' }
    $UI_PORT, $localUI_PORT = $p -split ':'
}
if (-not $ip) { $ip = '0.0.0.0:localhost' }
$remoteIP, $localIP = $ip -split ':'

# ── Display configuration ───────────────────────────────────────────────
Write-Host ''
Write-Host 'Parameters in use:'
Write-Host "  Remote UI_PORT       : $UI_PORT"
Write-Host "  Local  UI_PORT       : $localUI_PORT"
Write-Host "  Remote bind IP       : $remoteIP"
Write-Host "  Local  forward host  : $localIP"
Write-Host ''

$sshPreview = @(
  'ssh',
  '-o', 'GatewayPorts=yes',
  '-o', 'ServerAliveInterval=30',
  '-N',
  '-R', "${remoteIP}:${UI_PORT}:${localIP}:${localUI_PORT}",
  '<SSH_login>'
) -join ' '

Write-Host 'SSH command that will be launched:'
Write-Host "  $sshPreview"
Write-Host ''

# ── Prompt once for SSH login ───────────────────────────────────────────
$sshLogin = Read-Host 'Enter SSH login (user@ip) to start tunnel, or press <Enter> to abort'
if (-not $sshLogin) {
    Write-Host 'Aborted.'
    exit 0
}
if ($sshLogin -notmatch '^\S+@\d{1,3}(\.\d{1,3}){3}$') {
    throw 'Invalid format - expected user@ip'
}

# ── Quick connectivity test (5-second timeout) ──────────────────────────
Write-Host ''
Write-Host "[*] Testing SSH connectivity..."
$null = ssh -o BatchMode=yes -o "ConnectTimeout=5" $sshLogin 'exit'
if ($LASTEXITCODE -ne 0) {
    throw 'SSH connection failed - check credentials or firewall.'
}
Write-Host 'OK - SSH reachable.'
Write-Host ''

# ── Build argument list & launch detached tunnel ────────────────────────
$sshArgs = @(
    '-o', 'GatewayPorts=yes',
    '-o', 'ServerAliveInterval=30',
    '-N',
    '-R', "${remoteIP}:${UI_PORT}:${localIP}:${localUI_PORT}",
    $sshLogin
)

# launch detached tunnel  (remove -NoNewWindow)
Start-Process -FilePath 'ssh' -ArgumentList $sshArgs -WindowStyle Hidden

Write-Host ("Forwarded  {0}:{1} -> {2}:{3}  (tunnel running detached)." `
            -f $remoteIP,$UI_PORT,$localIP,$localUI_PORT)
