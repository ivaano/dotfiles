#!/usr/bin/env bash
#
# stage-base.sh — Provision base system packages, hostname, timezone, auto-updates
#
# Usage: bash stage-base.sh [--hostname NAME] [--timezone] [--auto-updates]
#
# Flags:
#   --hostname NAME   Set the system hostname
#   --timezone        Configure timezone via timedatectl
#   --auto-updates    Enable unattended security updates

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers.sh"

# ─── Defaults ─────────────────────────────────────────────────────────────────

SET_HOSTNAME=""
CONFIGURE_TZ="no"
AUTO_UPDATES="no"

# ─── Parse args ───────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --hostname)
            SET_HOSTNAME="$2"; shift 2 ;;
        --timezone)
            CONFIGURE_TZ="yes"; shift ;;
        --auto-updates)
            AUTO_UPDATES="yes"; shift ;;
        *)
            log_error "Unknown argument: $1"; exit 1 ;;
    esac
done

# ─── Provision ────────────────────────────────────────────────────────────────

provision_base() {
    log_section "Provisioning Base System"

    local base_packages=(
        sudo
        ca-certificates
        curl
        gnupg
        apt-transport-https
        git
    )

    update_package_index
    install_packages "${base_packages[@]}"

    if [[ -n "$SET_HOSTNAME" ]]; then
        sudo hostnamectl set-hostname "$SET_HOSTNAME"
        log_ok "Hostname set to ${SET_HOSTNAME}"
    fi

    if [[ "$CONFIGURE_TZ" == "yes" ]]; then
        if command -v timedatectl &>/dev/null; then
            sudo timedatectl set-ntp true
            log_ok "NTP enabled."
        fi
    fi

    if [[ "$AUTO_UPDATES" == "yes" ]]; then
        install_packages unattended-upgrades
        sudo dpkg-reconfigure -f noninteractive unattended-upgrades
        log_ok "Automatic security updates enabled."
    fi

    log_ok "Base system provisioning complete."
}

ensure_sudo
provision_base
