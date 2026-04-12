#!/usr/bin/env bash
#
# stage-docker.sh — Install Docker and add user to docker group
#
# Usage: bash stage-docker.sh [--user USERNAME]
#
# Optional:
#   --user USERNAME   Target user for docker group (defaults to current user)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers.sh"

# ─── Defaults ─────────────────────────────────────────────────────────────────

TARGET_USER="$(whoami)"

# ─── Parse args ───────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --user)
            TARGET_USER="$2"; shift 2 ;;
        *)
            log_error "Unknown argument: $1"; exit 1 ;;
    esac
done

# ─── Provision ────────────────────────────────────────────────────────────────

provision_docker() {
    log_section "Provisioning Docker"

    if command -v docker &>/dev/null; then
        log_ok "Docker already installed."
    else
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
            -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update
        install_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        log_ok "Docker installed."
    fi

    sudo usermod -aG docker "$TARGET_USER"
    log_ok "${TARGET_USER} added to docker group."
}

ensure_sudo
provision_docker
