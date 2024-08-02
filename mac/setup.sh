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

# Configure auto hide/appear dock settings
defaults write com.apple.dock autohide-time-modifier -float 0.7
defaults write com.apple.dock autohide-delay -float 0
killall Dock
