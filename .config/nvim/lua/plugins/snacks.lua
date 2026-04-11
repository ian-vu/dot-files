return {
	{
		"folke/snacks.nvim", -- https://github.com/folke/snacks.nvim
		priority = 1,
		lazy = false,
		---@type snacks.Config
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
			bigfile = { enabled = true },
			bufdelete = { enabled = true },
			git = { enabled = true }, -- used for git blame
			gitbrowse = { enabled = true }, -- used to open file in github
			indent = { -- Pretty indent lines
				enabled = true,
				indent = {
					char = "┊",
				},
				animate = {
					enabled = false,
				},
				scope = {
					hl = "Comment",
				},
				chunk = { -- Code chunk. e.g Functions
					enabled = true,
					hl = "Comment",
					char = {
						corner_top = "╭",
						corner_bottom = "╰",

						horizontal = "─",
						vertical = "│",
						arrow = "",
					},
				},
			},
			input = { -- Pretty input (:cmd /search)
				enabled = true,
			},
			notifier = { -- Pretty vim.notify
				enabled = true,
				top_down = false,
			},
			picker = { -- telescope alternative
				actions = require("trouble.sources.snacks").actions,
				enabled = true,
				hidden = true,
				exclude = {
					"*.log",
					"*.tmp",
					"node_modules/",
					".DS_Store",
					".worktrees/",
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
					},
					-- exclude test files/dirs by default
					files = {
						exclude = { "*test*", "*tests*" },
					},
					smart = {
						exclude = { "*test*", "*tests*" },
					},
					grep = {
						glob = { "!*test*", "!*tests*" },
					},
					grep_word = {
						glob = { "!*test*", "!*tests*" },
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
			-- When doing nvim somefile.txt, it will render the file as quickly as possible, before loading your plugins.
			quickfile = {
				enabled = true,
			},
			rename = { -- allow for Oil to LSP rename
				enabled = true,
			},
			scope = { -- Scope detection based on treesitter or indent.
				enabled = false,
			},
			-- Quickly open scratch buffers for testing code, creating notes or just messing around.
			scratch = {
				enabled = true,
			},
			statuscolumn = { -- Symbols for status column next to line number. Showing marks folds
				enabled = true,
			},
			toggle = { -- Toggle keymaps integrated with which-key icons / colors
				-- NOTE: Doesn't seem to work currently
				enabled = true,
			},
			words = { -- Auto-show LSP references and quickly navigate between them
				enabled = false,
			},
		},
		init = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					-- Setup some globals for debugging (lazy-loaded)
					_G.dd = function(...)
						Snacks.debug.inspect(...)
					end
					_G.bt = function()
						Snacks.debug.backtrace()
					end
					vim.print = _G.dd -- Override print to use snacks for `:=` command

					-- Create some toggle mappings
					Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
					Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
					Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
					Snacks.toggle.diagnostics():map("<leader>ud")
					Snacks.toggle.line_number():map("<leader>ul")
					Snacks.toggle
						.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
						:map("<leader>uc")
					Snacks.toggle.treesitter():map("<leader>uT")
					Snacks.toggle
						.option("background", { off = "light", on = "dark", name = "Dark Background" })
						:map("<leader>uB")
					Snacks.toggle.inlay_hints():map("<leader>uh")
					-- Snacks.toggle.indent():map '<leader>ug' -- indent toggle not available
					Snacks.toggle.dim():map("<leader>uD")
				end,
			})
		end,
	},
}
