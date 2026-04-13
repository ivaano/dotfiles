#!/usr/bin/env bash
#
# helpers.sh — Shared utilities for all provisioning scripts
#
# Source this file in any stage script:
#   source "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────────────

DOTFILES_REPO="ivaano/dotfiles"
DOTFILES_RAW="https://raw.githubusercontent.com/${DOTFILES_REPO}/main"

resolve_local_repo() {
    local dir
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    if [[ -d "$dir/.git" ]]; then
        echo "$dir"
    fi
}

LOCAL_REPO="$(resolve_local_repo)"

# ─── Colors ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ─── Logging ──────────────────────────────────────────────────────────────────

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }
log_section() { echo -e "\n${CYAN}══ $* ══${NC}\n"; }

# ─── Package management ───────────────────────────────────────────────────────

update_package_index() {
    log_info "Updating package index…"
    sudo apt-get update -qq
    log_ok "Package index updated."
}

install_packages() {
    log_info "Installing packages: $*"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@"
}

# ─── Dotfile installation ─────────────────────────────────────────────────────

# Usage: install_dotfile <repo_relative_path> <dest_path> <owner_user>
install_dotfile() {
    local rel_path="$1"
    local dest_path="$2"
    local user="$3"

    if [[ -n "$LOCAL_REPO" && -f "${LOCAL_REPO}/${rel_path}" ]]; then
        log_info "Copying ${rel_path} from local repo…"
        sudo cp "${LOCAL_REPO}/${rel_path}" "$dest_path"
    else
        log_info "Downloading ${rel_path} from GitHub…"
        sudo curl -fsSL "${DOTFILES_RAW}/${rel_path}" -o "$dest_path"
    fi

    sudo chown "${user}:${user}" "$dest_path"
    log_ok "Installed ${rel_path} → ${dest_path}"
}

# ─── Privilege escalation ─────────────────────────────────────────────────────

ensure_sudo() {
    # Already have working sudo
    if sudo -n true 2>/dev/null; then
        return 0
    fi

    # Running as root — install sudo if missing
    if [[ "$(id -u)" -eq 0 ]]; then
        if ! command -v sudo &>/dev/null; then
            log_info "Running as root but sudo is not installed. Installing…"
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq
            apt-get install -y -qq sudo
            log_ok "sudo installed."
        fi
        return 0
    fi

    # No sudo — escalate via su + root password
    log_warn "User $(whoami) does not have sudo privileges."
    log_info "Escalating via su to fix this…"

    local root_password=""
    read -rs -p "Enter root password: " root_password
    echo

    if ! echo "$root_password" | su -c "id" - 2>/dev/null; then
        log_error "Failed to authenticate as root."
        exit 1
    fi
    log_ok "Root authentication successful."

    # Install sudo if missing
    if ! echo "$root_password" | su -c "command -v sudo" - 2>/dev/null; then
        log_info "sudo not found on root. Installing…"
        echo "$root_password" | su -c "
            set -e
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq
            apt-get install -y -qq sudo
        " - 2>/dev/null || {
            log_info "Trying alternative method…"
            su -c "
                export DEBIAN_FRONTEND=noninteractive
                apt-get update -qq
                apt-get install -y -qq sudo
            " -
        }
        log_ok "sudo installed."
    fi

    # Add current user to sudoers
    local current_user
    current_user="$(whoami)"
    echo "$root_password" | su -c "
        usermod -aG sudo ${current_user}
        grep -q '^${current_user} .*NOPASSWD' /etc/sudoers 2>/dev/null || \
            echo '${current_user} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    " - 2>/dev/null || true

    log_ok "User ${current_user} added to sudoers."
    log_info "Re-checking sudo…"

    # Verify sudo now works
    if sudo -n true 2>/dev/null; then
        log_ok "Sudo is working. Continuing…"
        return 0
    else
        log_error "Sudo is still not active. Please log out and back in, then re-run this script."
        exit 1
    fi
}
