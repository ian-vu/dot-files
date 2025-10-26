mod homebrew '.homebrew'

# List available recipes
default:
    @just --list

# Symlink dot-files into home directory
[group: 'stow']
link:
    stow .

# Dry run to see what would be symlinked
[group: 'stow']
link-dry:
    stow --simulate .
