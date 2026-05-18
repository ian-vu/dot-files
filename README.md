# My dotfiles

Dotfiles managed with [GNU stow](https://www.gnu.org/software/stow/). Running `stow --no-folding .` from the repo root symlinks config files into `~` while keeping repo-only nested files out of `$HOME`.

## Docs

- [GNU Stow](docs/stow.md) — how stow manages symlinks and file placement
- [Git Configuration](docs/git.md) — automatic identity switching per workspace
- [Age Encryption](docs/encryption.md) — encrypting/decrypting secrets with age
- [Bootstrap](docs/bootstrap.md) — installation and post-install setup
