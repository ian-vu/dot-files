return {
	{ -- Detect tabstop and shiftwidth automatically
		"NMAC427/guess-indent.nvim", -- https://github.com/NMAC427/guess-indent.nvim
		enabled = true,
		event = "BufRead",
	},
	{ -- Easy commenting to be used with keymaps
		"numToStr/Comment.nvim", -- https://github.com/numToStr/Comment.nvim
		event = "BufRead",
	},
	{
		"windwp/nvim-autopairs", -- https://github.com/windwp/nvim-autopairs
		event = "InsertEnter",
		opts = {},
	},
	{
		"nvim-mini/mini.surround", -- https://github.com/nvim-mini/mini.surround
		enabled = false,
		event = "BufRead",
		version = false,
		opts = {},
	},
	{ -- undo history
		"mbbill/undotree", -- https://github.com/mbbill/undotree
		enabled = true,
		event = "BufRead",
		config = function()
			vim.g.undotree_WindowLayout = 3
			vim.g.undotree_SetFocusWhenToggle = 1
			vim.g.undotree_TreeNodeShape = ""
			vim.g.undotree_DiffpanelHeight = 20
			vim.g.undotree_SplitWidth = 40
		end,
	},
	{ -- newer undotree
		-- disabled since there currently isn't support to show saved nodes
		"XXiaoA/atone.nvim", -- https://github.com/XXiaoA/atone.nvim
		enabled = false,
		event = "BufRead",
		opts = {
			layout = {
				direction = "right",
			},
			keymaps = {
				tree = {
					next_node = "n",
					pre_node = "e",
				},
			},
		},
	},
	{ -- cycle through paste | yank history
		"gbprod/yanky.nvim", -- https://github.com/gbprod/yanky.nvim
		event = "BufRead",
		enabled = true,
		dependencies = {
			{ "kkharji/sqlite.lua" },
		},
		opts = {
			highlight = { timer = 200 },
			ring = { storage = "sqlite" },
		},
		keys = {
			{
				"<leader>sp",
				function()
					Snacks.picker.yanky({ layout = { preset = "dropdown" } })
				end,
				mode = { "n", "x" },
				desc = "Open Yank History",
			},
			{ "<c-p>", "<Plug>(YankyPreviousEntry)", mode = { "n", "x" }, desc = "Yanky previous entry" },
			{ "<leader>p", "<Plug>(YankyPreviousEntry)", mode = { "n", "x" }, desc = "Yanky previous entry" },

			-- Below is commented out because shift is not working
			-- { "<c-s-p>", "<Plug>(YankyPreviousEntry)", mode = { "n", "x" }, desc = "Yanky previous entry" },
			{ "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank Text" },
			{ "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put Yanked Text After Cursor" },
			{ "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put Yanked Text Before Cursor" },
			{ "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put Yanked Text After Selection" },
			{ "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put Yanked Text Before Selection" },
			-- { "[y", "<Plug>(YankyCycleForward)", desc = "Cycle Forward Through Yank History" },
			-- { "]y", "<Plug>(YankyCycleBackward)", desc = "Cycle Backward Through Yank History" },
			-- { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After Cursor (Linewise)" },
			-- { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before Cursor (Linewise)" },
			-- { "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After Cursor (Linewise)" },
			-- { "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before Cursor (Linewise)" },
			-- { ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and Indent Right" },
			-- { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and Indent Left" },
			-- { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put Before and Indent Right" },
			-- { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put Before and Indent Left" },
			{ "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put After Applying a Filter" },
		},
	},
	{ -- sticky keymaps
		"nvimtools/hydra.nvim", -- https://github.com/nvimtools/hydra.nvim
		event = "VeryLazy",
		config = function()
			local Hydra = require("hydra")

			-- Move the split divider in an absolute direction:
			-- > always moves divider right, < always moves left
			-- + always moves divider down, - always moves up
			local function move_divider(dir, amount)
				local cur = vim.fn.winnr()
				if dir == "right" then
					if cur == vim.fn.winnr("l") then
						vim.cmd(amount .. "wincmd <")
					else
						vim.cmd(amount .. "wincmd >")
					end
				elseif dir == "left" then
					if cur == vim.fn.winnr("l") then
						vim.cmd(amount .. "wincmd >")
					else
						vim.cmd(amount .. "wincmd <")
					end
				elseif dir == "down" then
					if cur == vim.fn.winnr("j") then
						vim.cmd(amount .. "wincmd -")
					else
						vim.cmd(amount .. "wincmd +")
					end
				elseif dir == "up" then
					if cur == vim.fn.winnr("j") then
						vim.cmd(amount .. "wincmd +")
					else
						vim.cmd(amount .. "wincmd -")
					end
				end
			end

			Hydra({
				name = "Window Resize",
				mode = "n",
				body = "<C-w>",
				heads = {
					-- press <C-w> then tap >/</+/- to resize splits
					{
						">",
						function()
							move_divider("right", 4)
						end,
						{ desc = "Divider right" },
					},
					{
						"<",
						function()
							move_divider("left", 4)
						end,
						{ desc = "Divider left" },
					},
					{
						"+",
						function()
							move_divider("down", 4)
						end,
						{ desc = "Divider down" },
					},
					{
						"-",
						function()
							move_divider("up", 4)
						end,
						{ desc = "Divider up" },
					},
					{ "=", "<C-w>=", { desc = "Equalize" } },
					{ "<Esc>", nil, { exit = true } },
				},
			})
		end,
	},
}
