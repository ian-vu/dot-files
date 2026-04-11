-- LSP rename integration (used by Oil for rename-aware file moves)
return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			rename = { enabled = true },
		},
	},
}
