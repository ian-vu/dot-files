-- Snacks base plugin spec.
-- Each feature is configured in its own sibling file.
return {
	-- lazy.nvim discovers this init.lua via { import = "plugins" }, but doesn't scan
	-- sibling files (picker.lua, indent.lua, etc.) automatically. This import directive
	-- tells lazy.nvim to scan the plugins.snacks module path for all .lua files.
	{ import = "plugins.snacks" },
	{
		"folke/snacks.nvim", -- https://github.com/folke/snacks.nvim
		priority = 1,
		lazy = false,
	},
}
