# languages/

Per-language Neovim plugin configuration. Each file configures LSP servers, formatters, treesitter overrides, and any other language-specific plugins for a single language (or language family).

## How to add a new language

1. Create `<language>.lua` returning a Lua table of [lazy.nvim](https://github.com/folke/lazy.nvim) plugin specs.
2. To add an LSP server, extend `nvim-lspconfig` opts with a `servers` entry. Mason auto-installs any server listed here. Example (`bash.lua`):
   ```lua
   return {
     {
       "neovim/nvim-lspconfig",
       opts = {
         servers = {
           bashls = {},
         },
       },
     },
   }
   ```
3. To add a formatter, extend `conform.nvim` opts with a `formatters_by_ft` entry (see `lua.lua`). If the LSP already provides formatting (e.g. rust-analyzer runs rustfmt), this is not needed — conform falls back to LSP formatting automatically.
4. Additional language-specific plugins (treesitter overrides, preview tools, etc.) go in the same file as separate specs in the returned table (see `markdown.lua`).

## Conventions

- One file per language. File name matches the language (e.g. `rust.lua`, `python.lua`).
- Extend existing plugin specs via `opts` — do not duplicate full plugin configurations that live in sibling files (e.g. `../lsp.lua`, `../autoformat.lua`).
- Mason ensure-install list in `../lsp.lua` auto-includes all servers defined here. Only add to that list for non-LSP tools (formatters, linters).
