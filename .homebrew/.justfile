default:
    @just --list

# Install Homebrew packages from Brewfile without upgrading
install:
    brew bundle --global install --no-upgrade

# Update Homebrew packages from Brewfile
upgrade:
    brew bundle --global upgrade

# Dry run to see what would be cleaned up
cleanup:
    brew bundle cleanup --global

# Uninstall packages not listed in Brewfile
cleanup-force:
    brew bundle cleanup --global --force
