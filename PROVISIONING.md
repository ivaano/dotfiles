# Debian Provisioning Scripts

A modular system for provisioning Debian systems. Each stage is an independent script that can be run on its own, or orchestrated together via an interactive menu.

## Directory Structure

```
scripts/
├── debian-provision.sh   # Interactive menu orchestrator
├── helpers.sh            # Shared utilities (sourcing target)
└── stages/
    ├── stage-base.sh     # Base packages, hostname, timezone, auto-updates
    ├── stage-shell.sh    # Shell (zsh/bash/fish) + Prezto + Powerlevel10k
    ├── stage-vim.sh      # Vim + vim-plug + plugins
    ├── stage-tmux.sh     # Tmux + configuration
    ├── stage-devtools.sh # Development tools (Python, Node, ripgrep, etc.)
    ├── stage-docker.sh   # Docker Engine + Compose
    └── stage-ssh.sh      # SSH client + optional key generation
```

## Quick Start

### Interactive Mode

Run the orchestrator and answer prompts to select what to install:

```bash
bash scripts/debian-provision.sh
```

It will ask:
1. **Primary username** — defaults to current user
2. **Hostname** — defaults to current hostname
3. **Preferred shell** — choose between zsh, bash, or fish
4. **Which stages to run** — each stage is listed with a `[Y/n]` prompt
5. **Sub-options** — e.g. timezone, auto-updates (if base selected), SSH key generation (if SSH selected)

A summary of all choices is shown before provisioning begins. Answer `n` to re-configure.

### Pass-Through Mode

You can also invoke a specific stage directly through the orchestrator:

```bash
bash scripts/debian-provision.sh docker --user myuser
bash scripts/debian-provision.sh shell --shell zsh --user myuser
```

This skips the interactive menu and runs only the named stage.

---

## Individual Stages

Each stage script can be run independently. All stages require `sudo` privileges.

### `stage-base.sh`

Installs essential system packages and optionally configures hostname, timezone, and automatic security updates.

**Packages installed:** `sudo`, `ca-certificates`, `curl`, `gnupg`, `apt-transport-https`, `git`

```bash
bash scripts/stages/stage-base.sh [OPTIONS]
```

| Flag              | Description                              |
| ----------------- | ---------------------------------------- |
| `--hostname NAME` | Set the system hostname                  |
| `--timezone`      | Enable NTP via `timedatectl`             |
| `--auto-updates`  | Install and enable `unattended-upgrades` |

**Examples:**

```bash
# Full base setup
bash scripts/stages/stage-base.sh --hostname myserver --timezone --auto-updates

# Just packages, no extras
bash scripts/stages/stage-base.sh
```

---

### `stage-shell.sh`

Installs and configures the user's preferred shell, deploys dotfiles, and (for zsh) clones Prezto, Powerlevel10k, and related plugins.

```bash
bash scripts/stages/stage-shell.sh --shell SHELL [OPTIONS]
```

| Flag              | Description                                        | Required |
| ----------------- | -------------------------------------------------- | -------- |
| `--shell SHELL`   | Shell to install: `zsh`, `bash`, or `fish`         | Yes      |
| `--user USERNAME` | Target user (defaults to current user)             | No       |

**Zsh extras cloned:**

- [Prezto](https://github.com/sorin-ionescu/prezto)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [fzf-tab](https://github.com/Aloxaf/fzf-tab)

**Examples:**

```bash
bash scripts/stages/stage-shell.sh --shell zsh --user ivan
bash scripts/stages/stage-shell.sh --shell fish
bash scripts/stages/stage-shell.sh --shell bash
```

---

### `stage-vim.sh`

Installs Vim, [vim-plug](https://github.com/junegunn/vim-plug), deploys `.vimrc`, and runs `PlugInstall`.

```bash
bash scripts/stages/stage-vim.sh [OPTIONS]
```

| Flag              | Description                            |
| ----------------- | -------------------------------------- |
| `--user USERNAME` | Target user (defaults to current user) |

**Example:**

```bash
bash scripts/stages/stage-vim.sh --user ivan
```

---

### `stage-tmux.sh`

Installs Tmux and deploys `.tmux.conf`.

```bash
bash scripts/stages/stage-tmux.sh [OPTIONS]
```

| Flag              | Description                            |
| ----------------- | -------------------------------------- |
| `--user USERNAME` | Target user (defaults to current user) |

**Example:**

```bash
bash scripts/stages/stage-tmux.sh --user ivan
```

---

### `stage-devtools.sh`

Installs common development tools. No flags.

**Packages installed:** `git`, `build-essential`, `pkg-config`, `python3`, `python3-pip`, `python3-venv`, `nodejs`, `npm`, `ripgrep`, `fd-find`, `fzf`, `eza`, `jq`, `tree`, `htop`, `openssh-client`

```bash
bash scripts/stages/stage-devtools.sh
```

---

### `stage-docker.sh`

Installs Docker Engine, CLI, containerd, Buildx plugin, and Docker Compose. Adds the target user to the `docker` group.

```bash
bash scripts/stages/stage-docker.sh [OPTIONS]
```

| Flag              | Description                                          |
| ----------------- | ---------------------------------------------------- |
| `--user USERNAME` | User to add to the `docker` group (default: current) |

**Example:**

```bash
bash scripts/stages/stage-docker.sh --user ivan
```

---

### `stage-ssh.sh`

Installs the OpenSSH client and optionally generates an ed25519 key pair.

```bash
bash scripts/stages/stage-ssh.sh [OPTIONS]
```

| Flag               | Description                                        |
| ------------------ | -------------------------------------------------- |
| `--user USERNAME`  | Target user (defaults to current user)             |
| `--generate-key`   | Generate `~/.ssh/id_ed25519` if it doesn't exist   |

**Examples:**

```bash
# Just the SSH client
bash scripts/stages/stage-ssh.sh --user ivan

# Client + key generation
bash scripts/stages/stage-ssh.sh --user ivan --generate-key
```

---

## Adding a New Stage

1. Create `scripts/stages/stage-<name>.sh`
2. Source helpers at the top:

   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "${SCRIPT_DIR}/../helpers.sh"
   ```

3. Parse arguments with a `while [[ $# -gt 0 ]]; do …` loop
4. Call `ensure_sudo` then your provisioning function
5. Add a `prompt_bool` entry and `run_stage` call in `debian-provision.sh`

## Dotfile Resolution

Each stage first looks for dotfiles in the local repo (`LOCAL_REPO`). If not found, it falls back to downloading from GitHub at `https://raw.githubusercontent.com/ivaano/dotfiles/main/…`.

Linux-specific dotfiles (`.zshrc`, `.zpreztorc`, `.p10k.zsh`) are pulled from the `linux/` directory. Shared dotfiles (`.vimrc`, `.tmux.conf`) are at the repo root.
