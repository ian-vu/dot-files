local M = {}

local idle_after_hours = 3
local idle_after_seconds = idle_after_hours * 60 * 60

local idle_timer = nil

local function cancel_idle_timer()
	if idle_timer then
		idle_timer:stop()
		idle_timer:close()
		idle_timer = nil
	end
end

local function quit_if_unmodified()
	-- Use :qall so idle Neovim processes disappear without risking unsaved work.
	pcall(function()
		vim.cmd("qall")
	end)
end

local function arm_idle_timer()
	cancel_idle_timer()
	idle_timer = vim.loop.new_timer()
	idle_timer:start(
		idle_after_seconds * 1000,
		0,
		vim.schedule_wrap(function()
			quit_if_unmodified()
		end)
	)
end

function M.setup()
	-- Activity means the session is in use again, so only FocusLost can start an idle quit countdown.
	vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "TextChanged", "TextChangedI", "CmdlineEnter" }, {
		callback = function()
			cancel_idle_timer()
		end,
	})

	-- Start the countdown when leaving the pane/session.
	vim.api.nvim_create_autocmd("FocusLost", {
		callback = function()
			arm_idle_timer()
		end,
	})

	-- Returning to the pane keeps Neovim alive.
	vim.api.nvim_create_autocmd("FocusGained", {
		callback = function()
			cancel_idle_timer()
		end,
	})
end

return M
