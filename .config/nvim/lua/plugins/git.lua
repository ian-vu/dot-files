return {
	{ -- Three-part diff viewer with a connector gutter that preserves each side's line numbers
		"CoreyKaylor/diffbandit.nvim", -- https://github.com/CoreyKaylor/diffbandit.nvim
		cmd = {
			"DiffBandit",
			"DiffBanditBuffers",
			"DiffBanditFolderDiff",
			"DiffBanditGit",
			"DiffBanditGitCurrent",
			"DiffBanditCommitPanel",
			"DiffBanditGitMenu",
			"DiffBanditGitLog",
			"DiffBanditGitCommit",
			"DiffBanditGitCompare",
			"DiffBanditGitCheckout",
			"DiffBanditMerge",
		},
		-- Mirrors the diffview.nvim workflow: ]q/[q for file entries, <leader>gc… for
		-- merge conflicts, commit panel sized like diffview's file_panel.
		opts = {
			git = {
				-- Match diffview's ]q/[q file-entry navigation (chunk nav stays ]c/[c).
				file_keys = { next = "]q", prev = "[q" },
				panel = {
					-- Match diffview's bottom file_panel height.
					commit_height = 12,
					keys = {
						-- Match diffview's `c` commit and `<S-a>` amend from the file panel.
						focus_commit = "c",
						toggle_amend = "A",
					},
				},
			},
			merge = {
				keys = {
					-- Match diffview's conflict chooser keys: ours / theirs / all.
					accept_local = "<leader>gco",
					accept_remote = "<leader>gct",
					accept_both = "<leader>gca",
					-- Closest analogue to diffview's <leader>gcA (accept everything).
					apply_non_conflicting = "<leader>gA",
				},
			},
		},
		config = function(_, opts)
			require("diffbandit").setup(opts)

			-- Colemak pane navigation inside diffbandit sessions.
			-- A session lays out ~9 windows (left/right source, number gutters,
			-- connector, headers, overviews), so plain wincmd h/l (the
			-- vim-tmux-navigator fallback) lands on gutter windows and feels like
			-- it cycles. Bind the colemak left/right nav keys directly to the
			-- session's source windows so Alt+h/Alt+i and <C-h>/<C-l> move cleanly
			-- between the two real panes, just like normal nvim splits.
			local db_state = require("diffbandit.state")
			local group = vim.api.nvim_create_augroup("DiffBanditColemakNav", { clear = true })

			vim.api.nvim_create_autocmd("WinEnter", {
				group = group,
				callback = function(args)
					local session = db_state.sessions[vim.api.nvim_get_current_tabpage()]
					if not session then
						return
					end
					local buf = args.buf
					if not vim.api.nvim_buf_is_valid(buf) then
						return
					end
					-- Re-resolve the live session on each keypress so maps left on a
					-- reused real-file buffer no-op once the session has closed.
					local function focus_side(side)
						local s = db_state.sessions[vim.api.nvim_get_current_tabpage()]
						local win = s and s[side]
						if win and vim.api.nvim_win_is_valid(win) then
							vim.api.nvim_set_current_win(win)
						end
					end
					local set = function(lhs, side)
						vim.keymap.set("n", lhs, function()
							focus_side(side)
						end, { buffer = buf, nowait = true, noremap = true, silent = true })
					end
					-- Colemak left/right → diffbandit source panes.
					set("<M-h>", "left_win")
					set("<M-i>", "right_win")
					set("<C-h>", "left_win")
					set("<C-l>", "right_win")
					-- <tab>/<s-tab> cycle changed files in a Git queue, mirroring octo/diffview.
					local function file_step(direction)
						local s = db_state.sessions[vim.api.nvim_get_current_tabpage()]
						if not s then
							return
						end
						if direction == "next" then
							s:goto_next_file()
						else
							s:goto_prev_file()
						end
					end
					vim.keymap.set("n", "<tab>", function()
						file_step("next")
					end, { buffer = buf, nowait = true, noremap = true, silent = true })
					vim.keymap.set("n", "<s-tab>", function()
						file_step("prev")
					end, { buffer = buf, nowait = true, noremap = true, silent = true })
				end,
			})
		end,
	},
	{ -- Adds git related signs to the gutter, as well as utilities for managing changes
		"lewis6991/gitsigns.nvim", -- https://github.com/lewis6991/gitsigns.nvim
		event = "BufRead",
		opts = {
			-- centered char "│"
			signs = {
				add = { text = "▕" },
				change = { text = "▕" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▕" },
				untracked = { text = "▕" },
			},
			signs_staged = {
				add = { text = "▕" },
				change = { text = "▕" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▕" },
				untracked = { text = "▕" },
			},
		},
	},
	{
		-- Git diff view
		"sindrets/diffview.nvim", -- https://github.com/sindrets/diffview.nvim
		event = "VeryLazy",
		-- Register commands before VeryLazy so external launchers can start Neovim
		-- directly in Diffview without racing plugin lazy-loading.
		cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
		opts = function()
			local actions = require("diffview.actions")
			return {
				enhanced_diff_hl = true,
				use_icons = true,
				default_args = {
					DiffviewOpen = { "--untracked-files=all", "--imply-local" },
					-- Compare history entries against the current local file so old revisions show their diff from the working tree.
					-- DiffviewFileHistory = { "--base=LOCAL" },
				},
				show_help_hints = false,
				keymaps = {
					view = {
						{ "n", "]q", actions.select_next_entry, { desc = "Open the diff for the next file" } },
						{ "n", "[q", actions.select_prev_entry, { desc = "Open the diff for the next file" } },
						{ "n", "<c-q>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
						{
							"n",
							"<leader>gco",
							actions.conflict_choose("ours"),
							{ desc = "Choose the OURS version of a conflict" },
						},
						{
							"n",
							"<leader>gct",
							actions.conflict_choose("theirs"),
							{ desc = "Choose the THEIRS version of a conflict" },
						},
						{
							"n",
							"<leader>gcb",
							actions.conflict_choose("base"),
							{ desc = "Choose the BASE version of a conflict" },
						},
						{
							"n",
							"<leader>gca",
							actions.conflict_choose("all"),
							{ desc = "Choose all the versions of a conflict" },
						},
						{
							"n",
							"dx",
							actions.conflict_choose("none"),
							{ desc = "Delete the conflict region" },
						},
						{
							"n",
							"<leader>gcO",
							actions.conflict_choose_all("ours"),
							{ desc = "Choose the OURS version of a conflict for the whole file" },
						},
						{
							"n",
							"<leader>gcT",
							actions.conflict_choose_all("theirs"),
							{ desc = "Choose the THEIRS version of a conflict for the whole file" },
						},
						{
							"n",
							"<leader>gcB",
							actions.conflict_choose_all("base"),
							{ desc = "Choose the BASE version of a conflict for the whole file" },
						},
						{
							"n",
							"<leader>gcA",
							actions.conflict_choose_all("all"),
							{ desc = "Choose all the versions of a conflict for the whole file" },
						},
					},
					file_panel = {
						{ "n", "<c-q>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
						{ "n", "<C-d>", actions.scroll_view(0.4), { desc = "Scroll down half page" } },
						{ "n", "<C-u>", actions.scroll_view(-0.4), { desc = "Scroll up half page" } },
						{ "n", "<C-f>", actions.scroll_view(0.8)({ desc = "Scroll down full page" }) },
						{ "n", "<C-b>", actions.scroll_view(-0.8), { desc = "Scroll up full page" } },
						{ "n", "]q", actions.select_next_entry, { desc = "Open the diff for the next file" } },
						{ "n", "[q", actions.select_prev_entry, { desc = "Open the diff for the next file" } },
						{ "n", "<cr>", actions.focus_entry, { desc = "Focus entry" } },
						{ "n", "<c-q>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
						{
							"n",
							"c",
							function()
								vim.ui.input({ prompt = "Commit message: " }, function(msg)
									if not msg then
										return
									end
									vim.cmd("Git commit -m " .. '"' .. msg .. '"')
								end)
							end,
						},
						{
							"n",
							"<S-c",
							"<Cmd>Git commit <bar> wincmd J<CR>",
							{ desc = "Commit staged changes" },
						},
						{
							"n",
							"<S-a>",
							"<Cmd>Git commit --amend <bar> wincmd J<CR>",
							{ desc = "Amend the last commit" },
						},
					},
					file_history_panel = {
						{ "n", "<c-q>", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
					},
				},
				view = {
					merge_tool = {
						layout = "diff3_horizontal",
					},
				},
				file_panel = {
					listing_style = "list", -- "list" or "tree"
					win_config = {
						position = "bottom",
						height = 12,
					},
				},
			}
		end,
	},
	{ -- bridging the gap between git and neovim
		"trevorhauter/gitportal.nvim", -- https://github.com/trevorhauter/gitportal.nvim
		event = "VeryLazy",
		opts = {},
	},
	{ -- github pull request pr
		"pwntester/octo.nvim", -- https://github.com/pwntester/octo.nvim
		requires = {
			"nvim-lua/plenary.nvim", -- https://github.com/nvim-lua/plenary.nvim
			"folke/snacks.nvim", -- https://github.com/folke/snacks.nvim
			"nvim-tree/nvim-web-devicons", -- https://github.com/nvim-tree/nvim-web-devicons
		},
		cmd = { "Octo" },
		config = function(_, opts)
			require("octo").setup(opts)

			-- gf in review diff buffers: open the file in the first tab
			vim.api.nvim_create_autocmd("BufEnter", {
				callback = function(args)
					local props = vim.b[args.buf].octo_diff_props
					if not props then
						return
					end
					vim.keymap.set("n", "gf", function()
						local line = vim.api.nvim_win_get_cursor(0)[1]
						vim.cmd("1tabnext")
						vim.cmd("edit " .. vim.fn.fnameescape(props.path))
						pcall(vim.api.nvim_win_set_cursor, 0, { line, 0 })
					end, { buffer = args.buf, desc = "Open file in first tab" })
				end,
			})
		end,
		opts = {
			picker = "snacks",
			use_local_fs = true,
			mappings_disable_default = true,
			mappings = {
				review_thread = {
					close_review_tab = { lhs = "<C-q>", desc = "close review tab" },
				},
				submit_win = {
					close_review_tab = { lhs = "<C-q>", desc = "close submit tab", mode = { "n", "i" } },
				},
				review_diff = {
					close_review_tab = { lhs = "<C-q>", desc = "close review tab" },
					select_next_entry = { lhs = "<tab>", desc = "move to next changed file" },
					select_prev_entry = { lhs = "<s-tab>", desc = "move to previous changed file" },
					add_review_comment = { lhs = "<leader>pc", desc = "add a new review comment", mode = { "n", "x" } },
					add_review_suggestion = {
						lhs = "<leader>ps",
						desc = "add a new review suggestion",
						mode = { "n", "x" },
					},
				},
				file_panel = {
					close_review_tab = { lhs = "<C-q>", desc = "close review tab" },
					select_next_entry = { lhs = "<tab>", desc = "move to next changed file" },
					select_prev_entry = { lhs = "<s-tab>", desc = "move to previous changed file" },
				},
			},
		},
	},
}
