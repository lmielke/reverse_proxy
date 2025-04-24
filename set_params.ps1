# set_params.ps1
<#
Prompts for reverse proxy parameters and saves them to params.json.
Excludes tunnelTarget — assumed to be handled outside this config.
#>

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

$params = @{}

Write-Host "🛠  Reverse Proxy Parameter Setup"
Write-Host "You'll be asked for a few values. Others will be auto-generated.`n"

# LOCAL_UI_PORT
Write-Host "🟡 LOCAL_UI_PORT:"
Write-Host "Port where Open Web UI runs locally (default: 3000)"
$localPort = Read-Host "Enter LOCAL_UI_PORT (or press Enter to use 3000)"
if (-not $localPort) { $localPort = "3000" }
$params.LOCAL_UI_PORT = $localPort

# TUNNEL_UI_PORT
Write-Host "`n🟡 TUNNEL_UI_PORT:"
Write-Host "Port exposed via SSH tunnel (e.g., 3333)"
do {
    $remotePort = Read-Host "Enter TUNNEL_UI_PORT"
} until ($remotePort -match '^\d+$')
$params.TUNNEL_UI_PORT = $remotePort

# Build portMapping
$params.portMapping = "${remotePort}:${localPort}"

# UI_IP
Write-Host "`n🟡 UI_IP:"
Write-Host "Your local machine IP reachable from the droplet (e.g., 192.168.0.235)"
do {
    $params.UI_IP = Read-Host "Enter UI_IP"
} until ($params.UI_IP -match '^\d{1,3}(\.\d{1,3}){3}$')

# IP Mapping is static
$params.ipMapping = "0.0.0.0:localhost"

# Save
$paramsPath = Join-Path $PSScriptRoot "params.json"
$params | ConvertTo-Json -Depth 3 | Out-File -Encoding UTF8 $paramsPath

Write-Host "`n💾 Saved config to params.json"
Write-Host "You can re-run this script anytime to update it."
