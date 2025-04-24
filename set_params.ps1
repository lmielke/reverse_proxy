# set_params.ps1
<#
Prompts for required reverse proxy parameters and saves them to params.json.
Simplified: Only prompts for essentials and calculates derived values.
#>

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

$params = @{}

Write-Host "🛠  Reverse Proxy Parameter Setup"
Write-Host "You'll be asked for a few values. Others will be auto-generated.`n"

# UI_PORT
Write-Host "🟡 UI_PORT:"
Write-Host "Port your Open Web UI runs on (default: 3000)"
$uiPort = Read-Host "Enter UI_PORT (or press Enter to use 3000)"
if (-not $uiPort) { $uiPort = "3000" }
$params.UI_PORT = $uiPort

# UI_IP
Write-Host "`n🟡 UI_IP:"
Write-Host "IP of the machine running Open Web UI (e.g., 192.168.0.111)"
do {
    $params.UI_IP = Read-Host "Enter UI_IP"
} until ($params.UI_IP -match '^\d{1,3}(\.\d{1,3}){3}$')

# Tunnel Target
Write-Host "`n🟡 SSH Tunnel Target:"
Write-Host "Remote host for SSH tunnel (e.g., root@123.456.78.9)"
do {
    $params.tunnelTarget = Read-Host "Enter SSH tunnel target"
} until ($params.tunnelTarget -match '^\S+@\d{1,3}(\.\d{1,3}){3}$')

# Tunnel Port (builds portMapping internally)
Write-Host "`n🟡 Remote Tunnel Port:"
Write-Host "Port used remotely for SSH reverse tunnel (e.g., 3333)"
do {
    $remotePort = Read-Host "Enter SSH tunnel remote port"
} until ($remotePort -match '^\d+$')
$params.portMapping = "${remotePort}:${uiPort}"

# IP mapping is fixed
$params.ipMapping = "0.0.0.0:localhost"

# Save
$params | ConvertTo-Json -Depth 3 | Out-File -Encoding UTF8 params.json
Write-Host "`n💾 Saved config to params.json"
Write-Host "You can re-run this script anytime to update it."
