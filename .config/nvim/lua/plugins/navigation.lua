return {
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
	{
		"folke/trouble.nvim",
		opts = {
			win = {
				size = 0.3,
			},
		},
		cmd = "Trouble",
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
	{ -- better quick fix qflist
		"stevearc/quicker.nvim",
		event = "FileType qf",
		---@module "quicker"
		---@type quicker.SetupOptions
		opts = {},
	},
}
