return {
	{
		"CRAG666/code_runner.nvim", -- https://github.com/CRAG666/code_runner.nvim
		cmd = { "RunCode", "RunFile", "RunProject", "RunClose", "CRFiletype", "CRProjects" },
		keys = {
			{ "<leader>rr", "<cmd>RunCode<cr>", desc = "Run code" },
			{ "<leader>rf", "<cmd>RunFile<cr>", desc = "Run file" },
			{ "<leader>rF", "<cmd>RunFile float<cr>", desc = "Run file float" },
			{ "<leader>rt", "<cmd>RunFile tab<cr>", desc = "Run file tab" },
			{ "<leader>rp", "<cmd>RunProject<cr>", desc = "Run project" },
			{
				"<leader>rs",
				function()
					-- Scratch files live outside dotfiles so quick experiments do not pollute the repo.
					local scratch_dir = vim.fn.stdpath("data") .. "/scratch"
					vim.fn.mkdir(scratch_dir, "p")
					local scratch_file = string.format("%s/python-%s.py", scratch_dir, os.date("%Y%m%d-%H%M%S"))
					vim.cmd.edit(vim.fn.fnameescape(scratch_file))
					vim.bo.filetype = "python"
				end,
				desc = "New Python scratch",
			},
			{ "<leader>rx", "<cmd>RunClose<cr>", desc = "Close runner" },
		},
		opts = {
			mode = "term",
			startinsert = false,
			term = {
				position = "bot",
				size = 12,
			},
			float = {
				border = "rounded",
				height = 0.85,
				width = 0.85,
				x = 0.5,
				y = 0.5,
			},
			before_run_filetype = function()
				-- Always execute the latest buffer contents rather than the last saved version.
				vim.cmd("silent update")
			end,
			-- Run from the file's directory so scratchpads can use relative imports/data files.
			filetype = {
				python = "cd $dir && python3 -u $fileName",
				lua = "lua $file",
				sh = "bash $file",
				zsh = "zsh $file",
			},
		},
		config = function(_, opts)
			require("code_runner").setup(opts)
		end,
	},
}
