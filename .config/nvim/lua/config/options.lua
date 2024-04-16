-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = true -- relative lnie numbers
vim.opt.wrap = true -- wrap lines

-- vim.o.guifont = "JetBrainsMono Nerd Font:h14" -- Font
vim.o.guifont = "UbuntuMono Nerd Font Mono:h16" -- Font

-- Title of window/nvim
vim.opt.title = true
local get_title = function()
  local path = vim.fn.getcwd()
  local last_path = path:match(".+/(.-)$")
  return last_path
end
vim.opt.titlestring = get_title()

-- Affects how things are shown in Markdown: 0 will show all chars, 1 will show only the first char of concealable text
vim.opt.conceallevel = 1

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 15

-- Always show sign column since when going to and from insert mode shifts text
vim.opt.signcolumn = "yes"
