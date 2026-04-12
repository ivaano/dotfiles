#!/usr/bin/env bash
#
# stage-devtools.sh — Install common development tools
#
# Usage: bash stage-devtools.sh
#
# Installs: git, build-essential, Python3, Node.js, ripgrep, fd, fzf, eza, jq, tree, htop, SSH client

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers.sh"

# ─── Provision ────────────────────────────────────────────────────────────────

provision_dev_tools() {
    log_section "Provisioning Development Tools"

    install_packages \
        git build-essential pkg-config \
        python3 python3-pip python3-venv \
        nodejs npm \
        ripgrep fd-find fzf eza \
        jq tree htop \
        openssh-client

    log_ok "Development tools installed."
}

ensure_sudo
provision_dev_tools
