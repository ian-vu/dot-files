-- Snacks notification and input UI

-- Strip "Snacks" branding from notification titles — keep the icon, lose the text
vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	callback = function()
		local orig_snacks_notify = Snacks.notify.notify
		Snacks.notify.notify = function(msg, opts)
			if opts and type(opts.title) == "string" then
				opts.title = opts.title:gsub("^Snacks%s*Picker%s*", "")
			end
			return orig_snacks_notify(msg, opts)
		end
	end,
})

return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			notifier = { -- Pretty vim.notify
				enabled = true,
				top_down = false,
			},
			input = { -- Pretty input (:cmd /search)
				enabled = true,
			},
		},
	},
}
