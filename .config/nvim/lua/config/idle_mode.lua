local M = {}

local idle_after_hours = 3
local idle_after_seconds = idle_after_hours * 60 * 60

local idle_timer = nil
local idle_active = false

-- Save settings to restore cleanly
local saved = {
	updatetime = nil,
	lazyredraw = nil,
}

local function enter_idle_mode()
	if idle_active then
		return
	end
	idle_active = true

	-- Save current options
	saved.updatetime = vim.o.updatetime
	saved.lazyredraw = vim.o.lazyredraw

	-- Reduce background churn
	vim.o.updatetime = 4000
	vim.o.lazyredraw = true

	-- Stop/disable expensive subsystems (best-effort; some may not exist)
	pcall(function()
		vim.diagnostic.enable(false)
	end)
	pcall(function()
		vim.cmd("silent! LspStop")
	end)
	pcall(function()
		vim.cmd("silent! syntax off")
	end)

	-- Stop treesitter highlighting if running
	pcall(function()
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) then
				pcall(vim.treesitter.stop, buf)
			end
		end
	end)
end

local function exit_idle_mode()
	if not idle_active then
		return
	end
	idle_active = false

	-- Restore options
	if saved.updatetime ~= nil then
		vim.o.updatetime = saved.updatetime
	end
	if saved.lazyredraw ~= nil then
		vim.o.lazyredraw = saved.lazyredraw
	end

	-- Re-enable things
	pcall(function()
		vim.cmd("silent! syntax on")
	end)
	pcall(function()
		vim.diagnostic.enable(true)
	end)
	pcall(function()
		vim.cmd("silent! LspStart")
	end)

	-- Restart treesitter for current buffer (and any others will start on demand)
	pcall(function()
		local buf = vim.api.nvim_get_current_buf()
		vim.treesitter.start(buf)
	end)

	-- Force a clean redraw
	pcall(function()
		vim.cmd("redraw!")
	end)
end

local function cancel_idle_timer()
	if idle_timer then
		idle_timer:stop()
		idle_timer:close()
		idle_timer = nil
	end
end

local function arm_idle_timer()
	cancel_idle_timer()
	idle_timer = vim.loop.new_timer()
	idle_timer:start(
		idle_after_seconds * 1000,
		0,
		vim.schedule_wrap(function()
			enter_idle_mode()
		end)
	)
end

function M.setup()
	-- Any activity should “wake” and reset the idle timer
	vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "TextChanged", "TextChangedI", "CmdlineEnter" }, {
		callback = function()
			exit_idle_mode()
			-- If we’re focused, don’t keep an idle timer armed from old focus-loss.
			cancel_idle_timer()
		end,
	})

	-- When leaving the pane/session: start countdown to idle mode
	vim.api.nvim_create_autocmd("FocusLost", {
		callback = function()
			arm_idle_timer()
		end,
	})

	-- When returning to the pane: wake up immediately
	vim.api.nvim_create_autocmd("FocusGained", {
		callback = function()
			cancel_idle_timer()
			exit_idle_mode()
		end,
	})
end

return M
