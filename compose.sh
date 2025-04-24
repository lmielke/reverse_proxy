#!/bin/bash
set -e

# Ensure we're in or cd into reverse_proxy
if [[ "$(basename "$PWD")" != "reverse_proxy" ]]; then
  if [[ -d "reverse_proxy" ]]; then
    echo "📁 Found reverse_proxy dir — changing into it..."
    cd reverse_proxy
  else
    echo "❌ 'reverse_proxy' directory not found in current location."
    exit 1
  fi
fi

# Pull latest repo changes
echo "📥 Pulling latest git changes..."
git pull

# Confirm docker-compose.yml exists
if [[ ! -f "docker-compose.yml" ]]; then
  echo "❌ docker-compose.yml not found in $(pwd)"
  exit 1
fi

# Load UI_IP and UI_PORT from params.json if present
if [[ -f "params.json" ]]; then
  echo "📄 Found params.json:"
  cat params.json

  read -p "Use these parameters? (Y/N): " use_params
  if [[ "$use_params" =~ ^[Yy]$ ]]; then
    UI_PORT=$(jq -r '.UI_PORT' params.json)
    UI_IP=$(jq -r '.UI_IP' params.json)
  fi
fi

# Fallback to manual prompt if not set
if [[ -z "$UI_PORT" ]]; then
  UI_PORT="$1"
  if [[ -z "$UI_PORT" ]]; then
    read -p "Enter UI_PORT: " UI_PORT
    if [[ -z "$UI_PORT" ]]; then
      echo "❌ UI_PORT is required."
      exit 1
    fi
  fi
fi

if [[ -z "$UI_IP" ]]; then
  UI_IP=$(ip addr show docker0 | awk '/inet / {print $2}' | cut -d/ -f1)
  if [[ -z "$UI_IP" ]]; then
    echo "❌ Could not determine UI_IP from docker0"
    exit 1
  fi
fi

# Stop if container is already running
if (UI_PORT=$UI_PORT UI_IP=$UI_IP docker compose ps) | grep -q "Up"; then
  echo "⛔ Container running — stopping it first..."
  UI_PORT=$UI_PORT UI_IP=$UI_IP docker compose down
fi

# Pull latest image
echo "🔄 Pulling latest images..."
UI_PORT=$UI_PORT UI_IP=$UI_IP docker compose pull

# Start
echo -e "\033[1;33m🚀 Starting docker compose with:\033[0m"
echo "  UI_IP:   $UI_IP"
echo "  UI_PORT: $UI_PORT"

UI_PORT=$UI_PORT UI_IP=$UI_IP docker compose up -d

echo "⏳ Waiting 5 seconds..."
sleep 5

UI_PORT=$UI_PORT UI_IP=$UI_IP docker compose ps
