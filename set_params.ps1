# set_params.ps1
<#
Prompts for reverse proxy parameters and saves them to params.json.
Includes both LOCAL_UI_PORT and TUNNEL_UI_PORT (used by compose.sh).
#>

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

$params = @{}

Write-Host "🛠  Reverse Proxy Parameter Setup"
Write-Host "You'll be asked for a few values. Others will be auto-generated.`n"

# LOCAL_UI_PORT
Write-Host "🟡 LOCAL_UI_PORT:"
Write-Host "This is the port your Open Web UI runs on locally (default: 3000)"
$localPort = Read-Host "Enter LOCAL_UI_PORT (or press Enter to use 3000)"
if (-not $localPort) { $localPort = "3000" }
$params.LOCAL_UI_PORT = $localPort

# TUNNEL_UI_PORT
Write-Host "`n🟡 TUNNEL_UI_PORT:"
Write-Host "This is the remote port used for the SSH tunnel (e.g., 3333)"
do {
    $remotePort = Read-Host "Enter TUNNEL_UI_PORT"
} until ($remotePort -match '^\d+$')
$params.TUNNEL_UI_PORT = $remotePort

# Build portMapping string
$params.portMapping = "${remotePort}:${localPort}"

# UI_IP (of your local machine)
Write-Host "`n🟡 UI_IP:"
Write-Host "This is your local machine IP that the remote host should reach (e.g., 192.168.0.235)"
do {
    $params.UI_IP = Read-Host "Enter UI_IP"
} until ($params.UI_IP -match '^\d{1,3}(\.\d{1,3}){3}$')

# Tunnel target
Write-Host "`n🟡 SSH Tunnel Target:"
Write-Host "Format: user@ip (e.g., root@134.122.65.220)"
do {
    $params.tunnelTarget = Read-Host "Enter SSH tunnel target"
} until ($params.tunnelTarget -match '^\S+@\d{1,3}(\.\d{1,3}){3}$')

# IP Mapping is fixed
$params.ipMapping = "0.0.0.0:localhost"

# Save
$params | ConvertTo-Json -Depth 3 | Out-File -Encoding UTF8 params.json
Write-Host "`n💾 Saved config to params.json"
Write-Host "You can re-run this script anytime to update it."
