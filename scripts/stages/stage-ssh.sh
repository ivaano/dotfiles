#!/usr/bin/env bash
#
# stage-ssh.sh — Install SSH client and optionally generate keys
#
# Usage: bash stage-ssh.sh [--user USERNAME] [--generate-key]
#
# Optional:
#   --user USERNAME    Target user (defaults to current user)
#   --generate-key     Generate an ed25519 SSH key if one doesn't exist

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers.sh"

# ─── Defaults ─────────────────────────────────────────────────────────────────

TARGET_USER="$(whoami)"
GENERATE_KEY="no"

# ─── Parse args ───────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --user)
            TARGET_USER="$2"; shift 2 ;;
        --generate-key)
            GENERATE_KEY="yes"; shift ;;
        *)
            log_error "Unknown argument: $1"; exit 1 ;;
    esac
done

# ─── Provision ────────────────────────────────────────────────────────────────

provision_ssh() {
    log_section "Provisioning SSH"

    install_packages openssh-client

    if [[ "$GENERATE_KEY" != "yes" ]]; then
        log_ok "SSH client installed. Use --generate-key to create a key pair."
        return
    fi

    local home_dir
    home_dir="$(eval echo "~${TARGET_USER}")"
    local ssh_dir="${home_dir}/.ssh"

    if [[ ! -f "${ssh_dir}/id_ed25519" ]]; then
        sudo install -d -m 700 "$ssh_dir"
        sudo ssh-keygen -t ed25519 -C "${TARGET_USER}@$(hostname)" \
            -f "${ssh_dir}/id_ed25519" -N "" -q
        sudo chown -R "${TARGET_USER}:${TARGET_USER}" "$ssh_dir"
        log_ok "SSH key generated at ${ssh_dir}/id_ed25519"
    else
        log_info "SSH key already exists. Skipping generation."
    fi
}

ensure_sudo
provision_ssh
