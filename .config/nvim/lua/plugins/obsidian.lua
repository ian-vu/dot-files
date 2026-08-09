local obsidian_util = require("utils.obsidian")
local notes_path = obsidian_util.notes_path
local heidi_path = obsidian_util.heidi_path

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
		-- Set conceallevel for vault notes only. The obsidian.nvim `enter_note`
		-- callback is unreliable — markdown ftplugin loads after it and resets
		-- the option — so we own this via a BufEnter autocmd that re-applies
		-- every time the buffer is focused.
		init = function()
			local group = vim.api.nvim_create_augroup("ObsidianVaultConceal", { clear = true })
			vim.api.nvim_create_autocmd("BufEnter", {
				group = group,
				pattern = {
					notes_path .. "/*.md",
					notes_path .. "/**/*.md",
					heidi_path .. "/*.md",
					heidi_path .. "/**/*.md",
				},
				callback = function()
					vim.opt_local.conceallevel = 2
				end,
			})
		end,
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		-- Keymaps also act as lazy-load triggers so commands work outside vault buffers
		keys = {
			{ "<leader>on", "<cmd>Obsidian new<cr>", desc = "Obsidian: new note" },
			{ "<leader>oo", "<cmd>Obsidian open<cr>", desc = "Obsidian: open in app" },
			{ "<leader>os", "<cmd>Obsidian search<cr>", desc = "Obsidian: search notes" },
			{ "<leader>oq", "<cmd>Obsidian quick_switch<cr>", desc = "Obsidian: quick switch" },
			{ "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Obsidian: backlinks" },
			{ "<leader>ok", "<cmd>Obsidian links<cr>", desc = "Obsidian: links in note" },
			{ "<leader>of", "<cmd>Obsidian follow_link<cr>", desc = "Obsidian: follow link" },
			{ "<leader>og", "<cmd>Obsidian tags<cr>", desc = "Obsidian: tags" },
			{ "<leader>ot", "<cmd>Obsidian today<cr>", desc = "Obsidian: today's daily note" },
			{ "<leader>oy", "<cmd>Obsidian yesterday<cr>", desc = "Obsidian: yesterday's daily note" },
			{ "<leader>oT", "<cmd>Obsidian tomorrow<cr>", desc = "Obsidian: tomorrow's daily note" },
			{ "<leader>od", "<cmd>Obsidian dailies<cr>", desc = "Obsidian: list dailies" },
			{ "<leader>oi", "<cmd>Obsidian template<cr>", desc = "Obsidian: insert template" },
			{ "<leader>ow", "<cmd>Obsidian workspace<cr>", desc = "Obsidian: switch workspace" },
			{ "<leader>ox", "<cmd>Obsidian toggle_checkbox<cr>", desc = "Obsidian: toggle checkbox" },
			{ "<leader>or", "<cmd>Obsidian rename<cr>", desc = "Obsidian: rename note" },
			{ "<leader>op", "<cmd>Obsidian paste_img<cr>", desc = "Obsidian: paste image" },
			{ "<leader>ol", "<cmd>Obsidian link<cr>", mode = "v", desc = "Obsidian: link selection" },
			{
				"<leader>oL",
				"<cmd>Obsidian link_new<cr>",
				mode = "v",
				desc = "Obsidian: new linked note from selection",
			},
		},
		---@module 'obsidian'
		---@type obsidian.config
		opts = {
			-- Use new command format (e.g. :Obsidian backlinks instead of :ObsidianBacklinks)
			legacy_commands = false,

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
				folder = "04_Archive/attachments",
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

			open = {
				-- Advanced URI plugin is installed in the notes vault
				use_advanced_uri = true,
			},

			link = {
				style = "wiki",
			},

			-- render-markdown.nvim owns visual markdown concealment; leaving Obsidian's
			-- legacy UI on causes duplicate checkbox extmarks that hide following text.
			ui = {
				enable = false,
			},

			-- blink.cmp is auto-detected; no explicit config needed
		},
	},
}
