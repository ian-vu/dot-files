-- Git blame integration
return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			git = { enabled = true },
		},
	},
}
