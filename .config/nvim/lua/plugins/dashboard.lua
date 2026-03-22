return {
	{ -- Allow for session saving and restoring
		"folke/persistence.nvim", -- https://github.com/folke/persistence.nvim
		event = "BufReadPre", -- this will only start session saving when an actual file was opened
		opts = {
			-- add any custom options here
		},
	},
	{ -- Dashboard is now provided by snacks.nvim
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			dashboard = {
				enabled = true,
				preset = {
					-- 					header = [[
					-- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
					-- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
					-- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
					-- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
					-- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
					-- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
					header = [[
 ███▄    █ ▓█████  ▒█████   ██▒   █▓ ██▓ ███▄ ▄███▓
 ██ ▀█   █ ▓█   ▀ ▒██▒  ██▒▓██░   █▒▓██▒▓██▒▀█▀ ██▒
▓██  ▀█ ██▒▒███   ▒██░  ██▒ ▓██  █▒░▒██▒▓██    ▓██░
▓██▒  ▐▌██▒▒▓█  ▄ ▒██   ██░  ▒██ █░░░██░▒██    ▒██
▒██░   ▓██░░▒████▒░ ████▓▒░   ▒▀█░  ░██░▒██▒   ░██▒
░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒░▒░▒░    ░ ▐░  ░▓  ░ ▒░   ░  ░
░ ░░   ░ ▒░ ░ ░  ░  ░ ▒ ▒░    ░ ░░   ▒ ░░  ░      ░
   ░   ░ ░    ░   ░ ░ ░ ▒       ░░   ▒ ░░      ░
         ░    ░  ░    ░ ░        ░   ░         ░
                                ░                  ]],
					keys = {
						{ icon = "󰦛", key = "s", desc = "Restore Session", section = "session" },
						{
							icon = "󱏒 ",
							key = "e",
							desc = "Explorer",
							action = function()
								require("oil").open()
							end,
						},
						{ icon = "", key = "n", desc = "New file", action = ":ene | startinsert" },
						{ icon = "󰇈 ", key = "t", desc = "Today's note", action = ":ObsidianToday" },
						{ icon = "󰇈 ", key = "T", desc = "Tomorrow's note", action = ":ObsidianTomorrow" },
						{ icon = "󰈆", key = "q", desc = "Quit", action = ":qa" },
					},
				},
				sections = {
					{ section = "header" },
					{
						-- pane = 2,
						section = "keys",
						padding = 1,
					},
					{
						-- pane = 2,
						icon = "",
						title = "Recent Files",
						section = "recent_files",
						indent = 2,
						padding = 1,
					},
					{
						-- pane = 2,
						icon = "",
						title = "Git Status",
						section = "terminal",
						enabled = function()
							return Snacks.git.get_root() ~= nil
						end,
						cmd = "git status --short --branch --renames",
						height = 5,
						padding = 1,
						ttl = 5 * 60,
						indent = 3,
					},
					{
						section = "terminal",
						cmd = "neofetch --disable title --color_blocks off --off --color_blocks off --colors 0 0 0 111 7 7",
						height = 15,
						padding = 1,
						ttl = 0,
						indent = 3,
					},
					{ section = "startup" },
				},
			},
		},
	},
}
