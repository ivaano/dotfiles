#!/usr/bin/env bash
#
# stage-shell.sh — Install and configure the user's preferred shell
#
# Usage: bash stage-shell.sh --shell SHELL [--user USERNAME]
#
# Required:
#   --shell SHELL     One of: zsh, bash, fish
#
# Optional:
#   --user USERNAME   Target user (defaults to current user)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../helpers.sh"

# ─── Defaults ─────────────────────────────────────────────────────────────────

SHELL_CHOICE=""
TARGET_USER="$(whoami)"

# ─── Parse args ───────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --shell)
            SHELL_CHOICE="$2"; shift 2 ;;
        --user)
            TARGET_USER="$2"; shift 2 ;;
        *)
            log_error "Unknown argument: $1"; exit 1 ;;
    esac
done

if [[ -z "$SHELL_CHOICE" ]]; then
    log_error "--shell is required (zsh, bash, fish)"
    exit 1
fi

# ─── Provision ────────────────────────────────────────────────────────────────

install_zsh_frameworks() {
    local home_dir
    home_dir="$(eval echo "~${TARGET_USER}")"

    if [[ ! -d "${home_dir}/.zprezto" ]]; then
        log_info "Cloning Prezto…"
        sudo -u "$TARGET_USER" git clone --recursive \
            https://github.com/sorin-ionescu/prezto.git "${home_dir}/.zprezto"
    else
        log_ok "Prezto already installed."
    fi

    if [[ ! -d "${home_dir}/.zprezto/modules/fzf-tab/external" ]]; then
        log_info "Cloning fzf-tab…"
        sudo -u "$TARGET_USER" git clone \
            https://github.com/Aloxaf/fzf-tab.git \
            "${home_dir}/.zprezto/contrib/fzf-tab"
    fi
}

provision_shell() {
    log_section "Provisioning Shell (${SHELL_CHOICE})"

    local home_dir
    home_dir="$(eval echo "~${TARGET_USER}")"
    local shell_platform="linux"

    case "$SHELL_CHOICE" in
        zsh)
            install_packages zsh fzf eza zoxide bat

            # Clean up existing Prezto installation before fresh setup
            if [[ -d "${home_dir}/.zprezto" ]]; then
                log_info "Removing existing .zprezto directory…"
                rm -rf "${home_dir}/.zprezto"
            fi
            if [[ -f "${home_dir}/.zpreztorc" ]]; then
                log_info "Removing existing .zpreztorc file…"
                rm -f "${home_dir}/.zpreztorc"
            fi

            install_zsh_frameworks

            install_dotfile "${shell_platform}/.zshrc"       "${home_dir}/.zshrc"     "$TARGET_USER"
            install_dotfile "${shell_platform}/.zpreztorc"   "${home_dir}/.zpreztorc" "$TARGET_USER"
            install_dotfile "${shell_platform}/.p10k.zsh"    "${home_dir}/.p10k.zsh"  "$TARGET_USER"

            sudo chsh -s "$(command -v zsh)" "$TARGET_USER"
            log_ok "Zsh installed, dotfiles placed, set as default for ${TARGET_USER}"
            ;;
        fish)
            install_packages fish
            sudo chsh -s "$(command -v fish)" "$TARGET_USER"
            log_ok "Fish installed and set as default for ${TARGET_USER}"
            ;;
        bash|*)
            install_dotfile "${shell_platform}/.bashrc" "${home_dir}/.bashrc" "$TARGET_USER" 2>/dev/null || \
                log_warn "No .bashrc found in repo. Keeping system default."
            log_ok "Bash configured for ${TARGET_USER}"
            ;;
    esac
}

ensure_sudo
provision_shell
