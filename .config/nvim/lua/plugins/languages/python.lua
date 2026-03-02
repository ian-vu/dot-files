-- Module-level caches. Using local tables instead of vim.g because
-- vim.g returns copies on read, so vim.g.tbl[key] = val silently fails.
local poetry_venv_cache = {}
local ruff_cmd_cache = {}

--- Re-trigger FileType on loaded Python buffers to restart LSP servers
local function retrigger_python_ft()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "python" then
			vim.api.nvim_exec_autocmds("FileType", { buffer = buf, modeline = false })
		end
	end
end

-- Disable ruff hover in favor of Pyright
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client == nil then
			return
		end
		if client.name == "ruff" then
			client.server_capabilities.hoverProvider = false
		end
	end,
	desc = "LSP: Disable hover capability from Ruff",
})

return {
	{
		"neovim/nvim-lspconfig", -- https://github.com/neovim/nvim-lspconfig
		opts = {
			servers = {
				pyright = {
					single_file_support = true,
					-- on_new_config is not supported by vim.lsp.config() (nvim 0.11+).
					-- Use on_init instead: it fires after the server initializes but
					-- before settings are sent via automatic didChangeConfiguration.
					on_init = function(client)
						local root_dir = client.config.root_dir
						if not root_dir then
							return
						end

						-- Use cached path (applies before automatic didChangeConfiguration)
						local cached_path = poetry_venv_cache[root_dir]
						if cached_path then
							client.config.settings.python.pythonPath = cached_path
							return
						end

						-- Only detect poetry environments (pyright auto-detects .venv and venv)
						if not vim.uv.fs_stat(root_dir .. "/poetry.lock") then
							return
						end

						-- Async poetry venv detection (non-blocking)
						vim.system({ "poetry", "env", "info", "--path" }, {
							cwd = root_dir,
							timeout = 2000,
						}, function(result)
							if result.code ~= 0 or not result.stdout then
								return
							end

							local venv_path = vim.trim(result.stdout)
							if venv_path == "" then
								return
							end

							local python_path = venv_path .. "/bin/python"
							poetry_venv_cache[root_dir] = python_path

							-- Update running pyright with the detected path
							vim.schedule(function()
								for _, c in pairs(vim.lsp.get_clients({ name = "pyright" })) do
									if c.config.root_dir == root_dir then
										c.config.settings.python.pythonPath = python_path
										c:notify(
											"workspace/didChangeConfiguration",
											{ settings = c.config.settings }
										)
									end
								end
							end)
						end)
					end,
					settings = {
						pyright = {
							disableOrganizeImports = true, -- Using Ruff for this
						},
						python = {
							analysis = {
								autoImportCompletions = true,
								autoSearchPaths = true,
								diagnosticMode = "openFilesOnly", -- 'workspace' or 'openFilesOnly'
								useLibraryCodeForTypes = true,
								reportUnusedImport = true,
								reportUnusedVariable = true,
								reportDuplicateImport = true,
								reportConstantRedefinition = true,
								reportIncompatibleMethodOverride = true,
								reportIncompatibleVariableOverride = true,
							},
						},
					},
				},
				ruff = {
					-- on_new_config is not supported by vim.lsp.config() (nvim 0.11+).
					-- Use on_init to detect a project-local ruff binary and restart
					-- with it if the current instance is using the wrong one.
					on_init = function(client)
						local root_dir = client.config.root_dir
						if not root_dir then
							return
						end

						local cached_cmd = ruff_cmd_cache[root_dir]
						if cached_cmd then
							if vim.deep_equal(client.config.cmd, cached_cmd) then
								return -- Already running the correct binary
							end
							-- Wrong binary, update global config and restart
							vim.lsp.config("ruff", { cmd = cached_cmd })
							vim.defer_fn(retrigger_python_ft, 100)
							return false
						end

						-- Check local venv paths (synchronous, fast)
						local local_ruff_paths = {
							root_dir .. "/.venv/bin/ruff",
							root_dir .. "/venv/bin/ruff",
						}
						for _, ruff_path in ipairs(local_ruff_paths) do
							if vim.fn.executable(ruff_path) == 1 then
								local cmd = { ruff_path, "server", "--preview" }
								ruff_cmd_cache[root_dir] = cmd
								vim.lsp.config("ruff", { cmd = cmd })
								vim.defer_fn(retrigger_python_ft, 100)
								return false -- Kill this instance, restart with local ruff
							end
						end

						-- Check poetry (async, non-blocking)
						if vim.uv.fs_stat(root_dir .. "/poetry.lock") then
							vim.system({ "poetry", "env", "info", "--path" }, {
								cwd = root_dir,
								timeout = 2000,
							}, function(result)
								if result.code ~= 0 or not result.stdout then
									return
								end

								local venv_path = vim.trim(result.stdout)
								if venv_path == "" then
									return
								end

								local ruff_path = venv_path .. "/bin/ruff"
								if vim.uv.fs_stat(ruff_path) then
									local cmd = { ruff_path, "server", "--preview" }
									vim.schedule(function()
										ruff_cmd_cache[root_dir] = cmd
										vim.lsp.config("ruff", { cmd = cmd })
										for _, c in pairs(vim.lsp.get_clients({ name = "ruff" })) do
											if c.config.root_dir == root_dir then
												c:stop()
											end
										end
										vim.defer_fn(retrigger_python_ft, 100)
									end)
								end
							end)
						end

						-- Cache default cmd so we don't re-check on next start
						ruff_cmd_cache[root_dir] = client.config.cmd
					end,
					cmd = { "ruff", "server", "--preview" },
					cmd_env = { RUFF_TRACE = "messages" },
					init_options = {
						settings = {
							logLevel = "error",
						},
					},
				},
			},
		},
	},
}
