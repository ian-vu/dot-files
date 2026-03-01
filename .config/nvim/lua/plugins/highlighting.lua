return {
	{ -- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter", -- https://github.com/nvim-treesitter/nvim-treesitter
		build = ":TSUpdate",
		main = "nvim-treesitter.configs", -- Sets main module to use for opts
		-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
			},
			-- Autoinstall languages that are not installed
			auto_install = true,
			highlight = {
				enable = true,
			},
			indent = { enable = true },
		},
		-- There are additional nvim-treesitter modules that you can use to interact
		-- with nvim-treesitter. You should go explore a few and see what interests you:
		--
		--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
		--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
		--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
	},
	{ -- Top of buffer showing context of current line
		"nvim-treesitter/nvim-treesitter-context", -- https://github.com/nvim-treesitter/nvim-treesitter-context
		event = "BufRead",
		opts = {
			multiwindow = true,
			seperator = "~",
			max_lines = 15,
			multiline_threshold = 3,
			mode = "topline",
		},
		config = function(_, opts)
			require("treesitter-context").setup(opts)
			-- vim.cmd 'hi TreesitterContext None'
			-- vim.cmd("hi TreesitterContextBottom gui=underline guisp=Grey")
			-- vim.cmd 'hi TreesitterContextLineNumberBottom gui=underline guisp=Grey'
		end,
	},
	{ -- illuminate word under cursor
		"RRethy/vim-illuminate", -- https://github.com/RRethy/vim-illuminate
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
	-- Highlight todo, notes, etc in comments
	{
		"folke/todo-comments.nvim", -- https://github.com/folke/todo-comments.nvim
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},
	{
		"nvim-mini/mini.hipatterns", -- https://github.com/nvim-mini/mini.hipatterns
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
		"norcalli/nvim-colorizer.lua", -- https://github.com/norcalli/nvim-colorizer.lua
		event = "BufRead",
		opts = {},
	},
}
