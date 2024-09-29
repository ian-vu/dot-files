#!/bin/bash

#########################################################################################
# Install APT packages
#########################################################################################
apt_packages=(
  "stow"
  "gcc"
  "unzip"
  "zsh"
  "zsh-autosuggestions"
  "fzf"
  "zoxide"
  "make"
  "ripgrep"
)

# Update apt package list
sudo apt update

# Install apt packages
for package in "${apt_packages[@]}"; do
  if ! command -v "$package" &>/dev/null; then
    echo "Installing $package..."
    sudo apt install -y "$package"
  else
    echo "$package is already installed."
  fi
done

#########################################################################################
# Install mise (language version manager)
#########################################################################################
if ! command -v mise &>/dev/null; then
  echo "Installing mise..."
  curl https://mise.run | sh
  eval "$(~/.local/bin/mise activate zsh)"
fi

#########################################################################################
# Install languages
#########################################################################################

# This will look into ~/.tool-versions
mise install

#########################################################################################
# Install go packages
#########################################################################################
go_packages=(
  "github.com/jesseduffield/lazygit@latest"
  "github.com/joshmedeski/sesh@latest"
)

# Install go packagese
for package in "${go_packages[@]}"; do
  if ! command -v "$package" &>/dev/null; then
    echo "Installing $package..."
    go install "$package"
  else
    echo "$package is already installed."
  fi
done

#########################################################################################
# Install github deb packages
#########################################################################################

# Associative array to store package names and their corresponding URLs
declare -A github_deb_packages=(
  ["delta"]="https://github.com/dandavison/delta/releases/download/0.17.0/git-delta_0.17.0_arm64.deb"
  # Add more packages here in the format: ["package_name"]="package_url"
)

for package_name in "${!github_deb_packages[@]}"; do
  package_url="${github_deb_packages[$package_name]}"

  if ! command -v "$package" &>/dev/null; then
    echo "Installing $package_name..."

    # Extract the filename from the URL
    deb_file=$(basename "$package_url")

    # Use /tmp directory for downloading and installing
    tmp_path="/tmp/$deb_file"

    # Download the .deb file to /tmp
    if wget -O "$tmp_path" "$package_url"; then
      # Install the .deb package from /tmp
      if sudo dpkg -i "$tmp_path"; then
        echo "$package_name installed successfully."
      else
        echo "Failed to install $package_name. Please check the package and try again."
      fi

      # Clean up the downloaded .deb file from /tmp
      rm "$tmp_path"
    else
      echo "Failed to download $package_name. Please check the URL and try again."
    fi
  else
    echo "$package_name is already installed."
  fi
done

#########################################################################################
# Install neovim
#########################################################################################
sudo snap install neovim --classic

#########################################################################################
# Install TPM
#########################################################################################

if [ ! -d "$TPM_DIR" ]; then
  echo "TPM directory not found. Cloning the repository..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "TPM directory already exists."
fi
