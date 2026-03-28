mod brew '.homebrew'

# List available recipes
default:
    @just --list

# Symlink dot-files into home directory
[group: 'stow']
link:
    stow .
unlink:
    stow -D .
relink: unlink link


# Dry run to see what would be symlinked
[group: 'stow']
link-dry:
    stow --simulate .
