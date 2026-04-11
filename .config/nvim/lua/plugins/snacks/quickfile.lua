-- Renders the file as quickly as possible before loading plugins (e.g. nvim somefile.txt)
return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			quickfile = { enabled = true },
		},
	},
}
