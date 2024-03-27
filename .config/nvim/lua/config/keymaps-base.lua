-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local Util = require("lazyvim.util")

-- unmap
vim.keymap.del({ "n", "v", "i" }, "<A-j>")
vim.keymap.del({ "n", "v", "i" }, "<A-k>")
vim.keymap.del("n", "<leader>cd")

-- misc
vim.keymap.set({ "n", "v", "i", "x", "o" }, "<C-c>", "<esc>", { desc = "Esc" })
vim.keymap.set("v", "p", '"_dP', { desc = "Paste without yank" })
vim.keymap.set({ "v" }, "<D-c>", "y", { desc = "Yank" })
vim.keymap.set({ "n", "v" }, "<D-a>", ":%y", { desc = "Yank whole buffer" })

-- format
vim.keymap.set({ "n", "v" }, "<leader>fm", function()
  Util.format({ force = true })
end, { desc = "Format" })

-- Buffers
local delete_buffer = function()
  local bd = require("mini.bufremove").delete
  if vim.bo.modified then
    local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
    if choice == 1 then -- Yes
      vim.cmd.write()
      bd(0)
    elseif choice == 2 then -- No
      bd(0, true)
    end
  else
    bd(0)
  end
end
vim.keymap.set({ "n", "v" }, "<C-x>", delete_buffer, { desc = "Delete Buffer" })
vim.keymap.set({ "n", "v" }, "<D-x>", delete_buffer, { desc = "Delete Buffer" })
vim.keymap.set({ "n", "v" }, "<leader>bx", delete_buffer, { desc = "Delete Buffer" })
vim.keymap.set(
  { "n", "v" },
  "<leader>ba",
  "<cmd>BufferLineGroupClose ungrouped<CR>",
  { desc = "Delete non-pinned buffers" }
)
vim.keymap.set({ "n", "v" }, "<C-<tab>", "<cmd>e #<CR>", { desc = "Switch to previous buffer" })
vim.keymap.set("n", "<D-n>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<D-j>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<D-e>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
vim.keymap.set("n", "<D-k>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })

-- Tabs
vim.keymap.set("n", "<C-`>", "g<tab>", { desc = "Switch to previous tab" })
vim.keymap.set("n", "<leader><tab>n", "<cmd>tabnew<cr>", { desc = "New Tab" })
vim.keymap.set("n", "<leader><tab>p", "<cmd>tabs<cr>", { desc = "Print tabs" })
vim.keymap.set("n", "<leader><tab>x", "<cmd>tabclose<cr>", { desc = "Close Tab" })

vim.keymap.set("n", "<D-w>", "<cmd>tabclose<cr>", { desc = "Close Tab" })
vim.keymap.set("n", "<D-n>", "<cmd>tabnew<cr>", { desc = "New Tab" })

-- Pane navigation
vim.keymap.set({ "n", "v", "i" }, "<C-h>", "<C-w>h", { desc = "Move to pane left" })
vim.keymap.set({ "n", "v", "i" }, "<C-l>", "<C-w>l", { desc = "Move to pane right" })
vim.keymap.set({ "n", "v", "i" }, "<C-j>", "<C-w>j", { desc = "Move to pane up" })
vim.keymap.set({ "n", "v", "i" }, "<C-k>", "<C-w>k", { desc = "Move to pane down" })

vim.keymap.set({ "n", "v", "i" }, "<D-h>", "<C-w>h", { desc = "Move to pane left" })
vim.keymap.set({ "n", "v", "i" }, "<D-l>", "<C-w>l", { desc = "Move to pane right" })
vim.keymap.set({ "n", "v", "i" }, "<D-j>", "<C-w>j", { desc = "Move to pane up" })
vim.keymap.set({ "n", "v", "i" }, "<D-k>", "<C-w>k", { desc = "Move to pane down" })

-- Telescope
vim.keymap.set({ "n", "v" }, "<leader>fw", "<cmd>Telescope egrepify<cr>", { desc = "Find words egrepify" })
vim.keymap.set({ "n", "v" }, "<leader>fW", "<cmd>Telescope live_grep<cr>", { desc = "Find words telescope" })
vim.keymap.set({ "n", "v" }, "<leader>fk", "<cmd>Telescope keymaps<CR>", { desc = "Find keymaps" })
vim.keymap.set({ "n", "v" }, "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Find help tags" })
vim.keymap.set({ "n", "v" }, "<D-p>", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
vim.keymap.set({ "n", "v" }, "<D-f>", "<cmd>Telescope egrepify<cr>", { desc = "Find words" })

-- Terminal
local lazyterm = function()
  Util.terminal(nil, { border = "rounded", cwd = Util.root() })
end
vim.keymap.set({ "n", "v" }, "<leader>tt", lazyterm, { desc = "Terminal (root dir)" })
vim.keymap.set({ "n", "v" }, "<C-\\>", lazyterm, { desc = "Terminal (root dir)" })
vim.keymap.set({ "n", "v" }, "<D-t>", lazyterm, { desc = "Terminal (root dir)" })
vim.keymap.set({ "n", "v" }, "<C-_>", lazyterm, { desc = "Terminal (root dir)" })

-- Neotree Plugin
vim.keymap.set({ "n", "v" }, "<C-n>", "<cmd>Neotree toggle<CR>", { desc = "Toggle Neotree", remap = true })
vim.keymap.set({ "n", "v" }, "<leader>ee", function()
  -- local Config = require("edgy.config")
  -- for p, edgebar in pairs(Config.layout) do
  --   if p == "left" then
  --     if #edgebar.wins == 0 then
  --       require("edgy").open("left")
  --     else
  --     end
  --   end
  -- end
  vim.api.nvim_command("Neotree action=focus position=left filesystem")
end, { desc = "Explorer Files", remap = true })
vim.keymap.set({ "n", "v" }, "<leader>eb", ":Neotree buffers<CR>", { desc = "Explorer buffers", remap = true })
-- vim.keymap.set({ "n", "v" }, "<leader>eb", function()
--   require("neo-tree.command").execute({
--     action = "focus", position = "left",
--     source = "buffers",
--     toggle = false,
--     reveal = true,
--   })
-- end,{ desc = "Explorer buffers", remap = true })
vim.keymap.set({ "n", "v" }, "<leader>eg", ":Neotree git_status<CR>", { desc = "Explorer git", remap = true })
-- vim.keymap.set({ "n", "v" }, "<leader>eg", function()
--   require("neo-tree.command").execute({
--     action = "focus",
--     position = "left",
--     source = "git_status",
--     toggle = false,
--   })
-- end, { desc = "Explorer git changes", remap = true })
vim.keymap.set({ "n", "v" }, "<leader>ef", function()
  require("neo-tree.command").execute({
    action = "focus",
    source = "filesystem",
    toggle = false,
    position = "float",
    reveal = true,
  })
end, { desc = "Explorer buffers", remap = true })
vim.keymap.set({ "n", "v" }, "<leader>ec", function()
  -- require("edgy").close("left")
  require("neo-tree.command").execute({ action = "close" })
end, { desc = "Close", remap = true })

-- Comment Plugin
local Comment = require("Comment.api")
vim.keymap.set({ "n" }, "<leader>/", Comment.toggle.linewise.current, { desc = "Comment line", noremap = true })
vim.keymap.set({ "n" }, "<D-/>", Comment.toggle.linewise.current, { desc = "Comment line", noremap = true })
vim.keymap.set(
  { "v" },
  "<leader>/",
  "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
  { desc = "Comment line", remap = true }
)
vim.keymap.set(
  { "v" },
  "<D-/>",
  "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
  { desc = "Comment line", remap = true }
)

-- diffview
vim.keymap.set({ "n", "v" }, "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "Git diff changes" })
vim.keymap.set(
  { "n", "v" },
  "<leader>gD",
  "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<CR>",
  { desc = "Git diff changes against base branch" }
)
vim.keymap.set({ "n", "v" }, "<leader>gf", "<cmd>DiffviewFileHistory %<CR>", { desc = "Git file history current" })
vim.keymap.set({ "n", "v" }, "<leader>gF", "<cmd>DiffviewFileHistory<CR>", { desc = "Git file branch history" })
vim.keymap.set({ "n", "v" }, "<leader>gx", "<cmd>DiffviewClose<CR>", { desc = "Git diff close" })
vim.keymap.set({ "n", "v" }, "<D-g>", "<cmd>DiffviewOpen<CR>", { desc = "Git diff changes" })

vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = true })

-- opening files in github
vim.keymap.set("n", "<leader>gor", "<cmd>OpenInGHRepo<CR>", { silent = true, desc = "Open Github Repository " })
vim.keymap.set("n", "<leader>gof", "<cmd>OpenInGHFile<CR>", { silent = true, desc = "Open file in Github" })
vim.keymap.set("n", "<leader>gol", "<cmd>OpenInGHFileLines<CR>", { silent = true, desc = "Open line in Github" })

--Save file
vim.keymap.set({ "i", "x", "n", "s" }, "<D-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
vim.keymap.set({ "i", "x", "n", "s" }, "<D-C-s>", "<cmd>wall<cr><esc>", { desc = "Save all files" })

-- Navigation
vim.keymap.set({ "i", "x", "n", "s", "v" }, "<C-d>", "<C-d>zz", { desc = "Move down half page", noremap = true })
vim.keymap.set({ "i", "x", "n", "s", "v" }, "<C-u>", "<C-u>zz", { desc = "Move up half page" })
vim.keymap.set({ "i", "x", "n", "s", "v" }, "<D-d>", "<C-d>", { desc = "Move down half page" })
vim.keymap.set({ "i", "x", "n", "s", "v" }, "<D-u>", "<C-u>", { desc = "Move up half page" })

-- Debugger
vim.keymap.set("n", "<leader>dd", function()
  require("dap").continue()
end, { desc = "Continue/Start debugger" })

-- Autocomplete CMP
vim.keymap.set({ "n", "v" }, "<leader>cd", function()
  local opts = {
    focusable = false,
    close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
    border = "rounded",
    source = "always",
    header = "",
    prefix = " ",
    -- Comment below only show when over the error portion of the line
    -- scope = "cursor",
    scope = "line",
  }
  vim.diagnostic.open_float(nil, opts)
end, { desc = "Line diagnostic" })

-- harpoon
vim.keymap.set({ "n", "v" }, "<leader>ha", function()
  require("harpoon"):list():append()
end, { desc = "Add current file" })
vim.keymap.set({ "n", "v" }, "<leader>hc", function()
  require("harpoon"):list():clear()
end, { desc = "Clear list" })
vim.keymap.set({ "n", "v" }, "<leader>hh", function()
  local harpoon = require("harpoon")
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Toggle UI" })

vim.keymap.set({ "n", "v", "i" }, "<C-1>", function()
  require("harpoon"):list():select(1)
end, { desc = "Select 1" })
vim.keymap.set({ "n", "v", "i" }, "<C-2>", function()
  require("harpoon"):list():select(2)
end, { desc = "Select 2" })
vim.keymap.set({ "n", "v", "i" }, "<C-3>", function()
  require("harpoon"):list():select(3)
end, { desc = "Select 3" })
vim.keymap.set({ "n", "v", "i" }, "<C-4>", function()
  require("harpoon"):list():select(4)
end, { desc = "Select 4" })

vim.keymap.set({ "n", "v", "i" }, "<D-1>", function()
  require("harpoon"):list():select(1)
end, { desc = "Select 1" })
vim.keymap.set({ "n", "v", "i" }, "<D-2>", function()
  require("harpoon"):list():select(2)
end, { desc = "Select 2" })
vim.keymap.set({ "n", "v", "i" }, "<D-3>", function()
  require("harpoon"):list():select(3)
end, { desc = "Select 3" })
vim.keymap.set({ "n", "v", "i" }, "<D-4>", function()
  require("harpoon"):list():select(4)
end, { desc = "Select 4" })

vim.keymap.set({ "n", "v" }, "<leader>1>", function()
  require("harpoon"):list():select(1)
end, { desc = "Select 1" })
vim.keymap.set({ "n", "v" }, "<leader>2>", function()
  require("harpoon"):list():select(2)
end, { desc = "Select 2" })
vim.keymap.set({ "n", "v" }, "<leader>3>", function()
  require("harpoon"):list():select(3)
end, { desc = "Select 3" })
vim.keymap.set({ "n", "v" }, "<leader>4>", function()
  require("harpoon"):list():select(4)
end, { desc = "Select 4" })

-- Toggle previous & next buffers stored within require("harpoon") list
vim.keymap.set({ "n", "v", "i" }, "<D-n>", function()
  require("harpoon"):list():next()
end, { desc = "Next in list" })
vim.keymap.set({ "n", "v", "i" }, "<D-e>", function()
  require("harpoon"):list():prev()
end, { desc = "Previous in list" })

vim.keymap.set({ "n", "v", "i" }, "<D-j>", function()
  require("harpoon"):list():next()
end, { desc = "Next in list" })
vim.keymap.set({ "n", "v", "i" }, "<D-k>", function()
  require("harpoon"):list():prev()
end, { desc = "Previous in list" })

-- neotest
vim.keymap.set("n", "<leader>tt", require("neotest").run.run, { desc = "Run nearest test" })
vim.keymap.set("n", "<leader>tf", require("neotest").run.run, { desc = "Run whole file" })
-- vim.keymap.set("n", "<leader>dt", function()
--   require("neotest").run.run({ strategy = "dap" })
-- end, { desc = "Debug nearest test" })
-- vim.keymap.set("n", "<leader>td", function()
--   require("neotest").run.run({ strategy = "dap" })
-- end, { desc = "Debug nearest test" })

-- Glance
vim.keymap.set({ "n", "v" }, "gD", "<CMD>Glance definitions<CR>", { desc = "Glance definitions" })
vim.keymap.set({ "n", "v" }, "gR", "<CMD>Glance references<CR>", { desc = "Glance references" })
vim.keymap.set({ "n", "v" }, "gY", "<CMD>Glance type_definitions<CR>", { desc = "Glance type definitions" })
vim.keymap.set({ "n", "v" }, "gM", "<CMD>Glance implementations<CR>", { desc = "Glance implementations" })

vim.keymap.set({ "n", "v" }, "<leader>cgd", "<CMD>Glance definitions<CR>", { desc = "Glance definitions" })
vim.keymap.set({ "n", "v" }, "<leader>cgr", "<CMD>Glance references<CR>", { desc = "Glance references" })
vim.keymap.set({ "n", "v" }, "<leader>cgy", "<CMD>Glance type_definitions<CR>", { desc = "Glance type definitions" })
vim.keymap.set({ "n", "v" }, "<leader>cgm", "<CMD>Glance implementations<CR>", { desc = "Glance implementations" })
