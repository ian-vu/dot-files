-- Resolve symlinks so event patterns match the real path Neovim uses
-- (~/notes is a symlink to iCloud)
local notes_path = vim.uv.fs_realpath(vim.fn.expand("~") .. "/notes") or vim.fn.expand("~") .. "/notes"
local heidi_path = vim.fn.expand("~") .. "/Documents/heidi_obsidian"

return {
	{
		"obsidian-nvim/obsidian.nvim", -- https://github.com/obsidian-nvim/obsidian.nvim
		version = "*",
		-- Only load for markdown files inside vault directories
		event = {
			"BufReadPre " .. notes_path .. "/*.md",
			"BufReadPre " .. notes_path .. "/**/*.md",
			"BufNewFile " .. notes_path .. "/*.md",
			"BufNewFile " .. notes_path .. "/**/*.md",
			"BufReadPre " .. heidi_path .. "/*.md",
			"BufReadPre " .. heidi_path .. "/**/*.md",
			"BufNewFile " .. heidi_path .. "/*.md",
			"BufNewFile " .. heidi_path .. "/**/*.md",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		---@module 'obsidian'
		---@type obsidian.config
		opts = {
			workspaces = {
				{
					name = "notes",
					path = "~/notes",
				},
				{
					name = "heidi",
					path = "~/Documents/heidi_obsidian",
				},
			},

			daily_notes = {
				folder = "04_Archive/daily-notes",
				date_format = "%Y-%m-%d",
				-- template = "daily-note",
			},

			templates = {
				folder = "03_Resources/obsidian/templates",
				date_format = "%Y-%m-%d",
				time_format = "%H:%M",
			},

			-- Attachments match Obsidian app setting
			attachments = {
				img_folder = "04_Archive/attachments",
			},

			-- Use note title as filename, falling back to zettel-style ID
			note_id_func = function(title)
				if title ~= nil then
					return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
				end
				return tostring(os.time())
			end,

			picker = {
				name = "snacks.pick",
			},

			-- Advanced URI plugin is installed in the notes vault
			use_advanced_uri = true,

			preferred_link_style = "wiki",

			-- blink.cmp is auto-detected; no explicit config needed
		},
	},
}
