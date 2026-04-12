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

# ─── Privilege check ──────────────────────────────────────────────────────────

ensure_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges."
        exit 1
    fi
}
