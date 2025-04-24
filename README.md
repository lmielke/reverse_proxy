# Reverse Proxy for Ollama + Open Web UI

A lightweight Nginx-based reverse proxy to route traffic to Ollama API and Open Web UI services.

## Prerequisites
- Docker & Docker Compose
- PowerShell (for Windows dev machines)
- SSH access to a deployment target (e.g., DigitalOcean droplet)

## Setup
1. Run `prepare.ps1` on your dev machine to validate tools and repo state.
2. Build and push the image with `dockerize.ps1`.
3. Deploy to the droplet with `publish.ps1`.
4. Start the container on the droplet with `run.ps1`.

## Architecture
- Dev Machine: Builds and pushes the Docker image.
- Droplet: Hosts the reverse proxy container.
- Local Server: Runs Open Web UI and Ollama, tunneled via SSH.

## Ports
- 80: Open Web UI
- 88: Ollama API (internal)

