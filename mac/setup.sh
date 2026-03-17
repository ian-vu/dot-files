#!/bin/bash

# This script is used to setup the macOS environment

# --- Logging helpers ---

log_info() { echo "[INFO]  $*"; }
log_skip() { echo "[SKIP]  $*"; }
log_ok()   { echo "[OK]    $*"; }
log_fail() { echo "[FAIL]  $*"; }

# --- Install helpers ---

# Idempotently install a CLI tool. Checks if a command exists on PATH;
# if not, runs the provided install command.
ensure_cli_command() {
  local name=$1; shift
  if command -v "$name" &>/dev/null; then
    log_skip "$name is already installed"
  else
    log_info "Installing $name..."
    if "$@"; then
      log_ok "$name installed successfully"
    else
      log_fail "$name installation failed"
    fi
  fi
}

# Idempotently clone a git repository. Checks if the destination directory
# exists; if not, clones the repo.
ensure_git_repo_clone() {
  local name=$1 repo=$2 dest=$3
  if [ -d "$dest" ]; then
    log_skip "$name is already installed"
  else
    log_info "Installing $name..."
    if git clone "$repo" "$dest"; then
      log_ok "$name installed successfully"
    else
      log_fail "$name installation failed"
    fi
  fi
}

# --- Homebrew ---

ensure_cli_command brew /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install Brew packages
# NOTE: This merge logic is duplicated from .homebrew/.justfile — keep both in sync.
BREWFILE_DIR="$HOME/.homebrew"
if [ -f "$BREWFILE_DIR/Brewfile.local" ]; then
  cat "$BREWFILE_DIR/Brewfile" > /tmp/Brewfile.merged
  cat "$BREWFILE_DIR/Brewfile.local" >> /tmp/Brewfile.merged
else
  cat "$BREWFILE_DIR/Brewfile" > /tmp/Brewfile.merged
fi
brew bundle install --file=/tmp/Brewfile.merged --no-upgrade

# --- mise (language version manager) ---

ensure_cli_command mise curl https://mise.run
if ! command -v mise &>/dev/null; then
  eval "$(~/.local/bin/mise activate zsh)"
fi

mise install

# --- oh-my-zsh ---

ensure_git_repo_clone "oh-my-zsh" \
  "https://github.com/ohmyzsh/ohmyzsh.git" \
  "$HOME/.oh-my-zsh"

# --- oh-my-zsh plugins ---

CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
mkdir -p "$CUSTOM_PLUGINS_DIR"

ensure_git_repo_clone "fzf-tab" \
  "https://github.com/Aloxaf/fzf-tab.git" \
  "$CUSTOM_PLUGINS_DIR/fzf-tab"

ensure_git_repo_clone "fast-syntax-highlighting" \
  "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" \
  "$CUSTOM_PLUGINS_DIR/fast-syntax-highlighting"

ensure_git_repo_clone "zsh-autosuggestions" \
  "https://github.com/zsh-users/zsh-autosuggestions.git" \
  "$CUSTOM_PLUGINS_DIR/zsh-autosuggestions"

ensure_git_repo_clone "F-Sy-H" \
  "https://github.com/z-shell/F-Sy-H.git" \
  "$CUSTOM_PLUGINS_DIR/F-Sy-H"

# --- tmux plugin manager (tpm) ---

ensure_git_repo_clone "tpm" \
  "https://github.com/tmux-plugins/tpm" \
  "$HOME/.tmux/plugins/tpm"

# --- poetry ---

ensure_cli_command poetry /bin/bash -c "curl -sSL https://install.python-poetry.org | python3 -"

# --- Claude Code ---
# Check the binary directly since `claude` is aliased in .zshrc

if [ -f "$HOME/.local/bin/claude" ]; then
  log_skip "Claude Code is already installed"
else
  log_info "Installing Claude Code..."
  if curl -fsSL https://claude.ai/install.sh | bash; then
    log_ok "Claude Code installed successfully"
  else
    log_fail "Claude Code installation failed"
  fi
fi

# --- macOS defaults ---

# Configure auto hide/appear dock settings
defaults write com.apple.dock autohide-time-modifier -float 0.7
defaults write com.apple.dock autohide-delay -float 0
killall Dock

# Disable hold down key showing accented characters popup
defaults write -g ApplePressAndHoldEnabled -bool false
