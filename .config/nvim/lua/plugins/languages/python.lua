-- Module-level caches. Using local tables instead of vim.g because
-- vim.g returns copies on read, so vim.g.tbl[key] = val silently fails.
local venv_cache = {}
local ruff_cmd_cache = {}

--- Detect the project's package manager by checking for lockfiles.
--- Returns "uv", "poetry", or nil.
local function detect_pkg_manager(root_dir)
	if vim.uv.fs_stat(root_dir .. "/uv.lock") then
		return "uv"
	elseif vim.uv.fs_stat(root_dir .. "/poetry.lock") then
		return "poetry"
	end
end

--- Return the command to get the venv path for a given package manager.
local function venv_path_cmd(pkg_manager)
	if pkg_manager == "uv" then
		-- uv always puts the venv in .venv, but `uv python find` returns the
		-- interpreter path directly, handling custom toolchain configs.
		return { "uv", "python", "find" }
	elseif pkg_manager == "poetry" then
		return { "poetry", "env", "info", "--path" }
	end
end

--- Normalize venv command output into a python path.
--- uv python find returns a full interpreter path; poetry returns the venv dir.
local function normalize_python_path(pkg_manager, stdout)
	local trimmed = vim.trim(stdout)
	if trimmed == "" then
		return nil
	end
	if pkg_manager == "uv" then
		return trimmed -- already the full interpreter path
	else
		return trimmed .. "/bin/python"
	end
end

--- Normalize venv command output into a venv directory for binary lookups.
local function normalize_venv_dir(pkg_manager, stdout)
	local trimmed = vim.trim(stdout)
	if trimmed == "" then
		return nil
	end
	if pkg_manager == "uv" then
		-- uv python find returns e.g. /path/.venv/bin/python; walk up to venv root
		return vim.fn.fnamemodify(trimmed, ":h:h")
	else
		return trimmed
	end
end

--- Re-trigger FileType on loaded Python buffers to restart LSP servers
local function retrigger_python_ft()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "python" then
			vim.api.nvim_exec_autocmds("FileType", { buffer = buf, modeline = false })
		end
	end
end

local RUFF_DEFAULT_CMD = { "ruff", "server", "--preview" }

-- Resolve the project-local ruff binary before vim.lsp.enable() starts the
-- server. Unlike pyright (which only needs a pythonPath *setting* and can update
-- it on a running server via on_init + didChangeConfiguration), ruff requires
-- swapping the actual binary — the built-in `ruff server` runs analysis
-- in-process, so the correct version must be the one spawned. This autocmd is
-- registered at module load time (before vim.lsp.enable), so it fires first on
-- each FileType event, letting us update vim.lsp.config() with the correct cmd
-- before the server process is spawned.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	group = vim.api.nvim_create_augroup("ruff_binary_resolve", { clear = true }),
	callback = function(args)
		local root_dir = vim.fs.root(args.buf, { "pyproject.toml", "setup.py", "setup.cfg", ".git" })
		if not root_dir then
			return
		end

		-- Already resolved for this project
		if ruff_cmd_cache[root_dir] then
			vim.lsp.config("ruff", { cmd = ruff_cmd_cache[root_dir] })
			return
		end

		-- Check local venv (synchronous, fast)
		for _, ruff_path in ipairs({
			root_dir .. "/.venv/bin/ruff",
			root_dir .. "/venv/bin/ruff",
		}) do
			if vim.uv.fs_stat(ruff_path) then
				local cmd = { ruff_path, "server", "--preview" }
				ruff_cmd_cache[root_dir] = cmd
				vim.lsp.config("ruff", { cmd = cmd })
				return
			end
		end

		-- No local ruff; reset to default to avoid leaking another project's binary
		vim.lsp.config("ruff", { cmd = RUFF_DEFAULT_CMD })
	end,
	desc = "Resolve project-local ruff binary before LSP server starts",
})

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
						local cached_path = venv_cache[root_dir]
						if cached_path then
							client.config.settings.python.pythonPath = cached_path
							return
						end

						-- Fast path: set pythonPath from local venv (no subprocess needed)
						for _, venv_name in ipairs({ ".venv", "venv" }) do
							local python = root_dir .. "/" .. venv_name .. "/bin/python"
							if vim.uv.fs_stat(python) then
								venv_cache[root_dir] = python
								client.config.settings.python.pythonPath = python
								return
							end
						end

						-- Fallback: detect managed environments where venv lives elsewhere
						local pkg_manager = detect_pkg_manager(root_dir)
						if not pkg_manager then
							return
						end

						-- Async venv detection (non-blocking)
						vim.system(venv_path_cmd(pkg_manager), {
							cwd = root_dir,
							timeout = 2000,
						}, function(result)
							if result.code ~= 0 or not result.stdout then
								return
							end

							local python_path = normalize_python_path(pkg_manager, result.stdout)
							if not python_path then
								return
							end

							venv_cache[root_dir] = python_path

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
					-- Async fallback for non-local venvs (e.g. poetry stores venvs
					-- in ~/.cache). Local .venv/venv detection is handled by the
					-- ruff_binary_resolve FileType autocmd above, which runs before
					-- the server spawns. This on_init only covers the rare case where
					-- the venv lives outside the project directory.
					on_init = function(client)
						local root_dir = client.config.root_dir
						if not root_dir then
							return
						end

						-- Already resolved by FileType autocmd or a previous on_init
						if ruff_cmd_cache[root_dir] then
							return
						end

						local pkg_manager = detect_pkg_manager(root_dir)
						if not pkg_manager then
							ruff_cmd_cache[root_dir] = client.config.cmd
							return
						end

						vim.system(venv_path_cmd(pkg_manager), {
							cwd = root_dir,
							timeout = 2000,
						}, function(result)
							if result.code ~= 0 or not result.stdout then
								return
							end

							local venv_dir = normalize_venv_dir(pkg_manager, result.stdout)
							if not venv_dir then
								return
							end

							local ruff_path = venv_dir .. "/bin/ruff"
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
							else
								ruff_cmd_cache[root_dir] = client.config.cmd
							end
						end)
					end,
					cmd = RUFF_DEFAULT_CMD,
					cmd_env = { RUFF_TRACE = "messages" },
					init_options = {
						settings = {
							logLevel = "error",
							lint = {
								-- Suppress editor-only; these rules are enforced by project CI/tooling instead.
								-- I001: import sorting — avoid noisy diagnostics for side-effect imports and module order
								-- RUF100: unused noqa directives — projects may ignore rules globally making inline noqa redundant
								ignore = { "I001", "RUF100" },
							},
						},
					},
				},
			},
		},
	},
}
