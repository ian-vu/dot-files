return {
	{
		"neovim/nvim-lspconfig", -- https://github.com/neovim/nvim-lspconfig
		opts = {
			-- make sure mason installs the server
			servers = {
				-- `tsgo` is Microsoft's native Go port of tsserver/tsc
				-- (microsoft/typescript-go, published as @typescript/native-preview).
				-- It replaces the previous `vtsls` setup: tsgo is a single native binary
				-- so there is no Node/tsserver child process to manage (the old
				-- `tsserver.nodePath` mise-shim workaround is no longer needed), and it
				-- supports monorepos out of the box. See lsp/tsgo.lua for defaults
				-- (cmd, filetypes, deno-aware root detection, inlay hints).
				tsgo = {
					-- explicitly add default filetypes, so that we can extend
					-- them in related extras
					filetypes = {
						"javascript",
						"javascriptreact",
						"javascript.jsx",
						"typescript",
						"typescriptreact",
						"typescript.tsx",
					},
					settings = {
						typescript = {
							inlayHints = {
								enumMemberValues = { enabled = true },
								functionLikeReturnTypes = { enabled = true },
								parameterNames = { enabled = "literals" },
								parameterTypes = { enabled = true },
								propertyDeclarationTypes = { enabled = true },
								-- Keep variable types off to avoid noisy hints on every
								-- variable declaration; matches the previous vtsls setup.
								variableTypes = { enabled = false },
							},
						},
					},
				},
			},
		},
	},
}
