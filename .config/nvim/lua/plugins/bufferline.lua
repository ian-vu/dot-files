return {
	{
		"akinsho/bufferline.nvim", -- https://github.com/akinsho/bufferline.nvim
		version = "*",
		dependencies = { "nvim-tree/nvim-web-devicons", "ThePrimeagen/harpoon" },
		config = function()
			local bufferline = require("bufferline")
			local harpoon = require("harpoon")

			local harpoon_lookup = {}
			local sync_pending = false

			local function sync()
				-- Debounce: coalesce multiple sync calls in the same event loop tick
				-- (e.g. bufadd inside sync triggering BufAdd autocmd)
				if sync_pending then
					return
				end
				sync_pending = true
				vim.schedule(function()
					sync_pending = false
					harpoon_lookup = {}
					local items = harpoon:list().items
					for i, item in ipairs(items) do
						harpoon_lookup[item.value] = i
						-- Register buffer so bufferline can show it before it's visited
						local bufnr = vim.fn.bufadd(item.value)
						vim.bo[bufnr].buflisted = true
					end
					-- Hide tabline when harpoon list is empty, unless multiple tabpages exist
					vim.o.showtabline = (#items > 0 or vim.fn.tabpagenr("$") > 1) and 2 or 0
					vim.cmd("redrawtabline")
				end)
			end

			-- Sync on any harpoon list mutation instead of manual calls in keymaps
			harpoon:extend({
				ADD = sync,
				REMOVE = sync,
				REORDER = sync,
				LIST_CHANGE = sync, -- covers bulk edits via harpoon UI
			})

			sync()

			-- Harpoon's clear() doesn't emit any extension event, so wrap it
			-- to trigger a sync and update the tabline.
			local list = harpoon:list()
			local orig_clear = list.clear
			list.clear = function(self, ...)
				orig_clear(self, ...)
				sync()
			end

			-- Re-sync on tab events that affect tabline visibility
			vim.api.nvim_create_autocmd({ "TabNew", "TabClosed" }, {
				callback = sync,
			})

			local function buf_harpoon_index(buf)
				local rel = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":.")
				return harpoon_lookup[rel]
			end

			-- Enforce showtabline based on harpoon state (non-deferred, for use in autocmds)
			local function update_showtabline()
				local items = harpoon:list().items
				vim.o.showtabline = (#items > 0 or vim.fn.tabpagenr("$") > 1) and 2 or 0
			end

			bufferline.setup({
				options = {
					-- Disable separators between tabs
separator_style = { "", "" },
					style_preset = bufferline.style_preset.no_italic,
					numbers = function(opts)
						local idx = buf_harpoon_index(opts.id)
						if idx then
							return opts.lower(idx)
						end
						return ""
					end,
					themeable = true,
					indicator = {
						style = "none",
					},
					show_buffer_icons = false,
					show_buffer_close_icons = false,
					-- sync() manages showtabline based on harpoon list; let bufferline stay out of it
					always_show_bufferline = true,
					custom_filter = function(buf_number)
						return buf_harpoon_index(buf_number) ~= nil
					end,
					sort_by = function(buffer_a, buffer_b)
						local idx_a = buf_harpoon_index(buffer_a.id) or 999
						local idx_b = buf_harpoon_index(buffer_b.id) or 999
						return idx_a < idx_b
					end,
				},
			})

			-- Correct showtabline after bufferline renders on buffer events.
			-- Created after bufferline.setup() so it runs after bufferline's handler.
			vim.api.nvim_create_autocmd("BufEnter", {
				callback = update_showtabline,
			})
		end,
	},
}
