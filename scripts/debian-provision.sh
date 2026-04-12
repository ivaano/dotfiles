#!/usr/bin/env bash
#
# debian-provision.sh — Interactive Debian provisioning script
#
# Usage: bash debian-provision.sh
#
# This script:
#   1. Checks for sudo privileges and escalates to root if needed
#   2. Gathers user preferences interactively
#   3. Provisions the system based on those preferences
#
# Dotfile layout:
#   linux/   — Linux-specific shell configs (.zshrc, .zpreztorc, .p10k.zsh)
#   osx/     — macOS-specific shell configs (.zshrc, .zpreztorc, .p10k.zsh)
#   root     — Shared dotfiles (.vimrc, .tmux.conf, alacritty/)
#
# Extending:
#   1. Add a new `provision_<name>` function below
#   2. Add its call in run_provision()
#   3. If it needs a new preference, add a prompt in gather_preferences()

set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────────────

DOTFILES_REPO="ivaano/dotfiles"
DOTFILES_RAW="https://raw.githubusercontent.com/${DOTFILES_REPO}/main"

# Resolve the local repo root if the script is run from within it.
# Returns "" if we can't find it.
resolve_local_repo() {
    local dir
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # scripts/
    if [[ -d "$dir/.git" ]]; then
        echo "$dir"
    elif [[ -d "$dir/../.git" ]]; then
        echo "$dir/.."
    fi
}

LOCAL_REPO="$(resolve_local_repo)"

# ─── Colors ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─── Logging helpers ──────────────────────────────────────────────────────────

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }
log_section() { echo -e "\n${CYAN}══ $* ══${NC}\n"; }

# ─── Preference storage ───────────────────────────────────────────────────────

declare -A PREFS

prompt() {
    local key="$1" prompt_text="$2" default="${3:-}"
    local input
    if [[ -n "$default" ]]; then
        read -rp "${prompt_text} [${default}]: " input
        PREFS["$key"]="${input:-$default}"
    else
        read -rp "${prompt_text}: " input
        PREFS["$key"]="$input"
    fi
}

prompt_bool() {
    local key="$1" prompt_text="$2" default="${3:-n}"
    local input
    while true; do
        read -rp "${prompt_text} [y/N]: " input
        input="${input:-$default}"
        case "$input" in
            [yY]|[yY][eE][sS]) PREFS["$key"]="yes"; break ;;
            [nN]|[nN][oO])     PREFS["$key"]="no";  break ;;
            *) log_warn "Please answer y or n." ;;
        esac
    done
}

prompt_select() {
    local key="$1" prompt_text="$2" default="${3:-1}"
    shift 3
    local options=("$@")
    local input

    echo -e "${prompt_text}:"
    for i in "${!options[@]}"; do
        echo -e "  ${GREEN}$((i+1))${NC}) ${options[$i]}"
    done

    while true; do
        read -rp "Choose [${default}]: " input
        input="${input:-$default}"
        if [[ "$input" =~ ^[0-9]+$ ]] && (( input >= 1 && input <= ${#options[@]} )); then
            PREFS["$key"]="${options[$((input-1))]}"
            break
        else
            log_warn "Please enter a number between 1 and ${#options[@]}."
        fi
    done
}

# ─── Gather preferences ───────────────────────────────────────────────────────

gather_preferences() {
    log_section "Gathering Preferences"

    local current_user
    current_user="$(whoami)"
    prompt "primary_user" "Primary username" "$current_user"

    local current_hostname
    current_hostname="$(hostname)"
    prompt "hostname" "Hostname" "$current_hostname"

    # Shell preference
    prompt_select "shell" "Preferred shell" "1" "zsh" "bash" "fish"

    # Docker
    prompt_bool "install_docker" "Install Docker?" "y"

    # Common dev tools
    prompt_bool "install_dev_tools" "Install common development tools?" "y"

    # SSH setup
    prompt_bool "setup_ssh" "Generate and configure SSH keys?" "n"

    # NTP / timezone
    prompt_bool "configure_timezone" "Configure timezone?" "y"

    # Automatic security updates
    prompt_bool "auto_security_updates" "Enable automatic security updates?" "y"

    echo
    log_section "Summary"
    for key in "${!PREFS[@]}"; do
        echo -e "  ${GREEN}${key}${NC}: ${PREFS[$key]}"
    done
    echo

    while true; do
        read -rp "Proceed with these settings? [y/N]: " confirm
        confirm="${confirm:-n}"
        case "$confirm" in
            [yY]|[yY][eE][sS]) break ;;
            [nN]|[nN][oO])
                log_info "Re-gathering preferences…"
                gather_preferences
                return
                ;;
            *) log_warn "Please answer y or n." ;;
        esac
    done
}

# ─── Privilege escalation ─────────────────────────────────────────────────────

has_sudo() {
    command -v sudo &>/dev/null && sudo -n true 2>/dev/null
}

ensure_sudo_privileges() {
    log_section "Checking Privileges"

    if has_sudo; then
        log_ok "User $(whoami) already has sudo privileges."
        return 0
    fi

    if [[ "$(id -u)" -eq 0 ]]; then
        log_info "Running as root."
        install_sudo_for_root
        return 0
    fi

    log_warn "User $(whoami) does not have sudo privileges."
    log_info "Attempting to escalate via su to fix this…"

    local root_password=""
    read -rs -p "Enter root password: " root_password
    echo

    if echo "$root_password" | su -c "id" - 2>/dev/null; then
        log_ok "Root authentication successful."

        echo "$root_password" | su -c "
            set -e
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq
            apt-get install -y -qq sudo
        " 2>/dev/null || {
            log_info "Trying alternative method…"
            su -c "
                export DEBIAN_FRONTEND=noninteractive
                apt-get update -qq
                apt-get install -y -qq sudo
            " -
        }

        local current_user
        current_user="$(whoami)"
        echo "$root_password" | su -c "
            usermod -aG sudo ${current_user}
            echo '${current_user} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
        " - 2>/dev/null || true

        log_ok "User ${current_user} added to sudoers."
        log_info "Please re-run this script for the changes to take effect."
        log_info "If your shell session needs to refresh groups, you may need to log out and back in."

        if has_sudo; then
            log_ok "Sudo is now working. Continuing…"
            return 0
        else
            log_error "Sudo is still not available. Please log out and log back in, then re-run this script."
            exit 1
        fi
    else
        log_error "Failed to authenticate as root."
        exit 1
    fi
}

install_sudo_for_root() {
    if ! command -v sudo &>/dev/null; then
        log_info "sudo not found. Installing…"
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq sudo
        log_ok "sudo installed."
    fi
}

# ─── Helpers ──────────────────────────────────────────────────────────────────

run_cmd() {
    log_info "Running: $*"
    if "$@"; then
        log_ok "Completed: $1"
    else
        log_error "Failed: $*"
        return 1
    fi
}

update_package_index() {
    log_info "Updating package index…"
    sudo apt-get update -qq
    log_ok "Package index updated."
}

install_packages() {
    log_info "Installing packages: $*"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@"
}

# Install a dotfile into the user's home directory.
# Tries the local repo first, then falls back to raw GitHub.
#
# Usage: install_dotfile <relative_path> <dest_path> <user>
#   relative_path — path relative to the repo root (e.g. linux/.zshrc)
#   dest_path     — absolute destination path (e.g. /home/user/.zshrc)
#   user          — owner username
install_dotfile() {
    local rel_path="$1"
    local dest_path="$2"
    local user="$3"

    if [[ -n "$LOCAL_REPO" && -f "${LOCAL_REPO}/${rel_path}" ]]; then
        log_info "Copying ${rel_path} from local repo…"
        sudo cp "${LOCAL_REPO}/${rel_path}" "$dest_path"
    else
        log_info "Downloading ${rel_path} from GitHub…"
        run_cmd sudo curl -fsSL "${DOTFILES_RAW}/${rel_path}" -o "$dest_path"
    fi

    sudo chown "${user}:${user}" "$dest_path"
    log_ok "Installed ${rel_path} → ${dest_path}"
}

# ─── Provisioning modules ─────────────────────────────────────────────────────

# --- Base system ---

# Edit this array to add/remove base packages.
BASE_PACKAGES=(
    sudo
    ca-certificates
    curl
    gnupg
    apt-transport-https
    git
)

provision_base() {
    log_section "Provisioning Base System"
    update_package_index

    install_packages "${BASE_PACKAGES[@]}"

    local hostname="${PREFS[hostname]:-}"
    if [[ -n "$hostname" ]] && [[ "$hostname" != "$(hostname)" ]]; then
        run_cmd sudo hostnamectl set-hostname "$hostname"
        log_ok "Hostname set to ${hostname}"
    fi

    if [[ "${PREFS[configure_timezone]:-n}" == "yes" ]]; then
        provision_timezone
    fi

    if [[ "${PREFS[auto_security_updates]:-n}" == "yes" ]]; then
        provision_auto_updates
    fi
}

provision_timezone() {
    log_info "Configuring timezone…"
    if command -v timedatectl &>/dev/null; then
        sudo timedatectl set-ntp true
        log_ok "NTP enabled."
    fi
}

provision_auto_updates() {
    log_info "Enabling automatic security updates…"
    install_packages unattended-upgrades
    run_cmd sudo dpkg-reconfigure -f noninteractive unattended-upgrades
    log_ok "Automatic security updates enabled."
}

# --- Shell ---

provision_shell() {
    log_section "Provisioning Shell"
    local shell_choice="${PREFS[shell]:-bash}"
    local primary_user="${PREFS[primary_user]:-$(whoami)}"
    local home_dir
    home_dir="$(eval echo "~${primary_user}")"

    # On this script's platform (Debian/Linux) we always pull from linux/
    local shell_platform="linux"

    case "$shell_choice" in
        zsh)
            install_packages zsh

            # Install zsh plugins first (prezto, p10k)
            install_zsh_frameworks "$primary_user"

            install_dotfile "${shell_platform}/.zshrc"       "${home_dir}/.zshrc"     "$primary_user"
            install_dotfile "${shell_platform}/.zpreztorc"   "${home_dir}/.zpreztorc" "$primary_user"
            install_dotfile "${shell_platform}/.p10k.zsh"    "${home_dir}/.p10k.zsh"  "$primary_user"

            run_cmd sudo chsh -s "$(command -v zsh)" "$primary_user"
            log_ok "Zsh installed, set as default, and dotfiles placed for ${primary_user}"
            ;;
        fish)
            install_packages fish
            run_cmd sudo chsh -s "$(command -v fish)" "$primary_user"
            log_ok "Fish installed and set as default for ${primary_user}"
            ;;
        bash|*)
            install_dotfile "${shell_platform}/.bashrc" "${home_dir}/.bashrc" "$primary_user" 2>/dev/null || \
                log_warn "No .bashrc found in repo. Keeping system default."
            log_ok "Bash is default shell for ${primary_user}"
            ;;
    esac
}

install_zsh_frameworks() {
    local primary_user="$1"
    local home_dir
    home_dir="$(eval echo "~${primary_user}")"

    # Prezto
    if [[ ! -d "${home_dir}/.zprezto" ]]; then
        log_info "Cloning Prezto…"
        run_cmd sudo -u "$primary_user" git clone --recursive \
            https://github.com/sorin-ionescu/prezto.git "${home_dir}/.zprezto"
    else
        log_ok "Prezto already installed."
    fi

    # Powerlevel10k
    if [[ ! -d "${home_dir}/.zprezto/modules/prompt/external/powerlevel10k" ]]; then
        log_info "Cloning Powerlevel10k…"
        run_cmd sudo -u "$primary_user" git clone \
            https://github.com/romkatv/powerlevel10k.git \
            "${home_dir}/.zprezto/modules/prompt/external/powerlevel10k"
    else
        log_ok "Powerlevel10k already installed."
    fi

    # zsh-autosuggestions (Prezto submodule sometimes misses it)
    if [[ ! -d "${home_dir}/.zprezto/modules/autosuggestions/external" ]]; then
        log_info "Cloning zsh-autosuggestions…"
        run_cmd sudo -u "$primary_user" git clone \
            https://github.com/zsh-users/zsh-autosuggestions.git \
            "${home_dir}/.zprezto/modules/autosuggestions/external"
    fi

    # zsh-syntax-highlighting
    if [[ ! -d "${home_dir}/.zprezto/modules/syntax-highlighting/external" ]]; then
        log_info "Cloning zsh-syntax-highlighting…"
        run_cmd sudo -u "$primary_user" git clone \
            https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "${home_dir}/.zprezto/modules/syntax-highlighting/external"
    fi

    # fzf-tab
    if [[ ! -d "${home_dir}/.zprezto/modules/fzf-tab/external" ]]; then
        log_info "Cloning fzf-tab…"
        run_cmd sudo -u "$primary_user" git clone \
            https://github.com/Aloxaf/fzf-tab.git \
            "${home_dir}/.zprezto/modules/fzf-tab/external"
    fi
}

# --- Dev tools ---

provision_dev_tools() {
    [[ "${PREFS[install_dev_tools]:-n}" != "yes" ]] && return 0

    log_section "Provisioning Development Tools"

    install_packages \
        git build-essential pkg-config \
        python3 python3-pip python3-venv \
        nodejs npm \
        ripgrep fd-find fzf eza \
        jq tree htop \
        openssh-client
}

# --- Vim ---

provision_vim() {
    log_section "Provisioning Vim"
    local primary_user="${PREFS[primary_user]:-$(whoami)}"
    local home_dir
    home_dir="$(eval echo "~${primary_user}")"

    install_packages vim

    # vim-plug
    if [[ ! -f "${home_dir}/.local/share/nvim/site/autoload/plug.vim" ]] && \
       [[ ! -f "${home_dir}/.vim/autoload/plug.vim" ]]; then
        log_info "Installing vim-plug…"
        run_cmd sudo curl -fLo "${home_dir}/.vim/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        sudo chown -R "${primary_user}:${primary_user}" "${home_dir}/.vim"
    else
        log_ok "vim-plug already installed."
    fi

    install_dotfile ".vimrc" "${home_dir}/.vimrc" "$primary_user"
    log_ok "Vim installed and .vimrc placed."

    # Install plugins via vim-plug
    log_info "Installing Vim plugins…"
    sudo -u "$primary_user" vim +PlugInstall +qall 2>/dev/null || true
    log_ok "Vim plugins installed."
}

# --- Tmux ---

provision_tmux() {
    log_section "Provisioning Tmux"
    local primary_user="${PREFS[primary_user]:-$(whoami)}"
    local home_dir
    home_dir="$(eval echo "~${primary_user}")"

    install_packages tmux
    install_dotfile ".tmux.conf" "${home_dir}/.tmux.conf" "$primary_user"
    log_ok "Tmux installed and .tmux.conf placed."
}

# --- Alacritty ---

provision_alacritty() {
    log_section "Provisioning Alacritty"
    local primary_user="${PREFS[primary_user]:-$(whoami)}"
    local home_dir
    home_dir="$(eval echo "~${primary_user}")"
    local config_dir="${home_dir}/.config/alacritty"

    # Alacritty may not be in the Debian repo; try to install, warn if unavailable
    install_packages alacritty 2>/dev/null || {
        log_warn "Alacritty package not available in this repo. Installing config only."
    }

    run_cmd sudo install -d -m 755 "$config_dir"
    install_dotfile "alacritty/alacritty.toml" "${config_dir}/alacritty.toml" "$primary_user"
    sudo chown -R "${primary_user}:${primary_user}" "$config_dir"
    log_ok "Alacritty config placed."
}

# --- Docker ---

provision_docker() {
    [[ "${PREFS[install_docker]:-n}" != "yes" ]] && return 0

    log_section "Provisioning Docker"

    if command -v docker &>/dev/null; then
        log_ok "Docker already installed."
        return 0
    fi

    run_cmd sudo install -m 0755 -d /etc/apt/keyrings
    run_cmd sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
        -o /etc/apt/keyrings/docker.asc
    run_cmd sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    run_cmd sudo apt-get update
    install_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    local primary_user="${PREFS[primary_user]:-$(whoami)}"
    run_cmd sudo usermod -aG docker "$primary_user"
    log_ok "Docker installed and ${primary_user} added to docker group."
}

# --- SSH ---

provision_ssh() {
    [[ "${PREFS[setup_ssh]:-n}" != "yes" ]] && return 0

    log_section "Provisioning SSH"

    install_packages openssh-client

    local primary_user="${PREFS[primary_user]:-$(whoami)}"
    local home_dir
    home_dir="$(eval echo "~${primary_user}")"
    local ssh_dir="${home_dir}/.ssh"

    if [[ ! -f "${ssh_dir}/id_ed25519" ]]; then
        run_cmd sudo install -d -m 700 "$ssh_dir"
        run_cmd sudo ssh-keygen -t ed25519 -C "${primary_user}@$(hostname)" \
            -f "${ssh_dir}/id_ed25519" -N "" -q
        run_cmd sudo chown -R "${primary_user}:${primary_user}" "$ssh_dir"
        log_ok "SSH key generated at ${ssh_dir}/id_ed25519"
    else
        log_info "SSH key already exists. Skipping generation."
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

run_provision() {
    provision_base
    provision_shell
    provision_dev_tools
    provision_vim
    provision_tmux
    provision_alacritty
    provision_docker
    provision_ssh

    log_section "Provisioning Complete"
    log_ok "All done! You may want to reboot to apply all changes."
}

main() {
    echo
    log_section "Debian Provisioning Script"

    ensure_sudo_privileges
    gather_preferences
    run_provision
}

main "$@"
