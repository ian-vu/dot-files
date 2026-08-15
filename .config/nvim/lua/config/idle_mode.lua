local M = {}

local uv = vim.uv or vim.loop
local check_every_minutes = 15
local default_idle_after_minutes = 3 * 60
local minute_ms = 60 * 1000

local check_timer = nil
local check_in_progress = false
local focused = true
local hidden_since = nil

local function stop_check_timer()
	if check_timer then
		check_timer:stop()
		check_timer:close()
		check_timer = nil
	end
end

local function has_running_terminal()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == "terminal" then
			local job_id = vim.b[bufnr].terminal_job_id
			if type(job_id) == "number" and job_id > 0 then
				local ok, statuses = pcall(vim.fn.jobwait, { job_id }, 0)
				if not ok or statuses[1] == -1 then
					return true
				end
			end
		end
	end
	return false
end

local function safe_to_quit()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].modified then
			return false
		end
	end
	return not has_running_terminal()
end

local function pane_is_visible(callback)
	local pane = vim.env.TMUX_PANE
	if not vim.env.TMUX or not pane or pane == "" then
		callback(focused)
		return
	end

	vim.system(
		{
			"tmux",
			"display-message",
			"-p",
			"-t",
			pane,
			"#{session_attached}:#{window_active}:#{pane_active}",
		},
		{ text = true },
		vim.schedule_wrap(function(result)
			if result.code ~= 0 then
				callback(true)
				return
			end

			local attached, window_active, pane_active = result.stdout:match("(%d+):(%d+):(%d+)")
			if not attached then
				callback(true)
				return
			end

			callback(focused and tonumber(attached) > 0 and window_active == "1" and pane_active == "1")
		end)
	)
end

local function check_idle()
	if check_in_progress or vim.g.disable_idle_quit then
		return
	end
	check_in_progress = true

	pane_is_visible(function(visible)
		check_in_progress = false
		if visible then
			hidden_since = nil
			return
		end

		local now = uv.now()
		if not hidden_since then
			hidden_since = now
			return
		end

		local idle_after_minutes = tonumber(vim.g.idle_quit_after_minutes) or default_idle_after_minutes
		if now - hidden_since < idle_after_minutes * minute_ms or not safe_to_quit() then
			return
		end

		-- :qall remains a final safeguard if a buffer changes after the checks above.
		pcall(vim.cmd, "qall")
	end)
end

function M.setup()
	stop_check_timer()
	local group = vim.api.nvim_create_augroup("idle-mode", { clear = true })

	vim.api.nvim_create_autocmd("FocusLost", {
		group = group,
		callback = function()
			focused = false
			hidden_since = uv.now()
		end,
	})

	vim.api.nvim_create_autocmd("FocusGained", {
		group = group,
		callback = function()
			focused = true
			hidden_since = nil
		end,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = stop_check_timer,
	})

	check_timer = assert(uv.new_timer())
	check_timer:start(check_every_minutes * minute_ms, check_every_minutes * minute_ms, vim.schedule_wrap(check_idle))
end

return M
