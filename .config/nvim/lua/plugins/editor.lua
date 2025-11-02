return {
	{ -- illuminate word under cursor
		"RRethy/vim-illuminate",
		enable = false,
		event = "BufRead",
		opts = {
			delay = 50,
			large_file_cutoff = 2000,
			large_file_overrides = {
				providers = { "lsp" },
			},
		},
		config = function(_, opts)
			require("illuminate").configure(opts)
		end,
	},
	{
		"NMAC427/guess-indent.nvim", -- Detect tabstop and shiftwidth automatically
		enabled = false,
		event = "BufRead",
	},
	{ -- Navigate between tmux panes
		"christoomey/vim-tmux-navigator",
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
		},
	},
	-- Highlight todo, notes, etc in comments
	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},
	{ -- Easy commenting to be used with keymaps
		"numToStr/Comment.nvim",
		event = "BufRead",
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},
	{
		"folke/flash.nvim",
		enabled = true,
		event = "VeryLazy",
		opts = {
			-- Show labels before the search word
			label = {
				before = true,
				after = false,
			},
			modes = {
				-- Disable flash for `/`
				search = { enabled = false },

				-- Disable flash when using `f`, `F`, `t`, `T`, `;` and `,` motions
				char = { enabled = false },
			},
		},
	},
	{ -- undo history
		"mbbill/undotree",
		enabled = true,
		event = "BufRead",
		config = function()
			vim.g.undotree_WindowLayout = 3
			vim.g.undotree_SetFocusWhenToggle = 1
			vim.g.undotree_TreeNodeShape = ""
			vim.g.undotree_DiffpanelHeight = 20
			vim.g.undotree_SplitWidth = 40
		end,
	},
	{
		"XXiaoA/atone.nvim",
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
	{
		"folke/trouble.nvim",
		-- lazy = false,
		-- optional = true,
		opts = {
			win = {
				-- input = {
				--   keys = {
				--     ['<c-t>'] = {
				--       'trouble_open',
				--       mode = { 'n', 'i' },
				--     },
				--   },
				-- },
				size = 0.3,
			},
		},
		cmd = "Trouble",
	},
	{ -- cycle through paste | yank history
		"gbprod/yanky.nvim",
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
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "BufRead",
		opts = {
			multiwindow = true,
			seperator = "~",
		},
		config = function(_, opts)
			require("treesitter-context").setup(opts)
			-- vim.cmd 'hi TreesitterContext None'
			-- vim.cmd("hi TreesitterContextBottom gui=underline guisp=Grey")
			-- vim.cmd 'hi TreesitterContextLineNumberBottom gui=underline guisp=Grey'
		end,
	},
	{ -- better quick fix qflist
		"stevearc/quicker.nvim",
		event = "FileType qf",
		---@module "quicker"
		---@type quicker.SetupOptions
		opts = {},
	},
	{
		"nvim-mini/mini.hipatterns",
		version = "*",
		opts = {
			-- Table with highlighters (see |MiniHipatterns.config| for more details).
			-- Nothing is defined by default. Add manually for visible effect.
			highlighters = {},

			-- Delays (in ms) defining asynchronous highlighting process
			delay = {
				-- How much to wait for update after every text change
				text_change = 200,

				-- How much to wait for update after window scroll
				scroll = 50,
			},
		},
	},
	{
		"norcalli/nvim-colorizer.lua",
		event = "BufRead",
		opts = {},
	},
	{
		-- Search and replace
		"nvim-pack/nvim-spectre",
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		opts = {},
	},
	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = "nvim-tree/nvim-web-devicons",
		config = function()
			local bufferline = require("bufferline")

			-- Track buffer access times globally
			_G.buffer_access_times = _G.buffer_access_times or {}
			_G.sorted_buffers = _G.sorted_buffers or {}

			-- Set up autocommand to track buffer visits and keep sorted list
			vim.api.nvim_create_autocmd("BufEnter", {
				callback = function(args)
					-- Skip if in a floating window (picker, etc.)
					local win = vim.api.nvim_get_current_win()
					local config = vim.api.nvim_win_get_config(win)
					if config.relative ~= "" then
						return
					end

					_G.buffer_access_times[args.buf] = os.time()

					-- Update sorted buffer list
					local buffers = vim.tbl_filter(function(b)
						return vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted
					end, vim.api.nvim_list_bufs())

					table.sort(buffers, function(a, b)
						local time_a = _G.buffer_access_times[a] or 0
						local time_b = _G.buffer_access_times[b] or 0
						return time_a > time_b
					end)

					_G.sorted_buffers = buffers
				end,
			})

			bufferline.setup({
				options = {
					style_preset = bufferline.style_preset.no_italic,
					-- numbers = "ordinal",
					-- Show number next to buffer name
					numbers = function(opts)
						-- Find the index of the current buffer in the sorted list
						for i, buf in ipairs(_G.sorted_buffers) do
							if buf == opts.id then
								return string.format("%s", opts.lower(i))
							end
						end
						-- Fallback to ordinal if not found
						return string.format("%s", opts.lower(opts.ordinal))
					end,
					themeable = true,
					indicator = {
						-- icon = "",
						style = "none",
					},
					show_buffer_icons = false,
					show_buffer_close_icons = false,
					pick = {
						-- alphabet = "neiluym,.",
					},
					sort_by = function(buffer_a, buffer_b)
						-- Sort by last access time (most recently accessed first)
						local time_a = _G.buffer_access_times[buffer_a.id] or 0
						local time_b = _G.buffer_access_times[buffer_b.id] or 0
						return time_a > time_b
					end,
				},
			})
		end,
	},
	{
		{
			"nvim-mini/mini.surround",
			event = "BufRead",
			version = false,
			opts = {},
		},
	},
}
