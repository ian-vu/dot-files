-- Snacks picker configuration (telescope alternative)
return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			picker = {
				actions = require("trouble.sources.snacks").actions,
				enabled = true,
				hidden = true,
				exclude = {
					"*.log",
					"*.tmp",
					".DS_Store",
					".worktrees/",
					-- Generated / dependency dirs: large, never want to fuzzy-find into them
					"node_modules/",
					-- Python
					".venv/",
					"venv/",
					"__pycache__/",
					".pytest_cache/",
					".mypy_cache/",
					".ruff_cache/",
					"*.pyc",
					-- JS/TS
					"dist/",
					"build/",
					".next/",
					".nuxt/",
					".turbo/",
					"*.min.js",
					"*.min.css",
					-- Rust
					"target/",
					-- Ruby
					"vendor/bundle/",
					".bundle/",
					-- Generic
					"coverage/",
					".cache/",
				},
				matcher = {
					history_bonus = true,
					cwd_bonus = true,
					frecency = true,
				},
				layout = {
					cycle = false,
					-- Use custom layout when wide enough, otherwise default vertical
					preset = function()
						return vim.o.columns >= 150 and "ivy" or "vertical"
					end,
				},
				layouts = {
					default = {
						layout = {
							width = 0.98,
							height = 0.85,
						},
					},
					ivy = {
						-- hidden = { "preview" }, -- default don't show preview
						layout = {
							box = "vertical",
							backdrop = true, -- true blur background
							row = -1,
							width = 0,
							height = 0.85,
							min_height = 25,
							border = "top",
							title = " {title} {live} {flags}",
							title_pos = "left",
							{ win = "input", height = 1, border = "none" },
							{
								box = "horizontal",
								border = "top",
								{ win = "list", border = "none" },
								{ win = "preview", title = "{preview}", width = 0.55, border = true },
							},
						},
					},
					vertical = {
						-- hidden = { "preview" }, -- default don't show preview
						layout = {
							box = "vertical",
							backdrop = true, -- true blur background
							row = -1,
							width = 0,
							height = 0.85,
							min_height = 25,
							border = "top",
							title = " {title} {live} {flags}",
							title_pos = "left",
							{ win = "input", height = 1, border = "none" },
							{ win = "list", border = "top" },
							{ win = "preview", title = "{preview}", border = true },
						},
					},
				},
				sources = {
					smart = {
						filter = {
							cwd = true,
							filter = function(item)
								return not item.file or not item.file:find("/.worktrees/", 1, true)
							end,
						},
						-- pre-fill input with !test to exclude test files (user still can delete during search)
						pattern = "!'test ",
					},
					-- pre-fill input with !test to exclude test files (user still can delete during search)
					files = {
						pattern = "!'test ",
					},
					grep = {
						pattern = "!'test ",
					},
					grep_word = {
						pattern = "!'test ",
					},
					lsp_references = {
						pattern = "!'test ",
					},
				},
				formatters = {
					file = {
						filename_first = false,
						git_status_hl = false, -- highlights files with git status
						truncate = 150,
					},
				},
				win = {
					input = {
						keys = {
							["<Esc>"] = { "close", mode = { "n", "i" } }, -- esc to close without going to normal mode first
							["n"] = { "list_down", mode = { "n" } },
							["e"] = { "list_up", mode = { "n" } }, -- remap preview toggle from <a-p> to <c-p>
							["<c-p>"] = { "toggle_preview", mode = { "i", "n" } }, -- remap preview toggle from <a-p> to <c-p>
							["<c-t>"] = {
								"trouble_open",
								mode = { "n", "i" },
							},
						},
					},
				},
			},
		},
	},
}
