return {
	{
		"folke/snacks.nvim",
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
				ignore = {
					"*.log",
					"*.tmp",
					"node_modules/",
					".DS_Store",
				},
				matcher = {
					history_bonus = true,
					cwd_bonus = true,
				},
				layout = {
					height = 0.9,
				},
				formatters = {
					file = {
						filename_first = true,
						git_status_hl = false, -- highlights files with git status
						truncate = 200, -- truncate the file path to (roughly) this length
					},
				},
				win = {
					input = {
						keys = {
							["<Esc>"] = { "close", mode = { "n", "i" } }, -- esc to close without going to normal mode first
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
						:map("<leader>ub")
					Snacks.toggle.inlay_hints():map("<leader>uh")
					-- Snacks.toggle.indent():map '<leader>ug' -- indent toggle not available
					Snacks.toggle.dim():map("<leader>uD")
				end,
			})
		end,
	},
}
