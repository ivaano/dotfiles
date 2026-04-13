#!/usr/bin/env bash
#
# stage-devtools.sh — Install common development tools
#
# Usage: bash stage-devtools.sh
#
# Installs: git, build-essential, Python3, uv, fzf, zoxide, eza, yazi (via griffo repo)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers.sh"

# ─── Provision ────────────────────────────────────────────────────────────────

provision_dev_tools() {
    log_section "Provisioning Development Tools"

    # Uninstall packages that will be replaced by griffo repository
    log_info "Removing fzf, zoxide, eza (will be reinstalled from griffo repo)…"
    apt-get remove -y fzf zoxide eza 2>/dev/null || true

    # Add griffo repository (idempotent)
    local gpg_key="/etc/apt/trusted.gpg.d/debian.griffo.io.gpg"
    local sources_list="/etc/apt/sources.list.d/debian.griffo.io.list"

    if [[ ! -f "$gpg_key" ]]; then
        log_info "Adding griffo repository GPG key…"
        curl -sS https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | \
            sudo gpg --dearmor --yes -o "$gpg_key"
    else
        log_ok "Griffo GPG key already present."
    fi

    if [[ ! -f "$sources_list" ]]; then
        log_info "Adding griffo repository source…"
        echo "deb https://debian.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | \
            sudo tee "$sources_list"
        sudo apt update
    else
        log_ok "Griffo repository already configured."
    fi

    # Install packages from griffo repository
    install_packages \
        git build-essential pkg-config \
        python3 python3-pip python3-venv \
        uv fzf zoxide eza yazi

    log_ok "Development tools installed."
}

ensure_sudo
provision_dev_tools
