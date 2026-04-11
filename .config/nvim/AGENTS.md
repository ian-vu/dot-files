# Neovim Configuration

## Structure

```
init.lua              — Entry point. Loads config/ modules, bootstraps lazy.nvim, and sets up plugin loading.
lua/
  config/             — Core editor settings (loaded before plugins)
    init.lua          — Requires options, keymaps, and autocmds in order
    options.lua       — vim.o / vim.opt settings (static values only, no autocmds)
    keymaps.lua       — Key mappings
    autocmds.lua      — Autocommands (FileType overrides, event handlers, etc.)
    icons.lua         — Shared icon definitions
    idle_mode.lua     — Idle/screensaver mode logic
    neovide.lua       — Neovide GUI-specific settings
  plugins/            — Plugin specs for lazy.nvim (one file per concern)
    languages/        — Per-language plugin configuration (LSP, formatters, treesitter)
  utils/              — Shared utility functions
```

## Where to put things

- **Static vim options** (`vim.o`, `vim.opt`): `config/options.lua`
- **Autocommands** (`nvim_create_autocmd`): `config/autocmds.lua` — even if an autocmd overrides a vim option (e.g. `formatoptions`), it belongs here, not in options.lua.
- **Key mappings** (non-plugin): `config/keymaps.lua`
- **Plugin configuration**: `plugins/<concern>.lua` — one file per logical concern (e.g. `lsp.lua`, `git.lua`, `autoformat.lua`).
- **Language-specific plugins**: `plugins/languages/<language>.lua` — see `plugins/languages/AGENTS.md` for conventions.

## Notifications

Three notification styles are available, each suited to different contexts:

1. **Big popup** (`Snacks.notify` / `vim.notify`): Full notification popup via Snacks notifier (`plugins/snacks.lua`). Use for important alerts that need attention.
2. **Small inline** (noice "mini" view): Subtle text at the bottom of the screen — same style as the "written" message on save. Requires two changes: (a) emit the message via `vim.cmd.echo("'message'")`, and (b) add a `{ find = "message" }` entry to the noice `routes` filter in `plugins/ui.lua` so it renders with `view = "mini"` instead of a big popup.
3. **LSP progress** (fidget.nvim): Automatic spinner for LSP progress events (`plugins/lsp.lua`). No manual setup needed — LSP servers emit these automatically.

## Conventions

- Config modules in `config/` are loaded by `config/init.lua` in a fixed order: options → keymaps → autocmds. Do not add `require` calls elsewhere for these.
- Plugin specs use [lazy.nvim](https://github.com/folke/lazy.nvim) format. Extend existing plugins via `opts` merging rather than duplicating full specs.
- Comments should explain _why_, not _what_ — especially for workarounds or non-obvious overrides of default behaviour.
