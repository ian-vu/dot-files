return {
	{
		"stevearc/conform.nvim", -- https://github.com/stevearc/conform.nvim
		optional = true,
		opts = {
			formatters = {
				["markdown-toc"] = {
					condition = function(_, ctx)
						for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
							if line:find("<!%-%- toc %-%->") then
								return true
							end
						end
					end,
				},
				["markdownlint-cli2"] = {
					condition = function(_, ctx)
						local diag = vim.tbl_filter(function(d)
							return d.source == "markdownlint"
						end, vim.diagnostic.get(ctx.buf))
						return #diag > 0
					end,
				},
			},
			formatters_by_ft = {
				["markdown"] = { "prettierd", "markdownlint-cli2", "markdown-toc" },
				["markdown.mdx"] = { "prettierd", "markdownlint-cli2", "markdown-toc" },
			},
		},
	},
	-- install with yarn or npm
	{
		"iamcco/markdown-preview.nvim", -- https://github.com/iamcco/markdown-preview.nvim
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && yarn install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},
	{
		"MeanderingProgrammer/render-markdown.nvim", -- https://github.com/MeanderingProgrammer/render-markdown.nvim
		opts = {
			heading = {
				sign = false,
				icons = {},
			},
			checkbox = {
				-- Obsidian's legacy UI is disabled in plugins/obsidian.lua, so
				-- render-markdown owns task-list checkbox concealment.
				enabled = true,
			},
		},
		ft = { "markdown", "norg", "rmd", "org" },
		config = function(_, opts)
			require("render-markdown").setup(opts)
			Snacks.toggle({
				name = "Render Markdown",
				get = function()
					return require("render-markdown.state").enabled
				end,
				set = function(enabled)
					local m = require("render-markdown")
					if enabled then
						m.enable()
					else
						m.disable()
					end
				end,
			}):map("<leader>um")
		end,
	},
	{
		"neovim/nvim-lspconfig", -- https://github.com/neovim/nvim-lspconfig
		opts = {
			servers = {
				marksman = {},
			},
		},
		init = function()
			-- Marksman caches its file index at startup and doesn't detect new/moved/deleted
			-- files until restarted. This restarts it automatically when oil modifies files.
			vim.api.nvim_create_autocmd("User", {
				pattern = { "OilCreate", "OilDelete", "OilMove" },
				callback = function()
					local clients = vim.lsp.get_clients({ name = "marksman" })
					for _, client in ipairs(clients) do
						client:stop()
						vim.defer_fn(function()
							vim.cmd("LspStart marksman")
						end, 100)
					end
				end,
			})
		end,
	},
}
