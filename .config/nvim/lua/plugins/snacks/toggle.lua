-- Toggle keymaps integrated with which-key icons / colors
-- NOTE: Doesn't seem to work currently

vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	callback = function()
		Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
		Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
		Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
		Snacks.toggle.diagnostics():map("<leader>ud")
		Snacks.toggle.line_number():map("<leader>ul")
		Snacks.toggle
			.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
			:map("<leader>uc")
		Snacks.toggle.treesitter():map("<leader>uT")
		Snacks.toggle
			.option("background", { off = "light", on = "dark", name = "Dark Background" })
			:map("<leader>uB")
		Snacks.toggle.inlay_hints():map("<leader>uh")
		-- Snacks.toggle.indent():map '<leader>ug' -- indent toggle not available
		Snacks.toggle.dim():map("<leader>uD")
		-- Supermaven runs as a background process; toggle stops/starts it via the plugin API
		-- so suggestions can be disabled without unloading the plugin.
		Snacks.toggle({
			name = "Supermaven",
			get = function()
				local ok, api = pcall(require, "supermaven-nvim.api")
				return ok and api.is_running()
			end,
			set = function(state)
				local ok, api = pcall(require, "supermaven-nvim.api")
				if not ok then
					return
				end
				if state then
					api.start()
				else
					api.stop()
				end
			end,
		}):map("<leader>ua")
	end,
})

return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			toggle = { enabled = true },
		},
	},
}
