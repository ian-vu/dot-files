# Agent Instructions

## Repository Overview

This is a **dotfiles repository** that uses [GNU stow](https://www.gnu.org/software/stow/) to manage configuration files. The repo is cloned to `~/dot-files` and running `stow .` from the repo root creates symlinks for all files and directories into the user's home directory (`~`).

## How It Works

GNU stow treats the repo root as a "stow directory" and `~` as the target. Each top-level file or directory (other than ignored items like `.git`, `README.md`, `mac/`, `debian/`) is symlinked to the corresponding path under `~`. For example:

```
~/dot-files/.gitconfig   ->  ~/.gitconfig
~/dot-files/.config/nvim ->  ~/.config/nvim
```

## Important Conventions

- **File placement:** config files must be placed at the same relative path they occupy under `~`.
- **Secrets:** sensitive data is encrypted with `age`. Never commit plaintext secrets.
- **After creating new files:** re-run `stow .` from the repo root to create symlinks for them. Editing existing files does not require re-running stow.
- **Stow ignore check:** when creating a new file, ask the user whether it should be ignored by stow (i.e. not symlinked to `~`). Repo-only files like `.git-blame-ignore-revs` should be ignored. To ignore a file, add a regex pattern to `.stow-local-ignore` (e.g. `\.git-blame-ignore-revs`). Use `\.` for literal dots and `^/` prefix to match only at the repo root.
- **AI context files:** all AI/agent context belongs in `AGENTS.md`. When creating an `AGENTS.md` in any directory, always create a `CLAUDE.md` in the same directory that references it (containing just `@AGENTS.md`). This ensures Claude Code also picks up the context. Never put AI context directly in `CLAUDE.md`.
- **Documentation:** when adding or modifying code or configuration, include a brief comment explaining _why_ the change exists — especially for workarounds, non-obvious behaviour, or integration-specific logic.
