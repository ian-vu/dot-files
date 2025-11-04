return {
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
					separator_style = "slope",
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
}
