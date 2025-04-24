# publish.ps1
<#
Runs on your dev machine
Deploys the reverse proxy container to the droplet by:
1. Installing Docker + Compose plugin
2. Pulling your DockerHub image
3. Writing a remote-only docker-compose.yml (image: ... not build:)
4. Starting the container
#>

$ErrorActionPreference = 'Stop'

# 1) Ask for SSH target
$tunnelTarget = Read-Host "Enter droplet target (e.g. root@123.45.67.89)"
if ($tunnelTarget -notmatch '^\S+@\d{1,3}(\.\d{1,3}){3}$') {
    throw "Invalid SSH target format. Use user@ip"
}
$dropletIp = ($tunnelTarget -split '@')[1]

# 2) Ask for DockerHub username
$username = $env:DOCKERHUB_USER
if (-not $username) {
    $username = Read-Host "Enter your DockerHub username"
}
$imageName = 'ollama-reverse-proxy'
$fullImage = "${username}/${imageName}:latest"

# 3) SSH/SCP options to skip host‑key prompt
$sshOpts = @(
    '-o','StrictHostKeyChecking=no',
    '-o','UserKnownHostsFile=/dev/null'
)

# 4) Install Docker & Compose plugin
Write-Host "🔧 Installing Docker + Compose plugin on droplet..."
ssh @sshOpts $tunnelTarget "curl -fsSL https://get.docker.com | sudo sh && sudo apt-get update && sudo apt-get install -y docker-compose-plugin"

# 5) Pull the image
Write-Host "📦 Pulling image $fullImage..."
ssh @sshOpts $tunnelTarget "sudo docker pull ${fullImage}"

# 6) Ensure deploy dir
Write-Host "📂 Ensuring ~/reverse_proxy exists..."
ssh @sshOpts $tunnelTarget "mkdir -p ~/reverse_proxy"

# 7) Generate remote-only docker-compose.yml
$remoteCompose = @"
version: '3.9'
services:
  reverse-proxy:
    image: $fullImage
    ports:
      - "80:80"
      - "8080:8080"
    environment:
      UI_PORT: 3000
      OLLAMA_PORT: 11434
"@

Write-Host "📝 Writing remote docker-compose.yml..."
# Use a single SSH here-doc to avoid CRLF issues
$hereDoc  = "cat > ~/reverse_proxy/docker-compose.yml << 'EOF'`n$remoteCompose`nEOF"
ssh @sshOpts $tunnelTarget $hereDoc

# 8) Start the container
Write-Host "🚀 Starting container..."
ssh @sshOpts $tunnelTarget "cd ~/reverse_proxy && sudo docker compose up -d"

# 9) Done
Write-Host "✔ Deployment complete. Test at:"
Write-Host "  http://${dropletIp}/"
Write-Host "  http://${dropletIp}:8080/api/generate"
