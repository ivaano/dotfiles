#!/usr/bin/env bash
#
# stage-tmux.sh — Install Tmux and configuration
#
# Usage: bash stage-tmux.sh [--user USERNAME]
#
# Optional:
#   --user USERNAME   Target user (defaults to current user)

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

provision_tmux() {
    log_section "Provisioning Tmux"

    local home_dir
    home_dir="$(eval echo "~${TARGET_USER}")"

    install_packages tmux
    install_dotfile ".tmux.conf" "${home_dir}/.tmux.conf" "$TARGET_USER"
    log_ok "Tmux installed and .tmux.conf placed for ${TARGET_USER}."
}

ensure_sudo
provision_tmux
