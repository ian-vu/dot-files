# GNU Stow

This repo uses [GNU stow](https://www.gnu.org/software/stow/) to manage dotfiles. Stow treats the repo root (`~/dot-files`) as the "stow directory" and symlinks everything into the home directory (`~`).

See [this video](https://www.youtube.com/watch?v=y6XCebnB9gs) for a walkthrough of how stow works.

## How it works

Each top-level file or directory (other than ignored items) is symlinked to the corresponding path under `~`. For example:

```
~/dot-files/.gitconfig   ->  ~/.gitconfig
~/dot-files/.config/nvim ->  ~/.config/nvim
```

Running `stow .` from the repo root creates or updates the symlinks.

## File placement

Config files must be placed at the **same relative path** they occupy under `~`. For example, a Neovim config that lives at `~/.config/nvim/init.lua` should be at `dot-files/.config/nvim/init.lua` in the repo.

## Ignoring files

Not everything in the repo should be symlinked (e.g. `README.md`, `docs/`, platform-specific setup scripts). The `.stow-local-ignore` file controls what stow skips.

Pattern syntax:

| Pattern | Matches |
|---------|---------|
| `foo` | `foo` at any depth |
| `^/foo` | `foo` only at the repo root |
| `\.txt` | Literal `.txt` (use `\.` for dots) |

After editing `.stow-local-ignore`, re-run `stow .` to apply the changes.
