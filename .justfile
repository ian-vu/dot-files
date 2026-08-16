mod brew '.homebrew'
mod mise '.config/mise'

# List available recipes (including those in modules)
default:
    @just --list --list-submodules

# Symlink dot-files into home directory
# Uses --no-folding so nested repo-only files (like Pi extension LSP config) stay out of $HOME.
[group('stow')]
link:
    stow --no-folding .

unlink:
    stow -D --no-folding .

relink: unlink link

# Dry run to see what would be symlinked
[group('stow')]
link-dry:
    stow --simulate --no-folding .

# Refresh skills tracked in the vendored-skills manifest from their upstream sources.
[group('skills')]
update-vendored-skills:
    .local/bin/update-vendored-skills

# Install dev-only types used by LSP when editing Pi extensions in this repo.
[group('pi')]
pi-extension-lsp:
    npm ci --prefix .pi/agent/extensions
