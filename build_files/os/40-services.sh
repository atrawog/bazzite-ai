#!/usr/bin/env bash
set -xeuo pipefail

# Container services - socket activation for on-demand start
systemctl enable docker.socket
systemctl enable podman.socket

# SSH server - enabled at boot for remote access
systemctl enable sshd.service

# Docker daemon - always-on option (in addition to docker.socket)
# Users can choose between socket activation and always-on via ujust toggle-docker
systemctl enable docker.service

# System setup services
systemctl enable ublue-system-setup.service
systemctl --global enable ublue-user-setup.service
