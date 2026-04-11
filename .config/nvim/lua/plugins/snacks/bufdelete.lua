-- Better buffer deletion
return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			bufdelete = { enabled = true },
		},
	},
}
