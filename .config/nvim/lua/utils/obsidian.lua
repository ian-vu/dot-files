local M = {}

-- Resolve symlinks so event patterns and path comparisons match the real path
-- neovim reports (~/notes is a symlink to iCloud).
M.notes_path = vim.uv.fs_realpath(vim.fn.expand("~") .. "/notes") or vim.fn.expand("~") .. "/notes"
M.heidi_path = vim.fn.expand("~") .. "/Documents/heidi_obsidian"

---@param buf integer
---@return boolean
function M.in_vault(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" then
		return false
	end
	local real = vim.uv.fs_realpath(name) or name
	return vim.startswith(real, M.notes_path) or vim.startswith(real, M.heidi_path)
end

return M
