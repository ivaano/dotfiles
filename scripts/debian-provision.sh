#!/usr/bin/env bash
#
# debian-provision.sh — Interactive Debian provisioning orchestrator
#
# Usage: bash debian-provision.sh
#
# Presents an interactive menu to select which stages to run.
# Each stage can also be run individually from scripts/stages/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGES_DIR="${SCRIPT_DIR}/stages"

# ─── Colors ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
    local default_display
    if [[ "$default" =~ ^[yY] ]]; then
        default_display="[Y/n]"
    else
        default_display="[y/N]"
    fi
    while true; do
        read -rp "${prompt_text} ${default_display}: " input
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

    prompt_select "shell" "Preferred shell" "1" "zsh" "bash" "fish"

    echo
    log_section "Select stages to install"
    echo "Each stage can also be run individually from scripts/stages/"
    echo

    prompt_bool "stage_base"        "  1) Base system (packages, hostname, timezone, auto-updates)" "y"
    prompt_bool "stage_shell"       "  2) Shell (zsh/bash/fish + dotfiles)"                        "y"
    prompt_bool "stage_vim"         "  3) Vim (editor + plugins)"                                  "y"
    prompt_bool "stage_tmux"        "  4) Tmux (terminal multiplexer)"                              "y"
    prompt_bool "stage_devtools"    "  5) Dev tools (git, python, node, ripgrep, fzf, etc.)"        "y"
    prompt_bool "stage_docker"      "  6) Docker"                                                   "n"
    prompt_bool "stage_ssh"         "  7) SSH (client + optional key generation)"                   "n"

    # Base system sub-options
    if [[ "${PREFS[stage_base]:-n}" == "yes" ]]; then
        echo
        log_info "Base system options:"
        prompt_bool "base_timezone"    "     Configure timezone?"             "y"
        prompt_bool "base_auto_updates" "     Enable automatic security updates?" "y"
    fi

    # SSH sub-option
    if [[ "${PREFS[stage_ssh]:-n}" == "yes" ]]; then
        echo
        prompt_bool "ssh_generate_key" "     Generate SSH key pair?" "n"
    fi

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

# ─── Run stages ───────────────────────────────────────────────────────────────

run_stage() {
    local stage_script="$1"
    shift
    log_info "Running stage: $(basename "$stage_script")"
    bash "$stage_script" "$@"
    echo
}

run_provision() {
    local user="${PREFS[primary_user]:-$(whoami)}"
    local hostname="${PREFS[hostname]:-}"
    local shell_choice="${PREFS[shell]:-bash}"

    if [[ "${PREFS[stage_base]:-n}" == "yes" ]]; then
        local base_args=()
        if [[ -n "$hostname" ]]; then
            base_args+=(--hostname "$hostname")
        fi
        [[ "${PREFS[base_timezone]:-n}" == "yes" ]] && base_args+=(--timezone)
        [[ "${PREFS[base_auto_updates]:-n}" == "yes" ]] && base_args+=(--auto-updates)
        run_stage "${STAGES_DIR}/stage-base.sh" "${base_args[@]+"${base_args[@]}"}"
    fi

    if [[ "${PREFS[stage_shell]:-n}" == "yes" ]]; then
        run_stage "${STAGES_DIR}/stage-shell.sh" --shell "$shell_choice" --user "$user"
    fi

    if [[ "${PREFS[stage_vim]:-n}" == "yes" ]]; then
        run_stage "${STAGES_DIR}/stage-vim.sh" --user "$user"
    fi

    if [[ "${PREFS[stage_tmux]:-n}" == "yes" ]]; then
        run_stage "${STAGES_DIR}/stage-tmux.sh" --user "$user"
    fi

    if [[ "${PREFS[stage_devtools]:-n}" == "yes" ]]; then
        run_stage "${STAGES_DIR}/stage-devtools.sh"
    fi

    if [[ "${PREFS[stage_docker]:-n}" == "yes" ]]; then
        run_stage "${STAGES_DIR}/stage-docker.sh" --user "$user"
    fi

    if [[ "${PREFS[stage_ssh]:-n}" == "yes" ]]; then
        local ssh_args=(--user "$user")
        [[ "${PREFS[ssh_generate_key]:-n}" == "yes" ]] && ssh_args+=(--generate-key)
        run_stage "${STAGES_DIR}/stage-ssh.sh" "${ssh_args[@]}"
    fi

    log_section "Provisioning Complete"
    log_ok "All done! You may want to reboot to apply all changes."
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    log_section "Debian Provisioning Script"

    # Check if individual stage was requested via args
    if [[ $# -gt 0 ]]; then
        # Pass-through mode: run a specific stage with given args
        local stage_name="$1"
        shift
        local stage_script="${STAGES_DIR}/stage-${stage_name}.sh"
        if [[ ! -f "$stage_script" ]]; then
            log_error "Unknown stage: ${stage_name}"
            log_error "Available stages:"
            for f in "${STAGES_DIR}"/stage-*.sh; do
                echo "  $(basename "$f" .sh | sed 's/stage-//')"
            done
            exit 1
        fi
        bash "$stage_script" "$@"
        return
    fi

    # Interactive mode
    gather_preferences
    run_provision
}

main "$@"
