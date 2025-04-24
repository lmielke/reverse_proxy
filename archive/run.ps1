# run.ps1
<#
Runs on the droplet via SSH.
Starts (or restarts) the reverse‑proxy container in ~/reverse_proxy.
#>

param(
    [string]$Target = $(Read-Host "Enter droplet target (e.g. root@123.45.67.89)")
)

if ($Target -notmatch '^\S+@\d{1,3}(\.\d{1,3}){3}$') {
    throw "Invalid SSH target format. Use user@ip"
}

# SSH options to skip host‑key prompt
$sshOpts = @('-o','StrictHostKeyChecking=no','-o','UserKnownHostsFile=/dev/null')

Write-Host "🔄 Restarting reverse‑proxy container on $Target..."
ssh @sshOpts $Target "cd ~/reverse_proxy && sudo docker compose down && sudo docker compose up -d"

Write-Host "✔ Container restarted."
