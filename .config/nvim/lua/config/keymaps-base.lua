-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local Util = require("lazyvim.util")

-- unmap
vim.keymap.del({ "n", "v", "i" }, "<A-k>")
vim.keymap.del("n", "<leader>cd")

-- These are used by tmux floating session
vim.keymap.del("n", "<C-/>")

-- misc
vim.keymap.set({ "n", "v", "i", "x", "o" }, "<C-c>", "<esc>", { desc = "Esc" })
vim.keymap.set("v", "p", '"_dP', { desc = "Paste without yank" })
vim.keymap.set("n", "<leader>p", "<cmd>pu<cr>", { desc = "Paste on new line" })
vim.keymap.set({ "v" }, "<D-c>", "y", { desc = "Yank" })
vim.keymap.set({ "n", "v" }, "<D-a>", ":%y", { desc = "Yank whole buffer" })
vim.keymap.set({ "n" }, "<c-k>", "<c-i>", { noremap = true, desc = "Jump forward" })

-- Centre cursor in buffer when motion
vim.keymap.set({ "n", "v" }, "G", "Gzz", { noremap = true, desc = "Centre cursor in buffer" })
-- vim.keymap.set({ "n", "v" }, "*", "*zz", { noremap = true, desc = "Centre cursor in buffer" })
-- vim.keymap.set({ "n", "v" }, "#", "#zz", { noremap = true, desc = "Centre cursor in buffer" })
-- vim.keymap.set({ "n", "v" }, "<c-o>", "<c-o>zz", { noremap = true, desc = "Centre cursor in buffer" })

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
vim.keymap.set("n", "<leader><tab><tab>", "g<tab>", { desc = "Switch to previous tab" })
vim.keymap.set("n", "<leader><tab>n", "<cmd>tabnew<cr>", { desc = "New Tab" })
vim.keymap.set("n", "<leader><tab>p", "<cmd>tabs<cr>", { desc = "Print tabs" })
vim.keymap.set("n", "<leader><tab>x", "<cmd>tabclose<cr>", { desc = "Close Tab" })

vim.keymap.set("n", "<D-w>", "<cmd>tabclose<cr>", { desc = "Close Tab" })
vim.keymap.set("n", "<D-n>", "<cmd>tabnew<cr>", { desc = "New Tab" })

-- Pane navigation (use integration with tmux with plug)
vim.keymap.set({ "n", "v", "i" }, "<D-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Move to pane left" })

-- vim.keymap.set({ "n", "v", "i" }, "<C-h>", "<C-w>h", { desc = "Move to pane left" })
-- vim.keymap.set({ "n", "v", "i" }, "<C-l>", "<C-w>l", { desc = "Move to pane right" })
-- vim.keymap.set({ "n", "v", "i" }, "<C-j>", "<C-w>j", { desc = "Move to pane up" })
-- vim.keymap.set({ "n", "v", "i" }, "<C-k>", "<C-w>k", { desc = "Move to pane down" })
--
-- vim.keymap.set({ "n", "v", "i" }, "<D-h>", "<C-w>h", { desc = "Move to pane left" })
-- vim.keymap.set({ "n", "v", "i" }, "<D-l>", "<C-w>l", { desc = "Move to pane right" })
-- vim.keymap.set({ "n", "v", "i" }, "<D-j>", "<C-w>j", { desc = "Move to pane up" })
-- vim.keymap.set({ "n", "v", "i" }, "<D-k>", "<C-w>k", { desc = "Move to pane down" })

-- Telescope
-- Find keymaps
vim.keymap.set({ "n", "v" }, "<leader>fw", "<cmd>Telescope egrepify<cr>", { desc = "Find words egrepify" })
vim.keymap.set({ "n", "v" }, "<leader>fW", "<cmd>Telescope live_grep<cr>", { desc = "Find words telescope" })
vim.keymap.set({ "n", "v" }, "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Find recent (cwd)" })
vim.keymap.set(
  { "n", "v" },
  "<leader>fr",
  LazyVim.pick("oldfiles", { cwd = vim.uv.cwd() }),
  { desc = "Find recent (cwd)" }
)
vim.keymap.set({ "n", "v" }, "<leader>fR", "<cmd>Telescope oldfiles<cr>", { desc = "Find recent" })
vim.keymap.set({ "n", "v" }, "<leader>fk", "<cmd>Telescope keymaps<CR>", { desc = "Find keymaps" })
vim.keymap.set({ "n", "v" }, "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Find help tags" })
vim.keymap.set({ "n", "v" }, "<leader>sf", "<cmd>Telescope filetypes<CR>", { desc = "Search filetypes" })
vim.keymap.set({ "n", "v" }, "<D-p>", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
vim.keymap.set({ "n", "v" }, "<D-f>", "<cmd>Telescope egrepify<cr>", { desc = "Find words" })

-- Search keympas
vim.keymap.set({ "n", "v" }, "<leader>sj", "<cmd>Telescope jumplist<CR>", { desc = "Search jumplist" })

-- Terminal
local lazyterm = function()
  Util.terminal(nil, { border = "rounded", cwd = Util.root() })
end
vim.keymap.set({ "n", "v" }, "<leader>tt", lazyterm, { desc = "Terminal (root dir)" })
vim.keymap.set({ "n", "v" }, "<C-\\>", lazyterm, { desc = "Terminal (root dir)" })
vim.keymap.set({ "n", "v" }, "<D-t>", lazyterm, { desc = "Terminal (root dir)" })
vim.keymap.set({ "n", "v" }, "<C-_>", lazyterm, { desc = "Terminal (root dir)" })

-- Oil Plugin
vim.keymap.set({ "n", "v" }, "<leader>ef", function()
  require("oil").open_float()
end, { desc = "Explorer buffers", remap = true })

-- Neotree Plugin
vim.keymap.set({ "n", "v" }, "<leader>es", function()
  vim.api.nvim_command("Neotree action=show position=left filesystem")
end, { desc = "Show Neotree" })
vim.keymap.set({ "n", "v" }, "<leader>eo", function()
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
vim.keymap.set({ "n", "v" }, "<leader>e", "<cmd>Oil<cr>", { desc = "Open oil in current window" })
-- Comment Plugin
-- Normal mode mappings
vim.keymap.set(
  "n",
  "<D-/>",
  "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>",
  { desc = "Comment line", noremap = true }
)
vim.keymap.set(
  "n",
  "<leader>/",
  "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>",
  { desc = "Comment line", noremap = true }
)

-- Visual mode mappings
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
vim.keymap.set({ "n" }, "<leader>gd", function()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf = vim.api.nvim_win_get_buf(win)
      local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
      if filetype == "DiffviewFiles" then
        vim.api.nvim_set_current_tabpage(tab)
        return
      end
    end
  end
  vim.cmd("DiffviewOpen")
end, { desc = "Diff view local changes" })
vim.keymap.set(
  { "n" },
  "<leader>gD",
  "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<CR>",
  { desc = "Diff view changes against origin/HEAD" }
)
vim.keymap.set({ "n" }, "<leader>gs", "<cmd>DiffviewFileHistory -g --range=stash<CR>", { desc = "Stash" })
vim.keymap.set({ "n" }, "<leader>gf", "<cmd>DiffviewFileHistory %<CR>", { desc = "File history current file only" })
vim.keymap.set(
  { "v" },
  "<leader>gl",
  "<cmd>'<,'>DiffviewFileHistory<CR>",
  { desc = "File history current selected lines" }
)
vim.keymap.set({ "n" }, "<leader>gF", "<cmd>DiffviewFileHistory<CR>", { desc = "File history with other files" })
vim.keymap.set({ "n" }, "<leader>gx", "<cmd>DiffviewClose<CR>", { desc = "Git diff close" })

-- Octo (pull request plugin)
vim.keymap.set({ "n" }, "<leader>gpl", function()
  print("Listing PRs...")
  vim.cmd("Octo pr list")
end, { desc = "List PRs" })
vim.keymap.set({ "n" }, "<leader>gpr", "<cmd>Octo review<CR>", { desc = "Review start/resume" })

vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = true })

-- opening files in github
vim.keymap.set("n", "<leader>gor", "<cmd>OpenInGHRepo<CR>", { silent = true, desc = "Open Github Repository " })
vim.keymap.set("n", "<leader>gof", "<cmd>OpenInGHFile<CR>", { silent = true, desc = "Open file in Github" })
vim.keymap.set("n", "<leader>gol", "<cmd>OpenInGHFileLines<CR>", { silent = true, desc = "Open line in Github" })

-- Git signs
vim.keymap.set("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>", { silent = true, desc = "Git blame current line" })
vim.keymap.set(
  "n",
  "<leader>gB",
  "<cmd>Gitsigns toggle_current_line_blame<CR>",
  { silent = true, desc = "Toggle current line blame" }
)

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

vim.keymap.set("n", "<leader>dr", function()
  require("dap").restart()
end, { desc = "Restart debugger" })

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

-- Helper functions for copy keymaps
local function get_file_line()
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  local current_file = vim.fn.expand("%:p")
  local relative_path

  if vim.v.shell_error == 0 and git_root ~= "" then
    relative_path = vim.fn.fnamemodify(current_file, ":s?" .. git_root .. "/??")
  else
    relative_path = vim.fn.expand("%")
  end

  return relative_path .. ":" .. vim.fn.line(".")
end

local function get_current_diagnostic()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
  if #diagnostics > 0 then
    return diagnostics[1].message
  end
  return nil
end

-- Copy current diagnostic message to clipboard
vim.keymap.set("n", "<leader>cyd", function()
  local message = get_current_diagnostic()
  if message then
    vim.fn.setreg("+", message)
    print("Copied diagnostic: " .. message)
  else
    print("No diagnostic on current line")
  end
end, { desc = "Copy diagnostic message" })

-- Copy current line number to clipboard
vim.keymap.set("n", "<leader>cyl", function()
  local file_line = get_file_line()
  vim.fn.setreg("+", file_line)
  print("Copied: " .. file_line)
end, { desc = "Copy line number" })

-- Copy current line number and diagnostic message to clipboard
vim.keymap.set("n", "cyD", function()
  local file_line = get_file_line()
  local diagnostic = get_current_diagnostic()

  if diagnostic then
    local result = string.format("Code path: %s, Diagnostic: %s", file_line, diagnostic)
    vim.fn.setreg("+", result)
    print("Copied: " .. result)
  else
    print("No diagnostic on current line")
  end
end, { desc = "Copy line number and diagnostic" })

-- harpoon
vim.keymap.set({ "n", "v" }, "<leader>ha", function()
  require("harpoon"):list():add()
end, { desc = "Add current file" })
vim.keymap.set({ "n", "v" }, "<leader>hc", function()
  require("harpoon"):list():clear()
end, { desc = "Clear list" })
vim.keymap.set({ "n", "v" }, "<leader>hh", function()
  local harpoon = require("harpoon")
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Toggle UI" })

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

vim.keymap.set({ "n", "v" }, "<leader>1", function()
  require("harpoon"):list():select(1)
end, { desc = "Select 1" })
vim.keymap.set({ "n", "v" }, "<leader>2", function()
  require("harpoon"):list():select(2)
end, { desc = "Select 2" })
vim.keymap.set({ "n", "v" }, "<leader>3", function()
  require("harpoon"):list():select(3)
end, { desc = "Select 3" })
vim.keymap.set({ "n", "v" }, "<leader>4", function()
  require("harpoon"):list():select(4)
end, { desc = "Select 4" })
vim.keymap.set({ "n", "v" }, "<leader>5", function()
  require("harpoon"):list():select(5)
end, { desc = "Select 5" })
vim.keymap.set({ "n", "v" }, "<leader>6", function()
  require("harpoon"):list():select(6)
end, { desc = "Select 6" })
vim.keymap.set({ "n", "v" }, "<leader>7", function()
  require("harpoon"):list():select(7)
end, { desc = "Select 7" })

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

-- -- Glance
-- vim.keymap.set({ "n", "v" }, "gD", "<cmd>Glance definitions<CR>", { desc = "Glance definitions" })
-- vim.keymap.set({ "n", "v" }, "gR", "<cmd>Glance references<CR>", { desc = "Glance references" })
-- vim.keymap.set({ "n", "v" }, "gY", "<cmd>Glance type_definitions<CR>", { desc = "Glance type definitions" })
-- vim.keymap.set({ "n", "v" }, "gM", "<cmd>Glance implementations<CR>", { desc = "Glance implementations" })
--
-- vim.keymap.set({ "n", "v" }, "<leader>cgd", "<cmd>Glance definitions<CR>", { desc = "Glance definitions" })
-- vim.keymap.set({ "n", "v" }, "<leader>cgr", "<cmd>Glance references<CR>", { desc = "Glance references" })
-- vim.keymap.set({ "n", "v" }, "<leader>cgy", "<cmd>Glance type_definitions<CR>", { desc = "Glance type definitions" })
-- vim.keymap.set({ "n", "v" }, "<leader>cgm", "<cmd>Glance implementations<CR>", { desc = "Glance implementations" })

-- Trouble
vim.keymap.set({ "n", "v" }, "<leader>xr", "<cmd>Trouble lsp_references<cr>", { desc = "References (Trouble)" })
vim.keymap.set({ "n", "v" }, "<leader>xd", "<cmd>Trouble lsp_definitions<cr>", { desc = "Definitions (Trouble)" })

-- Zenmode
vim.keymap.set({ "n", "v" }, "<leader>uz", "<cmd>ZenMode<cr>", { desc = "Toggle Zenmode" })

-- Copilot
-- vim.keymap.set({ "i" }, "<C-l>", "<Plug>(copilot-accept-word)", { desc = "Accept next copilot word" })

-- Undo tree
vim.keymap.set({ "n" }, "<leader>uu", "<cmd>UndotreeToggle<cr>", { desc = "Toggle Undotree" })

-- Obsidian
vim.keymap.set("n", "<leader>oo", "<cmd>ObsidianQuickSwitch<CR>", { desc = "Search notes" })
vim.keymap.set("n", "<leader>ow", "<cmd>ObsidianSearch<CR>", { desc = "Word search notes" })
vim.keymap.set("n", "<leader>ol", "<cmd>ObsidianLinks<CR>", { desc = "Links of notes" })
vim.keymap.set("n", "<leader>on", "<cmd>ObsidianNew<CR>", { desc = "New note" })
vim.keymap.set("n", "<leader>om", "<cmd>ObsidianTemplate<CR>", { desc = "Template search" })
vim.keymap.set("n", "<leader>oc", "<cmd>ObsidianToggleCheckbox<CR>", { desc = "Checkbox toggle" })
vim.keymap.set("n", "<leader>ot", "<cmd>ObsidianToday<CR>", { desc = "Today's note" })
vim.keymap.set("n", "<leader>oT", "<cmd>ObsidianTomorrow<CR>", { desc = "Tomorrow's note" })

-- breadcrumbs
vim.keymap.set("n", "<leader>cb", "<cmd>lua require('dropbar.api').pick()<CR>", { desc = "Select breadcrumbs" })

-- treesitter context
vim.keymap.set("n", "<leader>uH", function()
  require("treesitter-context").toggle()
end, { desc = "Toggle Header Treesitter Context" })
