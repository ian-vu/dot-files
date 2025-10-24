# Homebrew Configuration

This directory contains Homebrew configuration for managing packages.

## Configuration in .zshrc

The following Homebrew settings are configured in `~/.zshrc`:

```bash
# Disable auto update
export HOMEBREW_NO_AUTO_UPDATE=1
# Set global Brewfile location
export HOMEBREW_BUNDLE_FILE_GLOBAL='~/.homebrew/Brewfile'

```

### Bundle Commands

```bash
# Install all packages from Brewfile
brew bundle --global

# Install all packages from Brewfile and upgrade existing packages
brew bundle --global --upgrade

# Check what would be installed/upgraded
brew bundle check --global

# Dry run to see what would be cleaned up
brew bundle cleanup --global

# Uninstall packages not listed in Brewfile
brew bundle cleanup --global --force

```

## Essential Brew Commands

### Installation & Removal

```bash
# Install a package
brew install <package>

# Install a GUI application (cask)
brew install --cask <app>

# Uninstall a package
brew uninstall <package>

# Uninstall a cask
brew uninstall --cask <app>

# Uninstall package and all its dependencies (if unused)
brew autoremove
```

## Resources

- [Homebrew Documentation](https://docs.brew.sh/)
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle)
- [Formulae Search](https://formulae.brew.sh/)
- [Cask Room](https://github.com/Homebrew/homebrew-cask)
