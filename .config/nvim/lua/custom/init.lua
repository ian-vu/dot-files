-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })

vim.cmd "autocmd User TelescopePreviewerLoaded setlocal number"

-- Defines what happends on nvim tree open
local function open_nvim_tree(data)

  -- buffer is a directory
  local directory = vim.fn.isdirectory(data.file) == 1

  if directory then
    -- change to the directory
    vim.cmd.cd(data.file)
    -- open the tree
    require("nvim-tree.api").tree.open()
  end

end

-- Always run open nvim tree on startup
vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

-- Source vimrc file
vim.cmd('source  /Users/ivu/.vim/vimrc')