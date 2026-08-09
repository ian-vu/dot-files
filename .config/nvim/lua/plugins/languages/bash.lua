return {
	{
		"neovim/nvim-lspconfig", -- https://github.com/neovim/nvim-lspconfig
		opts = {
			servers = {
				bashls = {
					root_dir = function(bufname)
						if vim.g.disable_bashls then
							return nil
						end
						return vim.fs.root(bufname, ".git")
					end,
					settings = {
						bashIde = {
							-- Avoid expensive workspace scans and ShellCheck external-source traversal;
							-- use separate lint/format tooling for shell diagnostics if needed.
							backgroundAnalysisMaxFiles = 0,
							shellcheckPath = "",
							includeAllWorkspaceSymbols = false,
						},
					},
				},
			},
		},
	},
}
