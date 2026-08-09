-- Python LSP configuration: Pyright (type checking) + Ruff (linting/formatting).
--
-- Virtual environment resolution strategy (applies to both servers):
--   1. Synchronous local check: look for .venv/bin or venv/bin under the project
--      root. This is the fast path and covers the common case.
--   2. Async package-manager fallback: if no local venv is found, detect uv or
--      poetry via lockfiles and shell out to resolve the venv path. This handles
--      managed environments that live outside the project (e.g. poetry in ~/.cache).
--
-- Pyright and ruff differ in how they consume the resolved path:
--   - Pyright accepts a pythonPath *setting* and can be updated on a running
--     server via workspace/didChangeConfiguration.
--   - Ruff runs analysis in-process, so the correct binary must be the one
--     spawned. A FileType autocmd (registered before vim.lsp.enable) resolves
--     the binary synchronously before the server starts. The async fallback in
--     on_init covers the rare non-local case by stopping and restarting the server.

-- Module-level caches. Using local tables instead of vim.g because
-- vim.g returns copies on read, so vim.g.tbl[key] = val silently fails.
local venv_cache = {}
local ruff_cmd_cache = {}
local pyright_cmd_cache = {}
-- Shared async venv-resolution state, keyed by root_dir. nil = not requested;
-- {pending={cb...}} = subprocess in flight (calllers queued); {python_path=...,
-- venv_dir=...} = resolved and cached for reuse by pyright + ruff.
local venv_resolve = {}
-- Shared async venv-resolution state, keyed by root_dir. nil = not requested;
-- {pending={cb...}} = subprocess in flight (calllers queued); {python_path=...,
-- venv_dir=...} = resolved and cached for reuse by pyright + ruff.
local venv_resolve = {}
-- Shared async venv-resolution state, keyed by root_dir. nil = not requested;
-- {pending={cb...}} = subprocess in flight (calllers queued); {python_path=...,
-- venv_dir=...} = resolved and cached for reuse by pyright + ruff.
local venv_resolve = {}

local VENV_NAMES = { ".venv", "venv" }
local RUFF_DEFAULT_CMD = { "ruff", "server", "--preview" }
local PYRIGHT_DEFAULT_CMD = { "pyright-langserver", "--stdio" }

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

--- Find a binary in a local virtual environment under root_dir.
--- Checks .venv and venv in order, returning the first match.
local function find_local_venv_binary(root_dir, binary)
	for _, name in ipairs(VENV_NAMES) do
		local path = root_dir .. "/" .. name .. "/bin/" .. binary
		if vim.uv.fs_stat(path) then
			return path
		end
	end
end

--- Asynchronously resolve venv paths via package manager (uv/poetry).
--- For managed environments where the venv lives outside the project directory.
--- Calls callback(python_path, venv_dir) on success via vim.schedule.
---
--- Work is shared across callers (pyright + ruff) per root_dir: the first call
--- spawns the subprocess; concurrent callers queue onto the in-flight request
--- and later callers reuse the cached result, so the package manager is queried
--- at most once per project.
local function resolve_venv_async(root_dir, callback)
	local state = venv_resolve[root_dir]

	-- Already resolved: reuse the cached result without spawning a subprocess.
	if state and state.python_path then
		vim.schedule(function()
			callback(state.python_path, state.venv_dir)
		end)
		return
	end

	-- Request already in flight: queue onto it instead of spawning again.
	if state and state.pending then
		table.insert(state.pending, callback)
		return
	end

	local pkg_manager = detect_pkg_manager(root_dir)
	if not pkg_manager then
		return
	end

	venv_resolve[root_dir] = { pending = { callback } }
	vim.system(venv_path_cmd(pkg_manager), {
		cwd = root_dir,
		timeout = 2000,
	}, function(result)
		local pending = venv_resolve[root_dir].pending
		if result.code ~= 0 or not result.stdout then
			-- Clear so a later call can retry; queued callbacks are dropped.
			venv_resolve[root_dir] = nil
			return
		end

		local python_path = normalize_python_path(pkg_manager, result.stdout)
		local venv_dir = normalize_venv_dir(pkg_manager, result.stdout)
		if python_path and venv_dir then
			venv_resolve[root_dir] = { python_path = python_path, venv_dir = venv_dir }
			vim.schedule(function()
				for _, cb in ipairs(pending) do
					cb(python_path, venv_dir)
				end
			end)
		else
			venv_resolve[root_dir] = nil
		end
	end)
end

--- Apply a resolved venv_dir to the ruff server: look up the ruff binary, and
--- if found, swap the global ruff cmd, stop the running server, and retrigger
--- FileType so a new server spawns with the correct binary. Returns true if
--- the ruff binary was found and applied.
local function apply_ruff_venv(root_dir, venv_dir)
	local ruff_path = venv_dir .. "/bin/ruff"
	if not vim.uv.fs_stat(ruff_path) then
		return false
	end
	local cmd = { ruff_path, "server", "--preview" }
	ruff_cmd_cache[root_dir] = cmd
	vim.lsp.config("ruff", { cmd = cmd })
	for _, c in pairs(vim.lsp.get_clients({ name = "ruff" })) do
		if c.config.root_dir == root_dir then
			c:stop()
		end
	end
	vim.defer_fn(retrigger_python_ft, 100)
	return true
end

--- Apply a resolved venv_dir to the ruff server: look up the ruff binary, and
--- if found, swap the global ruff cmd, stop the running server, and retrigger
--- FileType so a new server spawns with the correct binary. Returns true if
--- the ruff binary was found and applied.
local function apply_ruff_venv(root_dir, venv_dir)
	local ruff_path = venv_dir .. "/bin/ruff"
	if not vim.uv.fs_stat(ruff_path) then
		return false
	end
	local cmd = { ruff_path, "server", "--preview" }
	ruff_cmd_cache[root_dir] = cmd
	vim.lsp.config("ruff", { cmd = cmd })
	for _, c in pairs(vim.lsp.get_clients({ name = "ruff" })) do
		if c.config.root_dir == root_dir then
			c:stop()
		end
	end
	vim.defer_fn(retrigger_python_ft, 100)
	return true
end

--- Apply a resolved venv_dir to the ruff server: look up the ruff binary, and
--- if found, swap the global ruff cmd, stop the running server, and retrigger
--- FileType so a new server spawns with the correct binary. Returns true if
--- the ruff binary was found and applied.
local function apply_ruff_venv(root_dir, venv_dir)
	local ruff_path = venv_dir .. "/bin/ruff"
	if not vim.uv.fs_stat(ruff_path) then
		return false
	end
	local cmd = { ruff_path, "server", "--preview" }
	ruff_cmd_cache[root_dir] = cmd
	vim.lsp.config("ruff", { cmd = cmd })
	for _, c in pairs(vim.lsp.get_clients({ name = "ruff" })) do
		if c.config.root_dir == root_dir then
			c:stop()
		end
	end
	vim.defer_fn(retrigger_python_ft, 100)
	return true
end

--- Re-trigger FileType on loaded Python buffers to restart LSP servers
local function retrigger_python_ft()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "python" then
			vim.api.nvim_exec_autocmds("FileType", { buffer = buf, modeline = false })
		end
	end
end

-- Resolve the project-local ruff binary before vim.lsp.enable() starts the
-- server. Unlike pyright (which only needs a pythonPath *setting* and can update
-- it on a running server via on_init + didChangeConfiguration), ruff requires
-- swapping the actual binary - the built-in `ruff server` runs analysis
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
		local ruff_path = find_local_venv_binary(root_dir, "ruff")
		if ruff_path then
			local cmd = { ruff_path, "server", "--preview" }
			ruff_cmd_cache[root_dir] = cmd
			vim.lsp.config("ruff", { cmd = cmd })
			return
		end

		-- No local ruff; reset to default to avoid leaking another project's binary
		vim.lsp.config("ruff", { cmd = RUFF_DEFAULT_CMD })
	end,
	desc = "Resolve project-local ruff binary before LSP server starts",
})

-- Resolve the project-local pyright-langserver binary before vim.lsp.enable()
-- starts the server. Mason's pyright and the project's `uv run pyright` can drift
-- (different bundled node runtime / patch level), and a mismatched langserver
-- against the project's venv produces phantom type errors. Pinning nvim to the
-- venv's pyright-langserver makes the editor run the exact same binary that
-- `uv run pyright` uses. Like ruff, the cmd must be swapped before spawn because
-- the langserver process is what performs analysis.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	group = vim.api.nvim_create_augroup("pyright_binary_resolve", { clear = true }),
	callback = function(args)
		local root_dir = vim.fs.root(args.buf, { "pyproject.toml", "setup.py", "setup.cfg", ".git" })
		if not root_dir then
			return
		end

		-- Already resolved for this project
		if pyright_cmd_cache[root_dir] then
			vim.lsp.config("pyright", { cmd = pyright_cmd_cache[root_dir] })
			return
		end

		-- Check local venv (synchronous, fast)
		local langserver_path = find_local_venv_binary(root_dir, "pyright-langserver")
		if langserver_path then
			local cmd = { langserver_path, "--stdio" }
			pyright_cmd_cache[root_dir] = cmd
			vim.lsp.config("pyright", { cmd = cmd })
			return
		end

		-- No venv pyright; reset to mason's default to avoid leaking another project's binary
		vim.lsp.config("pyright", { cmd = PYRIGHT_DEFAULT_CMD })
	end,
	desc = "Resolve project-local pyright-langserver binary before LSP server starts",
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
						local python = find_local_venv_binary(root_dir, "python")
						if python then
							venv_cache[root_dir] = python
							client.config.settings.python.pythonPath = python
							return
						end

						-- Fallback: detect managed environments where venv lives elsewhere
						resolve_venv_async(root_dir, function(python_path)
							venv_cache[root_dir] = python_path
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

						-- Shared async fallback: deduped with pyright, reuses the cached
						-- result if pyright already resolved the venv for this project.
						resolve_venv_async(root_dir, function(_, venv_dir)
							if not apply_ruff_venv(root_dir, venv_dir) then
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
