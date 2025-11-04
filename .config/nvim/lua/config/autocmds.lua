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

-- Set folding options after buffer is loaded
-- This ensures fold settings aren't overridden by plugins
vim.api.nvim_create_autocmd({ "BufRead", "BufWinEnter", "BufNewFile" }, {
	desc = "Set fold options for TreeSitter folding",
	group = vim.api.nvim_create_augroup("treesitter-folding", { clear = true }),
	callback = function()
		vim.opt_local.foldmethod = "expr"
	end,
})
