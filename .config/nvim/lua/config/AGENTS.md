# config/

Core editor settings loaded before any plugins. Loaded by `init.lua` in this order: **options → keymaps → autocmds**.

## File responsibilities

| File            | Contains                               | Does NOT contain           |
| --------------- | -------------------------------------- | -------------------------- |
| `options.lua`   | Static `vim.o` / `vim.opt` assignments | Autocommands, key mappings |
| `keymaps.lua`   | Editor-wide key mappings (non-plugin)  |
| `autocmds.lua`  | All `nvim_create_autocmd` calls        | Static option assignments  |
| `icons.lua`     | Shared icon table used by plugins      |                            |
| `idle_mode.lua` | Idle/screensaver mode setup            |                            |
| `neovide.lua`   | Neovide GUI-specific overrides         |                            |

## Key rule

If something uses `nvim_create_autocmd`, it goes in `autocmds.lua` — even if its purpose is to override a vim option (e.g. removing `o` from `formatoptions` on `FileType`). The `options.lua` file is strictly for static assignments.
