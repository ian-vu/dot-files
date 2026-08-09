# Agent Instructions

## Repository Overview

This is a **dotfiles repository** that uses [GNU stow](https://www.gnu.org/software/stow/) to manage configuration files. The repo is cloned to `~/dot-files` and running `stow --no-folding .` from the repo root creates symlinks for all non-ignored files and directories into the user's home directory (`~`).

## How It Works

GNU stow treats the repo root as a "stow directory" and `~` as the target. Each top-level file or directory (other than ignored items like `.git`, `README.md`, `mac/`, `debian/`) is symlinked to the corresponding path under `~`. For example:

```
~/dot-files/.gitconfig   ->  ~/.gitconfig
~/dot-files/.config/nvim ->  ~/.config/nvim
```

## Repository Map

- `.config/` — stowed XDG config for apps and tools.
- `.config/nvim/` — active Neovim configuration. `.config/nvim-lazyvim/` is deprecated; do not modify unless explicitly asked.
- `.config/ivu/wt/` and `.local/bin/wt` — reusable git worktree helper CLI.
- `.config/tmux/` — tmux config, scripts, themes, and worktree popup UI.
- `.pi/agent/` — Pi agent settings, extensions, themes, and local extension source.
- `.claude/` and `.codex/` — AI assistant commands, skills, and settings.
- `.homebrew/` — shared Homebrew bundle plus local-machine package support.
- `mac/` and `debian/` — platform bootstrap scripts; ignored by stow.
- `docs/` — repo documentation; ignored by stow.
- `.age/encrypted/` — encrypted secrets only. Never add plaintext secrets.

## Important Conventions

- **File placement:** config files must be placed at the same relative path they occupy under `~`.
- **Secrets:** sensitive data is encrypted with `age`. Never commit plaintext secrets.
- **After creating new files:** re-run `stow --no-folding .` from the repo root to create symlinks for them. Editing existing files does not require re-running stow. `--no-folding` keeps nested repo-only files from leaking into `~` through parent-directory symlinks.
- **Stow ignore check:** when creating a new file, ask the user whether it should be ignored by stow (i.e. not symlinked to `~`). Repo-only files like `.git-blame-ignore-revs` should be ignored. To ignore a file, add a regex pattern to `.stow-local-ignore` (e.g. `\.git-blame-ignore-revs`). Use `\.` for literal dots and `^/` prefix to match only at the repo root.
- **AI context files:** all AI/agent context belongs in `AGENTS.md`. When creating an `AGENTS.md` in any directory, always create a `CLAUDE.md` in the same directory that references it (containing just `@AGENTS.md`). This ensures Claude Code also picks up the context. Never put AI context directly in `CLAUDE.md`.
- **Documentation:** when adding or modifying code or configuration, include a brief comment only when it helps a first-time reader understand the current behavior. Comments should describe the configuration as it is now and why that behavior is needed, especially for workarounds, non-obvious behavior, or integration-specific logic. Avoid historical comments about what changed or what was removed; put that context in commit messages or chat summaries instead.

## Safety

- Prefer `trash` over `rm` on macOS. Avoid destructive `rm -rf` unless explicitly required.
- Prefer the `wt` helper over raw `git worktree add` so configured worktree directory and setup/linking conventions are applied.

## Cross-file Maintenance Rules

- For `wt` CLI changes:
  - Entrypoint: `.local/bin/wt`.
  - Behavior modules: `.config/ivu/wt/*.bash`.
  - Help text: `.config/ivu/wt/help.bash`.
  - Completion metadata: `.config/ivu/wt/completions.bash`.
  - Zsh completion shim: `.oh-my-zsh/custom/completions/_wt`.
- For tmux worktree UI changes:
  - Keep git/worktree behavior in `wt`.
  - Keep tmux/fzf/session behavior in `.config/tmux/bin/worktree/`.
- For Homebrew bundle merge behavior, keep `.homebrew/.justfile` and `mac/setup.sh` in sync.

## Neovim

Active config lives in `.config/nvim/`; `.config/nvim-lazyvim/` is deprecated.

Before changing Neovim config, read:

- `.config/nvim/AGENTS.md`
- The relevant nested `AGENTS.md` under `lua/config/`, `lua/plugins/`, `lua/plugins/languages/`, or `lua/plugins/snacks/`.

Key convention: static options go in `config/options.lua`, keymaps in `config/keymaps.lua`, autocmds in `config/autocmds.lua`, and plugin specs under `plugins/`.

## Pi Extensions

Pi extensions live under `.pi/agent/extensions/`.

- Runtime `.ts` extensions are loaded directly by Pi through `jiti`; there is no build step.
- `package.json`, `package-lock.json`, `node_modules/`, and `tsconfig.json` are local editor/type-checking support and intentionally ignored by stow.
- For extension work, read `.pi/agent/extensions/AGENTS.md`.
- For status bar work, read `.pi/agent/extensions/status-bar/AGENTS.md`.

## Useful Checks

- Stow preview: `just link-dry`.
- Apply stow links: `just link`.
- Pi extension type check: `npm ci --prefix .pi/agent/extensions` then `npx tsc --project .pi/agent/extensions/tsconfig.json`.
- List available root recipes: `just --list --list-submodules`.
- List global mise recipes: `just -g --list`.
