-- Optimized handling of large files
return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			bigfile = { enabled = true },
		},
	},
}
