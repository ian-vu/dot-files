-- Scope detection based on treesitter or indent
return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			scope = { enabled = false },
		},
	},
}
