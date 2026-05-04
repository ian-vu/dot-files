mod brew '.homebrew'
mod mise '.config/mise'

# List available recipes (including those in modules)
default:
    @just --list --list-submodules

# Symlink dot-files into home directory
[group('stow')]
link:
    stow .

unlink:
    stow -D .

relink: unlink link

# Dry run to see what would be symlinked
[group('stow')]
link-dry:
    stow --simulate .
