#!/bin/bash

# This script is used to setup the macOS environment

# Install Homebrew and packages
if command -v brew >/dev/null 2>&1; then
  echo "Homebrew is already installed."
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Brew packages
brew bundle install

# Install mise (language version manager)
if ! command -v mise &>/dev/null; then
  echo "Installing mise..."
  curl https://mise.run | sh
  eval "$(~/.local/bin/mise activate zsh)"
fi

mise install

# Install and set up oh-my-zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "Oh My Zsh is already installed."
else
  echo "Oh My Zsh is not installed. Installing now..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # Check if the installation was successful
  if [ $? -eq 0 ]; then
    echo "Oh My Zsh has been successfully installed."
  else
    echo "There was an error installing Oh My Zsh. Please check your internet connection and try again."
  fi
fi

# Install oh-my-zsh plugins
CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

# Create the custom plugins directory if it doesn't exist
mkdir -p "$CUSTOM_PLUGINS_DIR"

# Function to install a plugin
install_plugin() {
  local plugin_name=$1
  local repo_url=$2
  local target_dir="$CUSTOM_PLUGINS_DIR/$plugin_name"

  if [ -d "$target_dir" ]; then
    echo "Plugin '$plugin_name' is already installed."
  else
    echo "Installing plugin '$plugin_name'..."
    git clone "$repo_url" "$target_dir"
    if [ $? -eq 0 ]; then
      echo "Plugin '$plugin_name' has been successfully installed."
    else
      echo "Error installing plugin '$plugin_name'. Please check your internet connection and try again."
    fi
  fi
}

# Install fzf-tab
install_plugin "fzf-tab" "https://github.com/Aloxaf/fzf-tab.git"

# Install fast-syntax-highlighting (which includes F-Sy-H)
install_plugin "fast-syntax-highlighting" "https://github.com/zdharma-continuum/fast-syntax-highlighting.git"

# Install zsh-autosuggestions
install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"

install_plugin "F-Sy-H" "https://github.com/z-shell/F-Sy-H.git"

# Install tmux plugin manager (tpm)
TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ -d "$TPM_DIR" ]; then
  echo "tmux plugin manager (tpm) is already installed."
else
  echo "tmux plugin manager (tpm) not found. Installing..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  tmux source ~/.tmux.conf
  if [ $? -eq 0 ]; then
    echo "tmux plugin manager (tpm) has been successfully installed."
  else
    echo "Failed to install tmux plugin manager (tpm). Please check your internet connection and try again."
  fi
fi

# Install poetry
if ! command -v poetry &>/dev/null; then
  echo "Installing poetry..."
  curl -sSL https://install.python-poetry.org | python3 -
  if [ $? -eq 0 ]; then
    echo "Poetry has been successfully installed."
  else
    echo "There was an error installing poetry. Please check your internet connection and try again."
  fi
fi

# Configure auto hide/appear dock settings
defaults write com.apple.dock autohide-time-modifier -float 0.7
defaults write com.apple.dock autohide-delay -float 0
killall Dock

# Disable hold down key showing accented characters popup
defaults write -g ApplePressAndHoldEnabled -bool false
