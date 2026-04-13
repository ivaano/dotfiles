#!/usr/bin/env bash
#
# stage-devtools.sh — Install common development tools
#
# Usage: bash stage-devtools.sh [--user USERNAME]
#
# Installs: git, build-essential, Python3, uv, fzf, zoxide, eza, yazi (via griffo repo)
#           Node.js via fnm

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

install_node_via_fnm() {
    local home_dir
    home_dir="$(eval echo "~${TARGET_USER}")"

    if sudo -u "$TARGET_USER" test -d "${home_dir}/.local/state/fnm"; then
        log_ok "fnm already installed for ${TARGET_USER}."
    else
        log_info "Installing fnm for ${TARGET_USER}…"
        sudo -u "$TARGET_USER" bash -c 'curl -fsSL https://fnm.vercel.app/install | bash'
    fi

    if sudo -u "$TARGET_USER" test -f "${home_dir}/.local/state/fnm/aliases/24" || \
       sudo -u "$TARGET_USER" bash -ic 'fnm ls 2>/dev/null' 2>&1 | grep -q "v24"; then
        log_ok "Node.js 24 already installed via fnm for ${TARGET_USER}."
    else
        log_info "Installing Node.js 24 via fnm for ${TARGET_USER}…"
        sudo -u "$TARGET_USER" bash -ic 'fnm install 24'
    fi

    # Ensure fnm is sourced in shell config
    if ! grep -q "fnm env" "${home_dir}/.bashrc" 2>/dev/null && \
       ! grep -q "fnm env" "${home_dir}/.zshrc" 2>/dev/null; then
        log_info "Adding fnm initialization to shell config…"
        sudo -u "$TARGET_USER" bash -c 'echo '\''eval "$(fnm env --use-on-cd)"'\'' >> "${HOME}/.bashrc"'
        if [[ -f "${home_dir}/.zshrc" ]]; then
            sudo -u "$TARGET_USER" bash -c 'echo '\''eval "$(fnm env --use-on-cd)"'\'' >> "${HOME}/.zshrc"'
        fi
    fi
}

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
        unzip git build-essential pkg-config \
        python3 python3-pip python3-venv \
        uv fzf zoxide eza yazi

    # Install Node.js via fnm
    install_node_via_fnm

    log_ok "Development tools installed."
}

ensure_sudo
provision_dev_tools
