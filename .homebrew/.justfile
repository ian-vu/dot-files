default:
    @just --list

# Merge global Brewfile with local machine-specific Brewfile (if it exists)
_merge_brew_files:
    #!/usr/bin/env bash
    BREWFILE_DIR="{{ source_directory() }}"
    LOCAL_BREWFILE="$BREWFILE_DIR/Brewfile.local"
    GIT_BREWFILE="$BREWFILE_DIR/Brewfile"
    if [ -f "$LOCAL_BREWFILE" ]; then
        cat "$GIT_BREWFILE" > /tmp/Brewfile.merged
        cat "$LOCAL_BREWFILE" >> /tmp/Brewfile.merged
    else
        cat "$GIT_BREWFILE" > /tmp/Brewfile.merged
    fi

# Install Homebrew packages from Brewfile without upgrading
install: _merge_brew_files
    brew bundle --file=/tmp/Brewfile.merged install --no-upgrade

# Update Homebrew packages from Brewfile
upgrade: _merge_brew_files
    brew bundle --file=/tmp/Brewfile.merged upgrade

# Dry run to see what would be cleaned up
cleanup: _merge_brew_files
    brew bundle cleanup --file=/tmp/Brewfile.merged

# Uninstall packages not listed in Brewfile
cleanup-force: _merge_brew_files
    brew bundle cleanup --file=/tmp/Brewfile.merged --force
