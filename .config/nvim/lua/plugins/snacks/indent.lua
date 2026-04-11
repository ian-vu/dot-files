-- Snacks indent guides and scope detection
return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			indent = {
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
						arrow = "",
					},
				},
			},
		},
	},
}
