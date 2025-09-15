-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<esc><esc>", "<cmd>noh<cr>")
vim.keymap.set("n", "<esc><C-c>", "<cmd>noh<cr>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<c-\\><c-n>", { desc = "Exit terminal mode" })

--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<c-h>", "<c-w><c-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<c-l>", "<c-w><c-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<c-j>", "<c-w><c-j>", { desc = "Move focus to the lower window" })

-- Code diagnostics
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

-- lsp
vim.keymap.set({ "n" }, "<leader>cr", vim.lsp.buf.rename, { desc = "Rename" })
vim.keymap.set({ "n" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
vim.keymap.set({ "n" }, "<C-k>", function()
	vim.cmd("normal! w")
	vim.cmd("startinsert")
	require("blink.cmp").show({ providers = { "lsp" } })
end, { desc = "Show LSP completion on current word" })

-- misc
vim.keymap.set({ "n", "v", "i", "x", "o" }, "<C-c>", "<esc>", { desc = "Esc" })
-- vim.keymap.set('n', '<leader>p', '<cmd>pu<cr>', { desc = 'Paste on new line' })

vim.keymap.set({ "n", "v" }, "G", "Gzz", { noremap = true, desc = "Centre cursor in buffer" })
vim.keymap.set("n", "<C-m>", "<C-i>", { desc = "Jump list forwards", noremap = true })

-- tabs
vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<cr>", { desc = "New Tab" })
vim.keymap.set("n", "<leader>tx", "<cmd>tabclose<cr>", { desc = "Close Tab" })
vim.keymap.set("n", "<leader>tt", "g<tab>", { desc = "Switch to previous tab" })
vim.keymap.set("n", "<leader>t1", ":tabn 1<cr>", { desc = "Switch to tab 1" })
vim.keymap.set("n", "<leader>t2", ":tabn 2", { desc = "Switch to tab 2" })
vim.keymap.set("n", "<leader>t3", ":tabn 3", { desc = "Switch to tab 3" })
vim.keymap.set("n", "<leader>t4", ":tabn 4", { desc = "Switch to tab 4" })
vim.keymap.set("n", "<leader>t5", ":tabn 5", { desc = "Switch to tab 5" })

-- Buffers
vim.keymap.set({ "n", "v", "x" }, "<leader>bb", "<cmd>e #<CR>", { desc = "Switch to previous buffer" })

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

vim.keymap.set("n", "<leader>fp", function()
	local harpoon = require("harpoon")
	local function generate_harpoon_picker()
		local file_paths = {}
		for _, item in ipairs(harpoon:list().items) do
			table.insert(file_paths, {
				text = item.value,
				file = item.value,
			})
		end
		return file_paths
	end

	Snacks.picker.files({
		finder = generate_harpoon_picker,
	})
end)

-- colemak
-- Navigate between tmux panes - Alt keys take precedence over letter remapping
--  See `:help vim-tmux-navigator`
vim.keymap.set(
	{ "n", "v", "i" },
	"<M-h>",
	"<cmd>TmuxNavigateLeft<cr>",
	{ noremap = true, silent = true, desc = "Move to pane left" }
)
vim.keymap.set(
	{ "n", "v", "i" },
	"<M-n>",
	"<cmd>TmuxNavigateDown<cr>",
	{ noremap = true, silent = true, desc = "Move to pane down" }
)
vim.keymap.set(
	{ "n", "v", "i" },
	"<M-e>",
	"<cmd>TmuxNavigateUp<cr>",
	{ noremap = true, silent = true, desc = "Move to pane up" }
)
vim.keymap.set(
	{ "n", "v", "i" },
	"<M-i>",
	"<cmd>TmuxNavigateRight<cr>",
	{ noremap = true, silent = true, desc = "Move to pane right" }
)

-- Allow for navigation with wrapped lines
vim.keymap.set({ "n", "x" }, "n", "v:count == 0 ? 'gj' : 'j'", { expr = true, noremap = true, silent = true })
vim.keymap.set({ "v", "o" }, "n", "j", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "N", "J", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "j", "nzz", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "J", "Nzz", { noremap = true, silent = true })

-- Allow for navigation with wrapped lines
vim.keymap.set({ "n", "x" }, "e", "v:count == 0 ? 'gk' : 'k'", { expr = true, noremap = true, silent = true })
vim.keymap.set({ "v", "o" }, "e", "k", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "E", "K", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "k", "e", { noremap = true, silent = true })

-- Colemak letter remapping (but preserve Alt combinations)
vim.keymap.set({ "n", "v", "x", "o" }, "i", "l", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "I", "L", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "l", "i", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "L", "I", { noremap = true, silent = true })

-- Re-establish Alt keymaps after letter remapping to ensure they take precedence
vim.keymap.set(
	{ "n", "v", "i" },
	"<M-h>",
	"<cmd>TmuxNavigateLeft<cr>",
	{ noremap = true, silent = true, desc = "Move to pane left" }
)
vim.keymap.set(
	{ "n", "v", "i" },
	"<M-n>",
	"<cmd>TmuxNavigateDown<cr>",
	{ noremap = true, silent = true, desc = "Move to pane down" }
)
vim.keymap.set(
	{ "n", "v", "i" },
	"<M-e>",
	"<cmd>TmuxNavigateUp<cr>",
	{ noremap = true, silent = true, desc = "Move to pane up" }
)
vim.keymap.set(
	{ "n", "v", "i" },
	"<M-i>",
	"<cmd>TmuxNavigateRight<cr>",
	{ noremap = true, silent = true, desc = "Move to pane right" }
)

-- Explorer
vim.keymap.set({ "n", "v", "x", "o" }, "<leader>e", "<cmd>Oil<cr>", { desc = "[E]xplorer: Toggle file explorer" })

-- Save file
vim.keymap.set({ "n", "v", "x", "o", "i", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Commenting
-- Normal mode mappings
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

-- Helper functions for copy keymaps
local function get_relative_file()
	local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
	local current_file = vim.fn.expand("%:p")
	local relative_path

	if vim.v.shell_error == 0 and git_root ~= "" then
		relative_path = vim.fn.fnamemodify(current_file, ":s?" .. git_root .. "/??")
	else
		relative_path = vim.fn.expand("%")
	end

	return relative_path
end
local function get_file_line()
	local relative_path = get_relative_file()

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

-- Copy current file to clipboard
vim.keymap.set("n", "<leader>cyf", function()
	local file = get_relative_file()
	vim.fn.setreg("+", file)
	print("Copied: " .. file)
end, { desc = "Copy file path" })

-- Copy current line number to clipboard
vim.keymap.set("n", "<leader>cyl", function()
	local file_line = get_file_line()
	vim.fn.setreg("+", file_line)
	print("Copied: " .. file_line)
end, { desc = "Copy line number" })

-- Copy current line number and diagnostic message to clipboard
vim.keymap.set("n", "<leader>cyD", function()
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

-- Flash keymaps
vim.keymap.set({ "n", "x", "o" }, "s", function()
	require("flash").jump()
end, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "S", function()
	require("flash").treesitter()
end, { desc = "Flash Treesitter" })

-- Snacks plugin keymaps
-- Top Pickers & Explorer
vim.keymap.set("n", "<leader><space>", function()
	Snacks.picker.smart({ filter = { cwd = true } })
	-- Snacks.picker.smart()
end, { desc = "Smart Find Files" })
vim.keymap.set("n", "<leader>fw", function()
	Snacks.picker.grep({ hidden = true })
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>fb", function()
	Snacks.picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>ff", function()
	Snacks.picker.files({ hidden = true })
end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", function()
	Snacks.picker.git_files()
end, { desc = "Find Git Files" })
-- vim.keymap.set('n', '<leader>fp', function()
--   Snacks.picker.projects()
-- end, { desc = 'Projects' })
vim.keymap.set("n", "<leader>fr", function()
	Snacks.picker.recent({ filter = { cwd = true } })
end, { desc = "Recent" })

-- git
vim.keymap.set("n", "<leader>gl", function()
	Snacks.picker.git_log()
end, { desc = "Git Log" })
vim.keymap.set("n", "<leader>gL", function()
	Snacks.picker.git_log_line()
end, { desc = "Git Log Line" })
vim.keymap.set("n", "<leader>gs", function()
	Snacks.picker.git_status()
end, { desc = "Git Status" })
vim.keymap.set("n", "<leader>gS", function()
	Snacks.picker.git_stash()
end, { desc = "Git Stash" })
vim.keymap.set("n", "<leader>gf", function()
	Snacks.picker.git_log_file()
end, { desc = "Git Log File" })
vim.keymap.set("n", "<leader>gb", function()
	Snacks.git.blame_line()
end, { desc = "Git Blame Line" })

vim.keymap.set("n", "<leader>gy", function()
	local git_root = Snacks.git.get_root()
	if not git_root then
		vim.notify("Not in a git repository", vim.log.levels.ERROR)
		return
	end

	local current_file = vim.fn.expand("%:p")
	local relative_path = vim.fn.fnamemodify(current_file, ":~:.")

	-- Copy to default register
	vim.fn.setreg('"', relative_path)
	vim.notify("Copied: " .. relative_path, vim.log.levels.INFO)
end, { desc = "Git copy file path" })

vim.keymap.set("n", "<leader>gol", function()
	Snacks.gitbrowse.open()
end, { desc = "Git open [l]ine" })
vim.keymap.set("n", "<leader>gof", function()
	Snacks.gitbrowse.open({ what = "file", line_start = nil, line_end = nil })
end, { desc = "Git open [f]ile" })

-- Grep
vim.keymap.set("n", "<leader>sb", function()
	Snacks.picker.lines()
end, { desc = "Buffer Lines" })
vim.keymap.set("n", "<leader>sB", function()
	Snacks.picker.grep_buffers()
end, { desc = "Grep Open Buffers" })
vim.keymap.set("n", "<leader>sg", function()
	Snacks.picker.grep()
end, { desc = "Grep" })
vim.keymap.set({ "n", "x" }, "<leader>sw", function()
	Snacks.picker.grep_word()
end, { desc = "Visual selection or word" })

-- search
vim.keymap.set("n", '<leader>s"', function()
	Snacks.picker.registers()
end, { desc = "Registers" })
vim.keymap.set("n", "<leader>s/", function()
	Snacks.picker.search_history()
end, { desc = "Search History" })
vim.keymap.set("n", "<leader>sa", function()
	Snacks.picker.autocmds()
end, { desc = "Autocmds" })
vim.keymap.set("n", "<leader>sc", function()
	Snacks.picker.command_history()
end, { desc = "Command History" })
vim.keymap.set("n", "<leader>sC", function()
	Snacks.picker.commands()
end, { desc = "Commands" })
vim.keymap.set("n", "<leader>sD", function()
	Snacks.picker.diagnostics()
end, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>sd", function()
	Snacks.picker.diagnostics_buffer()
end, { desc = "Buffer Diagnostics" })
vim.keymap.set("n", "<leader>sh", function()
	Snacks.picker.help()
end, { desc = "Help Pages" })
vim.keymap.set("n", "<leader>sH", function()
	Snacks.picker.highlights()
end, { desc = "Highlights" })
vim.keymap.set("n", "<leader>si", function()
	Snacks.picker.icons()
end, { desc = "Icons" })
vim.keymap.set("n", "<leader>sj", function()
	Snacks.picker.jumps({ filter = { cwd = true } })
end, { desc = "Jumps" })
vim.keymap.set("n", "<leader>sk", function()
	Snacks.picker.keymaps()
end, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>sl", function()
	Snacks.picker.loclist()
end, { desc = "Location List" })
vim.keymap.set("n", "<leader>sm", function()
	Snacks.picker.marks()
end, { desc = "Marks" })
vim.keymap.set("n", "<leader>sM", function()
	Snacks.picker.man()
end, { desc = "Man Pages" })
vim.keymap.set("n", "<leader>sp", function()
	Snacks.picker.lazy()
end, { desc = "Search for Plugin Spec" })
vim.keymap.set("n", "<leader>sq", function()
	Snacks.picker.qflist()
end, { desc = "Quickfix List" })
vim.keymap.set("n", "<leader>sR", function()
	Snacks.picker.resume()
end, { desc = "Resume" })
vim.keymap.set("n", "<leader>su", function()
	Snacks.picker.undo()
end, { desc = "Undo History" })
vim.keymap.set("n", "<leader>uC", function()
	Snacks.picker.colorschemes()
end, { desc = "Colorschemes" })

-- LSP
vim.keymap.set("n", "gd", function()
	Snacks.picker.lsp_definitions()
end, { desc = "Goto Definition" })
vim.keymap.set("n", "gD", function()
	Snacks.picker.lsp_declarations()
end, { desc = "Goto Declaration" })
vim.keymap.set("n", "gr", function()
	Snacks.picker.lsp_references()
end, { nowait = true, desc = "References" })
vim.keymap.set("n", "gI", function()
	Snacks.picker.lsp_implementations()
end, { desc = "Goto Implementation" })
vim.keymap.set("n", "gt", function()
	Snacks.picker.lsp_type_definitions()
end, { desc = "Goto [T]ype Definition" })
vim.keymap.set("n", "<leader>ss", function()
	Snacks.picker.lsp_symbols()
end, { desc = "LSP Symbols" })
vim.keymap.set("n", "<leader>sS", function()
	Snacks.picker.lsp_workspace_symbols()
end, { desc = "LSP Workspace Symbols" })

-- Other
vim.keymap.set("n", "<leader>z", function()
	Snacks.zen()
end, { desc = "Toggle Zen Mode" })
vim.keymap.set("n", "<leader>Z", function()
	Snacks.zen.zoom()
end, { desc = "Toggle Zoom" })
vim.keymap.set("n", "<leader>.", function()
	Snacks.scratch()
end, { desc = "Toggle Scratch Buffer" })
vim.keymap.set("n", "<leader>S", function()
	Snacks.scratch.select()
end, { desc = "Select Scratch Buffer" })
vim.keymap.set("n", "<leader>n", function()
	Snacks.notifier.show_history()
end, { desc = "Notification History" })
vim.keymap.set("n", "<leader>bd", function()
	Snacks.bufdelete()
end, { desc = "Delete Buffer" })
vim.keymap.set("n", "<leader>cR", function()
	Snacks.rename.rename_file()
end, { desc = "Rename File" })
vim.keymap.set({ "n", "v" }, "<leader>gol", function()
	Snacks.gitbrowse()
end, { desc = "Git Browse" })
vim.keymap.set("n", "<leader>un", function()
	Snacks.notifier.hide()
end, { desc = "Dismiss All Notifications" })
-- vim.keymap.set('n', '<c-/>', function()
--   Snacks.terminal()
-- end, { desc = 'Toggle Terminal' })
vim.keymap.set("n", "<c-_>", function()
	Snacks.terminal()
end, { desc = "which_key_ignore" })
vim.keymap.set({ "n", "t" }, "]]", function()
	Snacks.words.jump(vim.v.count1)
end, { desc = "Next Reference" })
vim.keymap.set({ "n", "t" }, "[[", function()
	Snacks.words.jump(-vim.v.count1)
end, { desc = "Prev Reference" })

vim.keymap.set("n", "<leader>N", function()
	Snacks.win({
		file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
		width = 0.6,
		height = 0.6,
		wo = {
			spell = false,
			wrap = false,
			signcolumn = "yes",
			statuscolumn = " ",
			conceallevel = 3,
		},
	})
end, { desc = "Neovim News" })

-- Trouble keymaps
vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
vim.keymap.set(
	"n",
	"<leader>xX",
	"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
	{ desc = "Buffer Diagnostics (Trouble)" }
)
vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
vim.keymap.set(
	"n",
	"<leader>cl",
	"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
	{ desc = "LSP Definitions / references / ... (Trouble)" }
)
vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })

-- GitSigns keymaps
vim.keymap.set("n", "]h", function()
	require("gitsigns").next_hunk()
end, { desc = "Next hunk" })
vim.keymap.set("n", "[h", function()
	require("gitsigns").prev_hunk()
end, { desc = "Previous hunk" })
vim.keymap.set("n", "<leader>ghs", function()
	require("gitsigns").stage_hunk()
end, { desc = "Stage hunk" })
vim.keymap.set("n", "<leader>ghr", function()
	require("gitsigns").reset_hunk()
end, { desc = "Reset hunk" })
vim.keymap.set("v", "<leader>ghs", function()
	require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
end, { desc = "Stage hunk" })
vim.keymap.set("v", "<leader>ghr", function()
	require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
end, { desc = "Reset hunk" })
vim.keymap.set("n", "<leader>ghR", function()
	require("gitsigns").reset_buffer()
end, { desc = "Reset buffer" })
vim.keymap.set("n", "<leader>ghp", function()
	require("gitsigns").preview_hunk_inline()
end, { desc = "Preview hunk inline" })
vim.keymap.set("n", "<leader>ghP", function()
	require("gitsigns").preview_hunk()
end, { desc = "Preview hunk" })
-- vim.keymap.set('n', '<leader>gb', function()
--   require('gitsigns').blame_line { full = true }
-- end, { desc = 'Blame line' })
vim.keymap.set("n", "<leader>gB", function()
	require("gitsigns").blame()
end, { desc = "Blame file" })
vim.keymap.set("n", "<leader>ghd", function()
	require("gitsigns").diffthis()
end, { desc = "Diff this" })
vim.keymap.set("n", "<leader>ghD", function()
	require("gitsigns").diffthis("~")
end, { desc = "Diff this ~" })
vim.keymap.set("n", "<leader>ghQ", function()
	require("gitsigns").setqflist("all")
end, { desc = "Setqflist all" })
vim.keymap.set("n", "<leader>ghq", function()
	require("gitsigns").setqflist()
end, { desc = "Setqflist" })

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

-- lsp docs scroll when pop up
vim.keymap.set({ "n", "i", "s" }, "<c-f>", function()
	if not require("noice.lsp").scroll(4) then
		return "<c-f>"
	end
end, { silent = true, expr = true })

vim.keymap.set({ "n", "i", "s" }, "<c-b>", function()
	if not require("noice.lsp").scroll(-4) then
		return "<c-b>"
	end
end, { silent = true, expr = true })

-- Octo (pull request plugin)
vim.keymap.set({ "n" }, "<leader>gpl", function()
	print("Listing PRs...")
	vim.cmd("Octo pr list")
end, { desc = "[l]ist PRs" })
vim.keymap.set({ "n" }, "<leader>gpr", function()
	print("Reviewing PR...")
	vim.cmd("Octo review")
end, { desc = "[r]eview start/resume" })
