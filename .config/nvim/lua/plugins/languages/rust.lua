return {
	{
		"neovim/nvim-lspconfig", -- https://github.com/neovim/nvim-lspconfig
		opts = {
			servers = {
				rust_analyzer = {
					settings = {
						["rust-analyzer"] = {
							checkOnSave = true,
							check = {
								command = "clippy", -- use clippy for stricter lints
							},
							cargo = {
								allFeatures = true,
							},
							procMacro = {
								enable = true,
							},
						},
					},
				},
			},
		},
	},
}
