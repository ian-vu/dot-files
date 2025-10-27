# Homebrew Configuration

This directory contains Homebrew configuration for managing packages across machines.

## Local Machine-Specific Packages

This setup supports both **shared packages** (tracked in git) and **machine-specific packages** (local only):

- **`Brewfile`** - Shared packages across all machines (version controlled)
- **`Brewfile.local`** - Machine-specific packages (git-ignored, lives in this directory)

### How It Works

The `just` recipes in this directory automatically merge both Brewfiles when running commands:

1. Checks if `Brewfile.local` exists in this directory
2. Merges it with the main `Brewfile` into a temporary file
3. Runs brew commands against the merged file
4. This ensures `cleanup` works correctly across both files

### Usage

1. **Create your local Brewfile** (one time per machine):

   ```bash
   touch .homebrew/Brewfile.local
   ```

2. **Add machine-specific packages**:

   ```bash
   # Edit .homebrew/Brewfile.local and add packages like:
   brew "work-specific-tool"
   cask "company-vpn"
   ```

3. **Use the just commands** - they automatically handle both files:
   ```bash
   just homebrew install        # Install from both Brewfiles
   just homebrew upgrade        # Upgrade all packages
   just homebrew cleanup        # Preview cleanup (safe)
   just homebrew cleanup-force  # Remove unlisted packages
   ```

## Configuration in .zshrc

The following Homebrew settings are configured in `~/.zshrc`:

```bash
# Disable auto update
export HOMEBREW_NO_AUTO_UPDATE=1
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
