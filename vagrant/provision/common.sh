#!/bin/bash

apt-get update -y
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# Docker
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com | sh
fi

usermod -aG docker vagrant

# Docker Compose
if ! command -v docker-compose &> /dev/null; then
  curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi
