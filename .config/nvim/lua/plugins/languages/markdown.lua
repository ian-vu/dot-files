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
		opts = function()
			local obsidian_util = require("utils.obsidian")
			return {
				heading = {
					sign = false,
					icons = {},
				},
				on = {
					-- Fix and configure conflicts with obsidian.nvim's UI layer:
					-- inside vault buffers both plugins render the same elements, so
					-- overlays stack and corrupt the display. Apply per-buffer tweaks
					-- here to keep the two renderers compatible.
					-- See: https://github.com/epwalsh/obsidian.nvim/issues/849
					attach = function(ctx)
						if obsidian_util.in_vault(ctx.buf) then
							local ok, state = pcall(require, "render-markdown.state")
							if ok and state.cache[ctx.buf] then
								-- Let obsidian own checkboxes; dual overlays eat the
								-- first ~3 chars of content after `] `.
								state.cache[ctx.buf].checkbox.enabled = false
								-- Add a space after the bullet icon so obsidian's
								-- bullet doesn't collide with the following text.
								state.cache[ctx.buf].bullet.right_pad = 1
							end
						end
					end,
				},
			}
		end,
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
