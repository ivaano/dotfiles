#!/usr/bin/env bash
#
# stage-vim.sh — Install Vim, vim-plug, and plugins
#
# Usage: bash stage-vim.sh [--user USERNAME]
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

provision_vim() {
    log_section "Provisioning Vim"

    local home_dir
    home_dir="$(eval echo "~${TARGET_USER}")"

    install_packages vim

    # vim-plug
    if [[ ! -f "${home_dir}/.vim/autoload/plug.vim" ]]; then
        log_info "Installing vim-plug…"
        sudo curl -fLo "${home_dir}/.vim/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        sudo chown -R "${TARGET_USER}:${TARGET_USER}" "${home_dir}/.vim"
        log_ok "vim-plug installed."
    else
        log_ok "vim-plug already installed."
    fi

    install_dotfile ".vimrc" "${home_dir}/.vimrc" "$TARGET_USER"

    # Install plugins via vim-plug
    log_info "Installing Vim plugins…"
    sudo -u "$TARGET_USER" vim +PlugInstall +qall 2>/dev/null || true
    log_ok "Vim and plugins installed for ${TARGET_USER}."
}

ensure_sudo
provision_vim
