return {
	{
		"sainnhe/gruvbox-material", -- https://github.com/sainnhe/gruvbox-material
		enabled = false,
		priority = 1000,
		config = function()
			-- vim.cmd("set background=light")
			-- vim.cmd("set background=dark")
			vim.cmd("let g:gruvbox_material_background = 'hard'") -- soft | medium | hard
			vim.cmd("let g:gruvbox_material_foreground = 'mix'") -- material | mix | original
			-- vim.cmd("let g:gruvbox_material_transparent_background = 2")
			-- vim.cmd("let g:gruvbox_material_better_performance = 1")
			vim.cmd("let g:gruvbox_material_enable_bold = 0")
			vim.cmd("let g:gruvbox_material_enable_italic = 1")
			-- vim.cmd("let g:gruvbox_material_dim_inactive_windows = 1")
			-- vim.cmd("let g:gruvbox_material_visual = 'blue background'")
			vim.cmd("let g:gruvbox_material_spell_foreground = 1")
			-- vim.cmd("let g:gruvbox_material_diagnostic_text_highlight = 1")
			vim.cmd("let g:gruvbox_material_diagnostic_virtual_text = 'colored'") -- 'highlighted' for extra
			-- How to highlight the current cursor word
			vim.cmd("let g:gruvbox_material_current_word = 'grey background'") -- 'underline' or 'grey background'

			-- This should be last
			vim.cmd("colorscheme gruvbox-material")
		end,
		opts = {
			inverse = true,
		},
	},
	{ -- You can easily change to a different colorscheme.
		-- Change the name of the colorscheme plugin below, and then
		-- change the command in the config to whatever the name of that colorscheme is.
		--
		-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
		"folke/tokyonight.nvim", -- https://github.com/folke/tokyonight.nvim
		enabled = true,
		priority = 1000, -- Make sure to load this before all the other start plugins.
		config = function()
			---@diagnostic disable-next-line: missing-fields
			require("tokyonight").setup({
				styles = {
					comments = { italic = true }, -- enable italics in comments
					functions = { italic = true }, -- enable italics in functions
					-- variables = { italic = true }, -- enable italics in variables
				},
			})

			-- Load the colorscheme here.
			-- Like many other themes, this one has different styles, and you could load
			-- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
			vim.cmd.colorscheme("tokyonight-moon")

			-- -- Italic path in Snacks picker (matches gruvbox-material behavior)
			-- vim.api.nvim_set_hl(0, "SnacksPickerDir", { link = "Comment" })
		end,
	},
}
