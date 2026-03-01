return {
	{
		"neovim/nvim-lspconfig", -- https://github.com/neovim/nvim-lspconfig
		opts = {
			servers = {
				lua_ls = {
					-- cmd = { ... },
					-- filetypes = { ... },
					-- capabilities = {},
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
							-- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
							-- diagnostics = { disable = { 'missing-fields' } },
						},
					},
				},
			},
		},
	},
	{ -- Autoformat
		"stevearc/conform.nvim", -- https://github.com/stevearc/conform.nvim
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
			},
		},
	},
}
