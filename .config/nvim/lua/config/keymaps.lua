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
vim.keymap.set("n", "<C-w><C-s>", function()
	vim.cmd("split")
	vim.lsp.buf.definition()
end, { desc = "Horizontal split and go to definition" })
vim.keymap.set("n", "<C-w><C-v>", function()
	vim.cmd("vsplit")
	vim.lsp.buf.definition()
end, { desc = "Vertical split and go to definition" })

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

-- Toggle autoformat on save
vim.keymap.set("n", "<leader>uf", function()
	vim.g.autoformat_enabled = not vim.g.autoformat_enabled
	if vim.g.autoformat_enabled then
		vim.notify("Autoformat on save: enabled", vim.log.levels.INFO)
	else
		vim.notify("Autoformat on save: disabled", vim.log.levels.INFO)
	end
end, { desc = "Toggle autoformat on save" })

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
vim.keymap.set("n", "<leader>t2", ":tabn 2<cr>", { desc = "Switch to tab 2" })
vim.keymap.set("n", "<leader>t3", ":tabn 3<cr>", { desc = "Switch to tab 3" })
vim.keymap.set("n", "<leader>t4", ":tabn 4<cr>", { desc = "Switch to tab 4" })
vim.keymap.set("n", "<leader>t5", ":tabn 5<cr>", { desc = "Switch to tab 5" })

-- Buffers
vim.keymap.set("n", "<leader>br", "<cmd>bufdo e<cr>", { desc = "Reload all buffers" })
vim.keymap.set({ "n", "v", "x" }, "<leader>bb", "<cmd>e #<CR>", { desc = "Switch to previous buffer" })
-- vim.keymap.set({ "n", "v", "x" }, "<leader>.", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
-- vim.keymap.set({ "n", "v", "x" }, "<leader>,", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", { desc = "Delete all buffers except current" })
vim.keymap.set("n", "<leader>bc", "<cmd>BufferLinePickClose<cr>", { desc = "Close pick buffer" })
vim.keymap.set("n", "<leader>bs", "<cmd>BufferLinePick<cr>", { desc = "Select pick buffer" })
vim.keymap.set("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", { desc = "Pin buffer" })
vim.keymap.set("n", "<leader>bX", "<cmd>%bd<cr>", { desc = "Close all buffers" })

-- Buffer switching
vim.keymap.set({ "n", "v", "x" }, "<leader>1", "<cmd>BufferLineGoToBuffer 1<cr>", { desc = "Buffer 1" })
vim.keymap.set({ "n", "v", "x" }, "<leader>2", "<cmd>BufferLineGoToBuffer 2<cr>", { desc = "Buffer 2" })
vim.keymap.set({ "n", "v", "x" }, "<leader>3", "<cmd>BufferLineGoToBuffer 3<cr>", { desc = "Buffer 3" })
vim.keymap.set({ "n", "v", "x" }, "<leader>4", "<cmd>BufferLineGoToBuffer 4<cr>", { desc = "Buffer 4" })
vim.keymap.set({ "n", "v", "x" }, "<leader>5", "<cmd>BufferLineGoToBuffer 5<cr>", { desc = "Buffer 5" })
vim.keymap.set({ "n", "v", "x" }, "<leader>6", "<cmd>BufferLineGoToBuffer 6<cr>", { desc = "Buffer 6" })
vim.keymap.set({ "n", "v", "x" }, "<leader>7", "<cmd>BufferLineGoToBuffer 7<cr>", { desc = "Buffer 7" })
vim.keymap.set({ "n", "v", "x" }, "<leader>8", "<cmd>BufferLineGoToBuffer 8<cr>", { desc = "Buffer 8" })
vim.keymap.set({ "n", "v", "x" }, "<leader>9", "<cmd>BufferLineGoToBuffer 9<cr>", { desc = "Buffer 9" })

-- harpoon
vim.keymap.set({ "n", "v" }, "<leader>ha", function()
	require("harpoon"):list():add()
	print("Added to Harpoon")
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

-- Undotree
vim.keymap.set("n", "<leader>uu", "<cmd>UndotreeToggle<cr>", { desc = "[U]ndotree toggle " })

-- Spectre - search and replace
vim.keymap.set("n", "<leader>sr", "<cmd>Spectre<cr>", { desc = "[S]pectre search and replace" })

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

local function get_filepath_prefix()
	return "@"
end

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
	local file = get_filepath_prefix() .. get_relative_file()
	vim.fn.setreg("+", file)
	print("Copied: " .. file)
end, { desc = "Copy file path" })

-- Copy full file path to clipboard
vim.keymap.set("n", "<leader>cyF", function()
	local full_path = get_filepath_prefix() .. vim.fn.expand("%:p")
	vim.fn.setreg("+", full_path)
	print("Copied: " .. full_path)
end, { desc = "Copy full file path" })

-- Copy current line number to clipboard
vim.keymap.set("n", "<leader>cyl", function()
	local file_line = get_filepath_prefix() .. get_file_line()
	vim.fn.setreg("+", file_line)
	print("Copied: " .. file_line)
end, { desc = "Copy line number" })

-- Copy range of lines in visual mode with file path and line range
vim.keymap.set("v", "<leader>cyl", function()
	vim.cmd('normal! "vy')
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	local file_path = get_relative_file()
	local result = get_filepath_prefix() .. file_path .. ":" .. start_line .. "-" .. end_line
	vim.fn.setreg("+", result)
	print("Copied " .. result)
end, { desc = "Copy range of lines with path" })

-- Copy current line number and diagnostic message to clipboard
vim.keymap.set("n", "<leader>cyD", function()
	local file_line = get_filepath_prefix() .. get_file_line()
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
vim.keymap.set({ "n" }, "s", function()
	require("flash").jump()
end, { desc = "Flash" })
vim.keymap.set({ "n" }, "S", function()
	require("flash").treesitter()
end, { desc = "Flash Treesitter" })

-- Snacks plugin keymaps
-- Top Pickers & Explorer
vim.keymap.set("n", "<leader><space>", function()
	Snacks.picker.smart({ layout = { preview = false } })
	-- Snacks.picker.smart()
end, { desc = "Smart Find Files" })
vim.keymap.set("n", "<leader>fw", function()
	Snacks.picker.grep({ hidden = true })
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>fb", function()
	Snacks.picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>ff", function()
	Snacks.picker.files({ hidden = true, layout = { preview = false } })
end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", function()
	Snacks.picker.git_files()
end, { desc = "Find Git Files" })
-- vim.keymap.set('n', '<leader>fp', function()
--   Snacks.picker.projects()
-- end, { desc = 'Projects' })
vim.keymap.set("n", "<leader>fr", function()
	Snacks.picker.recent({ filter = { cwd = true }, preview = false })
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
	local relative_path = get_filepath_prefix() .. vim.fn.fnamemodify(current_file, ":~:.")

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

vim.keymap.set("n", "<leader>gol", function()
	require("gitportal").open_file_in_browser()
end, { desc = "Git open [l]ine" })

vim.keymap.set("v", "<leader>gol", function()
	require("gitportal").open_file_in_browser()
end, { desc = "Git open [l]ine" })

vim.keymap.set("n", "<leader>gof", function()
	require("gitportal").open_file_in_browser()
end, { desc = "Git open [f]ile" })

vim.keymap.set("n", "<leader>ub", function()
	require("gitsigns").blame()
end, { desc = "Toggle Git blame" })

-- Grep
vim.keymap.set("n", "<leader>sb", function()
	Snacks.picker.lines({ layout = { layout = { height = 0.3 } } })
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
vim.keymap.set("n", "<leader>bx", function()
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
-- vim.keymap.set({ "n", "t" }, "]]", function()
-- 	Snacks.words.jump(vim.v.count1)
-- end, { desc = "Next Reference" })
-- vim.keymap.set({ "n", "t" }, "[[", function()
-- 	Snacks.words.jump(-vim.v.count1)
-- end, { desc = "Prev Reference" })

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
vim.keymap.set({ "n" }, "<leader>gD", function()
	-- Find the merge base (where the branch branched from)
	local handle = io.popen("git merge-base origin/HEAD HEAD 2>/dev/null")
	if handle then
		local merge_base = handle:read("*a"):gsub("%s+", "")
		handle:close()
		if merge_base ~= "" then
			vim.cmd("DiffviewOpen " .. merge_base .. "..HEAD --imply-local")
		else
			vim.notify("Could not find merge base", vim.log.levels.ERROR)
		end
	end
end, { desc = "Diff view changes against branch point" })
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
vim.keymap.set({ "n" }, "<leader>gpb", function()
	print("Browing PR...")
	vim.cmd("Octo browse")
end, { desc = "[b]rowse PR without starting a review" })
vim.keymap.set({ "n" }, "<leader>gpx", function()
	print("Closing PR...")
	vim.cmd("Octo review close")
end, { desc = "close the review window and return to the PR" })
vim.keymap.set({ "n" }, "<leader>gps", function()
	print("Searching for open PRs...")
	-- Get repo info
	local repo = vim.fn.system("gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null"):gsub("\n", "")
	if vim.v.shell_error ~= 0 or repo == "" then
		vim.notify("Not in a git repository or gh not authenticated", vim.log.levels.ERROR)
		return
	end

	-- Fetch open PRs and extract unique authors
	local pr_list = vim.fn.system("gh pr list --state open --json author --jq '.[].author.login' 2>/dev/null")
	if vim.v.shell_error ~= 0 then
		vim.notify("Failed to fetch PRs", vim.log.levels.ERROR)
		return
	end

	-- Get unique authors
	local authors = { "All authors" }
	local seen = {}
	for author in pr_list:gmatch("[^\n]+") do
		if author ~= "" and not seen[author] then
			table.insert(authors, author)
			seen[author] = true
		end
	end

	if #authors == 1 then -- Only "All authors" exists
		vim.notify("No open PRs found", vim.log.levels.WARN)
		return
	end

	-- Use vim.ui.select to pick an author
	vim.ui.select(authors, {
		prompt = "Select author (or cancel for all):",
	}, function(selected)
		if not selected or selected == "All authors" then
			vim.notify(string.format("Searching for all open PRs in %s...", repo), vim.log.levels.INFO)
			vim.cmd(string.format("Octo search is:pr is:open repo:%s", repo))
		else
			vim.notify(string.format("Searching for open PRs by %s in %s...", selected, repo), vim.log.levels.INFO)
			vim.cmd(string.format("Octo search is:pr is:open author:%s repo:%s", selected, repo))
		end
	end)
end, { desc = "[s]earch open PRs by author" })

-- markdown preview
vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreview<cr>", { desc = "[m]arkdown [p]review" })
