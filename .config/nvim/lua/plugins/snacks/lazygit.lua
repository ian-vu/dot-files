-- Open lazygit inside Neovim so repository operations do not require switching terminals.
return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			lazygit = {
				enabled = true,
			},
		},
	},
}
