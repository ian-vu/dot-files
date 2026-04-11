-- Global debugging helpers (lazy-loaded at VeryLazy)
vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	callback = function()
		_G.dd = function(...)
			Snacks.debug.inspect(...)
		end
		_G.bt = function()
			Snacks.debug.backtrace()
		end
		vim.print = _G.dd -- Override print to use snacks for `:=` command
	end,
})

return {}
