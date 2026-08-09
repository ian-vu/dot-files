-- Bruno (https://usebruno.com) stores API requests as `.bru` files in its own
-- "Bru Markup Language". There is no Tree-sitter grammar for it, so we register a
-- custom `bru` filetype backed by a hand-written syntax file (after/syntax/bru.vim).
vim.filetype.add({ extension = { bru = "bru" } })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Handle tmux pane resizing. When tmux resizes force a nvim resize
vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		vim.cmd("wincmd =")
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "qf",
	callback = function()
		vim.keymap.set("n", "<CR>", "<C-w><CR>", { buffer = true })
	end,
})

-- Check for external file changes on these events
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	pattern = "*",
	command = "checktime",
})

-- Markdown links use percent-encoding for spaces (%20) and other special chars.
-- Neovim's gf doesn't decode these, so it looks for a literal "%20" file.
-- Also, & is not in isfname so gf truncates filenames at that character.
local function percent_decode(fname)
	return (fname:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end))
end
_G._percent_decode = percent_decode

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt_local.isfname:append("&")
		vim.bo.includeexpr = "v:lua._percent_decode(v:fname)"
	end,
})

-- Prevent auto-inserting comment leaders when opening a new line with o/O in normal mode.
-- By default, Neovim's built-in filetype plugins (ftplugins) add the 'o' flag to
-- formatoptions for most languages. This causes o/O to auto-continue comments, which
-- is unwanted — comment continuation should only happen when pressing Enter in insert
-- mode (controlled by the 'r' flag, which we keep).
-- This must be an autocmd because ftplugins run after options.lua and would re-add 'o'.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove("o")
	end,
})
