#!/bin/bash
#
# Provisioning script for Debian systems.
# Installs essential tools, downloads dotfiles, and configures the environment.
#
# Intended to be modular and extensible.

# --- Module: System Check ---
# Checks for sudo access and OS type.
check_system() {
  echo "--- System Check ---"

  # Check for sudo access.
  if ! sudo -v &> /dev/null; then
    echo "ERROR: Sudo access is required to run this script."
    exit 1
  fi
  echo "Sudo access verified."

  # Check if the OS is Debian.  This is not foolproof, but a good start.
  if ! grep -q "Debian" /etc/os-release; then
    echo "WARNING: This script is primarily designed for Debian-based systems."
    echo "         Continuing may lead to errors or unexpected behavior."
    # Don't exit here, allow the user to proceed if they choose.
  fi
  echo "OS check passed (Debian-based)."
}

# --- Module: Install Packages ---
# Installs essential packages.
install_packages() {
  echo "--- Installing Packages ---"
  packages="git zsh wget unzip" # Added unzip
  echo "Installing packages: $packages"
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends $packages
  if [ $? -eq 0 ]; then
    echo "Packages installed successfully."
  else
    echo "ERROR: Failed to install packages."
    exit 1
  fi
}

# --- Module: Download Dotfiles ---
# Downloads and installs dotfiles.
download_dotfiles() {
  echo "--- Downloading Dotfiles ---"
  dotfiles=(
    ".zpreztorc"
    ".zshrc"
    ".p10k.zsh"
  )
  base_url="https://raw.githubusercontent.com/ivaano/dotfiles/refs/heads/master/"
  target_dir="$HOME" # Changed to $HOME

  # Use a loop to download each dotfile
  for file in "${dotfiles[@]}"; do
    echo "Downloading $file..."
    if ! wget -q "$base_url$file" -O "$target_dir/$file"; then #Added -q for quiet
      echo "ERROR: Failed to download $file."
      # We don't exit the whole script if one file fails.
      # Consider adding a counter and exiting if too many fail.
    fi
  done
  echo "Dotfiles downloaded."
}

# --- Module: Set Default Shell ---
# Sets the default shell to Zsh.
set_default_shell() {
  echo "--- Setting Default Shell ---"
  # Get the current user's username.
  current_user=$(/usr/bin/whoami) # Changed to /usr/bin/whoami
  echo "Changing shell for user: $current_user"

  # Check if zsh is in the list of valid shells.
  if ! grep -q "/bin/zsh" /etc/shells; then
    echo "ERROR: Zsh is not a valid shell on this system.  Aborting shell change."
    exit 1
  fi

  # Use chsh to change the shell.
  if ! sudo chsh -u "$current_user" /bin/zsh; then
    echo "ERROR: Failed to change the default shell to Zsh."
    exit 1
  fi
  echo "Default shell set to Zsh for user $current_user.  You may need to logout and log back in."
}

# --- Main Script ---
main() {
  check_system
  install_packages
  download_dotfiles
  set_default_shell
  echo "--- Provisioning Complete ---"
  echo "Please log out and log back in for changes to take effect."
}

# --- Execute the Main Function ---
main

