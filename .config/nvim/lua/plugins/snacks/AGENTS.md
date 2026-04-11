# snacks/

Per-feature configuration for [snacks.nvim](https://github.com/folke/snacks.nvim). Each feature has its own file.

## How it works

Lazy.nvim's `{ import = "plugins" }` discovers this folder via `init.lua`. The `{ import = "plugins.snacks" }` directive inside `init.lua` then tells lazy.nvim to scan for sibling `.lua` files. Each file returns a lazy.nvim spec for `folke/snacks.nvim` with just its `opts` — lazy.nvim deep-merges all `opts` into a single plugin configuration.

## File layout

- **`init.lua`** — Base plugin spec (`priority`, `lazy`) and the `{ import = "plugins.snacks" }` directive. No feature opts or init logic here.
- **`bigfile.lua`** — Optimized handling of large files.
- **`bufdelete.lua`** — Better buffer deletion.
- **`debug.lua`** — Global debugging helpers (`_G.dd`, `_G.bt`, `vim.print` override).
- **`git.lua`** — Git blame integration.
- **`gitbrowse.lua`** — Open file in GitHub.
- **`indent.lua`** — Indent guides, chunk highlighting.
- **`notifier.lua`** — Notification popups (`vim.notify`), input styling, and notify title stripping.
- **`picker.lua`** — Picker (telescope alternative): layouts, sources, formatters, keymaps, trouble integration.
- **`quickfile.lua`** — Fast file rendering before plugins load.
- **`rename.lua`** — LSP rename integration (used by Oil).
- **`scope.lua`** — Scope detection (treesitter/indent).
- **`scratch.lua`** — Scratch buffers for testing code.
- **`statuscolumn.lua`** — Status column symbols (marks, folds).
- **`toggle.lua`** — Toggle keymaps with which-key integration.
- **`words.lua`** — Auto-show LSP references.

## How to add a new snacks feature

Create a new `.lua` file named after the feature:

```lua
-- Description of the feature
return {
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      my_feature = {
        enabled = true,
        -- feature options here
      },
    },
  },
}
```

The file is auto-discovered by lazy.nvim — no registration needed.

## Feature-specific init logic

Lazy.nvim only merges `opts` and `keys` across specs — `init` functions don't merge. For feature-specific setup that needs to run at startup, register a `VeryLazy` autocmd directly at the module level (outside the return table):

```lua
-- Setup that runs after all plugins load
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    -- feature-specific init logic here
  end,
})

return {
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = { ... },
  },
}
```

This pattern is used by `debug.lua`, `notifier.lua`, and `toggle.lua`. The autocmd registers when lazy.nvim loads the file, then fires at the correct time.

## Conventions

- One file per feature, named to match the snacks module (e.g. `picker.lua` for `opts.picker`).
- Extend via `opts` merging — every file returns `{ { "folke/snacks.nvim", opts = { ... } } }`.
- Only `init.lua` should set `priority` or `lazy` — these don't merge across specs.
- Feature-specific init logic uses a module-level `VeryLazy` autocmd, not the spec's `init` field.
