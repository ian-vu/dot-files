-- Auto-show LSP references and quickly navigate between them
return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			words = { enabled = false },
		},
	},
}
