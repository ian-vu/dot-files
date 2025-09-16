-- If you're using Ruff alongside another language server (like Pyright), you may want to defer to that language server for certain capabilities, like textDocument/hover:
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client == nil then
			return
		end
		if client.name == "ruff" then
			-- Disable hover in favor of Pyright
			client.server_capabilities.hoverProvider = false
		end
	end,
	desc = "LSP: Disable hover capability from Ruff",
})

return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				pyright = {
					single_file_support = true,
					on_new_config = function(new_config, new_root_dir)
						-- Initialize cache for poetry virtual environment paths
						vim.g.poetry_venv_cache = vim.g.poetry_venv_cache or {}

						-- Use cached python path if available to avoid shell call
						local cached_path = vim.g.poetry_venv_cache[new_root_dir]
						if cached_path then
							new_config.settings.python.pythonPath = cached_path
							return
						end

						-- Asynchronously detect poetry virtual environment (non-blocking)
						vim.system({ "poetry", "env", "info", "--path" }, {
							cwd = new_root_dir,
							timeout = 2000, -- Prevent hanging
						}, function(result)
							if result.code ~= 0 or not result.stdout then
								return
							end

							local venv_path = vim.trim(result.stdout)
							if venv_path == "" then
								return
							end

							local python_path = venv_path .. "/bin/python"
							-- Cache the result for future file opens in this project
							vim.g.poetry_venv_cache[new_root_dir] = python_path

							-- Update running pyright client with new python path
							vim.schedule(function()
								for _, client in pairs(vim.lsp.get_clients({ name = "pyright" })) do
									if client.config.root_dir == new_root_dir then
										client.config.settings.python.pythonPath = python_path
										client.notify(
											"workspace/didChangeConfiguration",
											{ settings = client.config.settings }
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
								-- typeCheckingMode = 'basic', -- 'basic' or 'strict' or 'off'
								autoImportCompletions = true,
								autoSearchPaths = true,
								diagnosticMode = "openFilesOnly",
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
	-- {
	--   'linux-cultist/venv-selector.nvim',
	--   lazy = false,
	--   dependencies = { 'neovim/nvim-lspconfig' },
	--   branch = 'main',
	--   cmd = 'VenvSelect',
	--   opts = {
	--     debug = true,
	--     name = { 'venv', '.venv', 'Env' },
	--     settings = {
	--       options = {
	--         notify_user_on_venv_activation = true,
	--       },
	--     },
	--   },
	--   --  Call config for python files and load the cached venv automatically
	--   ft = 'python',
	--   keys = { { '<leader>cv', '<cmd>:VenvSelect<cr>', desc = 'Select VirtualEnv', ft = 'python' } },
	-- },
}
