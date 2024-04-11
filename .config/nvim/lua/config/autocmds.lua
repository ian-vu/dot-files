-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Auto save
-- vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
--   pattern = { "*" },
--   command = "silent! wall",
--   nested = true,
-- })

-- Telescope set line number
vim.cmd("autocmd User TelescopePreviewerLoaded setlocal number")
vim.cmd("autocmd User TelescopePreviewerLoaded setlocal wrap")

-- Code diagnostics on cursor hold
-- vim.api.nvim_create_autocmd("CursorHold", {
--   buffer = bufnr,
--   callback = function()
--     local opts = {
--       focusable = false,
--       close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
--       border = "rounded",
--       source = "always",
--       header = "",
--       prefix = " ",
--       -- Comment below only show when over the error portion of the line
--       -- scope = "cursor",
--       scope = "line",
--     }
--     vim.diagnostic.open_float(nil, opts)
--   end,
-- })

-- Allow for alt backspace This currently causes esc to be buggy
-- vim.cmd("imap <esc><bs> <c-w>")

-- Update format options. Using the options.lua file does not work
-- removing `o` will stop comment when using `o` in normal mode
vim.api.nvim_create_autocmd("FileType", {
  command = "set formatoptions-=o",
})
