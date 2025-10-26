mod homebrew '.homebrew'

default:
    @just --list

# Symlink dot-files into home directory
stow:
    stow .

# Dry run to see what would be symlinked
stow-dry:
    stow --simulate .
