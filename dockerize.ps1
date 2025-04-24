# dockerize.ps1
<#
.SYNOPSIS
Builds and pushes the ollama-reverse-proxy Docker image to DockerHub.

.DESCRIPTION
Builds the Docker image with no cache and pushes it to DockerHub using the specified username.
Requires Docker to be installed and DockerHub login credentials.

.PARAMETER u
The DockerHub username to use for tagging and pushing the image. If not provided, uses $env:DOCKERHUB_USER or prompts the user.

.EXAMPLE
.\dockerize.ps1 -u lmielke
#>

param(
    [string]$u = $env:DOCKERHUB_USER
)

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

# Determine DockerHub username
if (-not $u) {
    $u = Read-Host "Enter your DockerHub username"
}
if (-not $u) {
    throw "DockerHub username is required."
}

$imageName = "ollama-reverse-proxy"
$fullTag = "docker.io/$u/$($imageName):latest"

# Build the image
Write-Host "🔨 Building image: $fullTag"
docker build --no-cache -t $fullTag .

Write-Host "✔ Image built: $fullTag"

# Push the image (assumes docker login has been done)
Write-Host "📤 Pushing image to DockerHub: $fullTag"
docker push $fullTag

Write-Host "✔ Image pushed: $fullTag"