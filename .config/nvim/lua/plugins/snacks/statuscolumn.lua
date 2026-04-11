-- Status column symbols next to line numbers (marks, folds)
return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			statuscolumn = { enabled = true },
		},
	},
}
