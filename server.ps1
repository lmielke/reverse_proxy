<#
 server.ps1
 ──────────
 • Reads LOCAL_UI_PORT, TUNNEL_UI_PORT and ipMapping from params.json (if present)
 • Always asks once for the SSH-login string  ( user@ip )
 • Shows the exact SSH command that will be launched
 • Starts the tunnel **detached** (it keeps running after the script exits)
#>

param(
    [string]$p,   # fallback  "TUNNEL:LOCAL"  e.g. 3333:3000
    [string]$ip   # fallback  "0.0.0.0:localhost"
)

$ErrorActionPreference = 'Stop'

# ── Sanity-check host ────────────────────────────────────────────────────
$safeHosts = @('while-ai-0','while-ai-1')
if ( ($env:COMPUTERNAME).ToLower() -notin $safeHosts ) {
    throw "Must run on while-ai-0 or while-ai-1 (current: $env:COMPUTERNAME)"
}

# ── Load params.json if available ────────────────────────────────────────
$paramFile = Join-Path $PSScriptRoot 'params.json'
if (Test-Path $paramFile) {
    $params        = Get-Content $paramFile | ConvertFrom-Json
    $UI_PORT       = $params.TUNNEL_UI_PORT
    $localUI_PORT  = $params.LOCAL_UI_PORT
    $ip            = $params.ipMapping
}

# ── Fallbacks when params.json missing or incomplete ─────────────────────
if (-not $UI_PORT -or -not $localUI_PORT) {
    if (-not $p) { $p = '3333:3000' }
    $UI_PORT, $localUI_PORT = $p -split ':'
}
if (-not $ip) { $ip = '0.0.0.0:localhost' }
$remoteIP, $localIP = $ip -split ':'

# ── Show configuration & expected SSH command ────────────────────────────
Write-Host ""
Write-Host "Parameters in use:"
Write-Host "  Remote UI_PORT       : $UI_PORT"
Write-Host "  Local  UI_PORT       : $localUI_PORT"
Write-Host "  Remote bind IP       : $remoteIP"
Write-Host "  Local  forward host  : $localIP"
Write-Host ""
$sshPreview = "ssh -o GatewayPorts=yes -o ServerAliveInterval=30 -N " +
              "-R ${remoteIP}:${UI_PORT}:${localIP}:${localUI_PORT} <SSH_login>"
Write-Host "SSH command that will be launched:"
Write-Host "  $sshPreview"
Write-Host ""

# ── Prompt once for SSH login string ─────────────────────────────────────
$sshLogin = Read-Host "Enter SSH login (user@ip) to start tunnel, or press <Enter> to abort"
if (-not $sshLogin) {
    Write-Host "Aborted."
    exit 0
}
if ($sshLogin -notmatch '^\S+@\d{1,3}(\.\d{1,3}){3}$') {
    throw "Invalid format – expected user@ip"
}

# ── Quick test of SSH connectivity (5 s timeout) ─────────────────────────
Write-Host ""
Write-Host "[*] Testing SSH connectivity..."
$test = ssh -o BatchMode=yes -o "ConnectTimeout=5" $sshLogin "exit" 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "SSH connection failed – check credentials / firewall."
}
Write-Host "OK – SSH reachable.`n"

# ── Build argument list & start detached tunnel ──────────────────────────
$sshArgs = @(
    '-o', 'GatewayPorts=yes',
    '-o', 'ServerAliveInterval=30',
    '-N',
    '-R', "${remoteIP}:${UI_PORT}:${localIP}:${localUI_PORT}",
    $sshLogin
)

Start-Process -FilePath 'ssh' -ArgumentList $sshArgs `
              -WindowStyle Hidden -NoNewWindow

Write-Host "Tunnel started in background."
Write-Host "Forwarded  $remoteIP:$UI_PORT  →  $localIP:$localUI_PORT (local)."
