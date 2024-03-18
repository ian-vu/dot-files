-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = true -- relative lnie numbers
vim.opt.wrap = true -- wrap lines

vim.o.guifont = "JetBrainsMono Nerd Font:h14" -- Font

-- Title of window/nvim
vim.opt.title = true
local get_title = function()
  local path = vim.fn.getcwd()
  local last_path = path:match(".+/(.-)$")
  return last_path
end
vim.opt.titlestring = get_title()
