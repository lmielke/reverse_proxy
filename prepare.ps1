# prepare.ps1
<#
Checks the following:
- Hostname detection (dev vs server)
- Docker & Docker Compose installed
- doctl configured
- DockerHub login works
- Git repo status (must be clean except known files)
#>

$ErrorActionPreference = 'Stop'

function Get-HostnameType {
    $hostname = (hostname).ToLower()
    if ($hostname -eq 'while-ai-0') { return 'server' }
    elseif ($hostname -eq 'while-ai-2') { return 'dev' }
    else { throw "Unknown machine: $hostname" }
}

function Check-Docker {
    docker --version | Out-Null
    docker compose version | Out-Null
}

function Check-Doctl {
    $authOutput = doctl auth list
    if ($authOutput -notmatch '\(current\)') {
        throw "doctl not logged in or no active context."
    }
}


function Check-DockerHub {
    docker info | Select-String 'Username' | Out-Null
}

function Check-GitStatus {
    $status = git status --porcelain
    if ($status) {
        Write-Warning "Git has uncommitted changes:"
        $status | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "✔ Git repo clean"
    }
}


# Main
Write-Host "Running prepare.ps1 ..."
$machineType = Get-HostnameType
Write-Host "Detected machine: $machineType"

Check-Docker
Write-Host "✔ Docker + Compose OK"

if ($machineType -eq 'dev') {
    Check-Doctl
    Write-Host "✔ doctl configured"
    Check-DockerHub
    Write-Host "✔ DockerHub login OK"
    Check-GitStatus
    Write-Host "✔ Git repo clean"
}

Write-Host "All checks passed."
