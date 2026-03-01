return {
	{ -- statusline
		"nvim-lualine/lualine.nvim", -- https://github.com/nvim-lualine/lualine.nvim
		event = "VeryLazy",
		init = function()
			-- vim.g.lualine_laststatus = vim.o.laststatus
			-- if vim.fn.argc(-1) > 0 then
			--   -- set an empty statusline till lualine loads
			--   vim.o.statusline = ' '
			-- else
			--   -- hide the statusline on the starter page
			--   vim.o.laststatus = 0
			-- end
		end,
		opts = function()
			-- PERF: we don't need this lualine require madness 🤷
			local lualine_require = require("lualine_require")
			lualine_require.require = require

			local colors = {
				-- [''] = Util.ui.fg 'Special',
				-- ['Normal'] = Util.ui.fg 'Special',
				-- ['Warning'] = Util.ui.fg 'DiagnosticError',
				-- ['InProgress'] = Util.ui.fg 'DiagnosticWarn',
			}

			-- local icons = require('lazyvim.config').icons

			local icons = require("config.icons")

			return {
				options = {
					theme = "auto",
					-- globalstatus = true,
					disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
				},
				sections = {
					lualine_a = {
						-- { "mode" },
						{ "mode", icon = "" },
						-- { "mode", icon = "" },
					},
					lualine_b = {
						-- { "branch", icon = "󰘬" },
					},

					lualine_c = {
						{
							"diff",
							symbols = {
								added = icons.git.added,
								modified = icons.git.modified,
								removed = icons.git.removed,
							},
							source = function()
								-- Sum gitsigns diff counts across all loaded buffers
								local added, modified, removed = 0, 0, 0
								for _, buf in ipairs(vim.api.nvim_list_bufs()) do
									if vim.api.nvim_buf_is_loaded(buf) then
										local signs = vim.b[buf].gitsigns_status_dict
										if signs then
											added = added + (signs.added or 0)
											modified = modified + (signs.changed or 0)
											removed = removed + (signs.removed or 0)
										end
									end
								end
								return { added = added, modified = modified, removed = removed }
							end,
						},
						-- Util.lualine.root_dir(),
						-- { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
						-- { Util.lualine.pretty_path() },
						{
							"filename",
							-- file_status = true,
							path = 1,
						},

						-- {
						--   -- Show when unsaved modified buffer
						--   function()
						--     for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						--       if vim.api.nvim_buf_get_option(buf, "modified") then
						--         return "[+] Unsaved changes [+]"
						--       end
						--     end
						--     return ""
						--   end,
						--   color = Util.ui.fg("green"),
						--   separator = "",
						--   -- padding = { right = 20 },
						-- },
					},
					lualine_x = {
						-- Show recording mode
						{
							function()
								local reg = vim.fn.reg_recording()
								if reg == "" then
									return ""
								else
									return "󰻂 Recording @" .. reg
								end
							end,
							color = { fg = "#ff9e64" },
						},
            -- Show the current command pressed
            -- {
            --   function()
            --     return require("noice").api.status.command.get()
            --   end,
            --   cond = function()
            --     return package.loaded["noice"] and require("noice").api.status.command.has()
            --   end,
            --   color = Util.ui.fg("Statement"),
            -- },
            -- stylua: ignore
            -- {
            --   function()
            --     return require("noice").api.status.mode.get()
            --   end,
            --   cond = function()
            --     return package.loaded["noice"] and require("noice").api.status.mode.has()
            --   end,
            --   -- color = Util.ui.fg("Constant"),
            -- },
            -- stylua: ignore
            {
              function() return "  " .. require("dap").status() end,
              cond = function () return package.loaded["dap"] and require("dap").status() ~= "" end,
              -- color = Util.ui.fg("Debug"),
            },
						-- {
						--   require('lazy.status').updates,
						--   cond = require('lazy.status').has_updates,
						--   -- color = Util.ui.fg 'Special',
						-- },
						{
							"diagnostics",
							symbols = {
								error = icons.diagnostics.Error,
								warn = icons.diagnostics.Warn,
								info = icons.diagnostics.Info,
								hint = icons.diagnostics.Hint,
							},
						},
						-- { -- Copilot status
						--   function()
						--     local icon = require('lazyvim.config').icons.kinds.Copilot
						--     local status = require('copilot.api').status.data
						--     return icon .. (status.message or '')
						--   end,
						--   cond = function()
						--     if not package.loaded['copilot'] then
						--       return
						--     end
						--     local ok, clients = pcall(require('lazyvim.util').lsp.get_clients, { name = 'copilot', bufnr = 0 })
						--     if not ok then
						--       return false
						--     end
						--     return ok and #clients > 0
						--   end,
						--   color = function()
						--     if not package.loaded['copilot'] then
						--       return
						--     end
						--     local status = require('copilot.api').status.data
						--     return colors[status.status] or colors['']
						--   end,
						-- },
					},
					lualine_y = {
						"filetype",
						{ "progress", padding = { left = 1, right = 1 } },
					},
					lualine_z = {
						-- { "progress", separator = " ", padding = { left = 1, right = 0 } },
						-- { "location", icon = { "", align = "right" }, padding = { left = 1, right = 1 } },
						{ "location", icon = { "", align = "right" }, padding = { left = 1, right = 1 } },
						-- { "location", padding = { left = 1, right = 1 } },
					},
				},
				extensions = { "neo-tree", "lazy" },
			}
		end,
	},
}
