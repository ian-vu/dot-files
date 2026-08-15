return {
	"atiladefreitas/dooing",
	config = function()
		require("dooing").setup({
			-- Core settings
			save_path = vim.fn.stdpath("data") .. "/dooing_todos.json",
			pretty_print_json = false, -- Pretty-print JSON output (requires jq or python)

			-- Timestamp settings
			timestamp = {
				enabled = true, -- Show relative timestamps (e.g., @5m ago, @2h ago)
			},

			-- Interface style (see "Modern UI" below). Opt-in: the default keeps the
			-- original look, so updating never changes your interface.
			ui = {
				style = "modern", -- "classic" | "modern"
				sections = true, -- group top-level todos under status headings
				priority_bar = true, -- colored marker instead of coloring the whole row
				tree_connectors = true, -- draw ├─ / └─ / │ guides for nested tasks
				note_preview = true, -- first line of a todo's notes, dimmed, beneath it
				progress = true, -- progress bar in the title, summary in the footer
				compact_quick_keys = true, -- single strip instead of the tall quick keys panel
				section_titles = {
					in_progress = "IN PROGRESS",
					pending = "PENDING",
					done = "DONE",
				},
				icons = {
					priority_bar = "▎",
					overdue = "󰀦",
					progress_on = "▰",
					progress_off = "▱",
				},
			},

			-- Window settings
			window = {
				-- Size of the floating window; may also be a function returning a
				-- table with these keys (see "Adaptive Window Size" below)
				dimensions = {
					width = 55, -- Width of the floating window
					height = 20, -- Height of the floating window
				},
				border = "rounded", -- Border style: 'single', 'double', 'rounded', 'solid'
				zindex = 50, -- Base z-index for floating windows (uses zindex to zindex+5)
				position = "center", -- Window position: 'right', 'left', 'top', 'bottom', 'center',
				-- 'top-right', 'top-left', 'bottom-right', 'bottom-left'
				padding = {
					top = 1,
					bottom = 1,
					left = 2,
					right = 2,
				},
			},

			-- To-do formatting
			formatting = {
				pending = {
					icon = "○",
					format = { "icon", "notes_icon", "text", "due_date", "ect" },
				},
				in_progress = {
					icon = "◐",
					format = { "icon", "text", "due_date", "ect" },
				},
				done = {
					icon = "✓",
					format = { "icon", "notes_icon", "text", "due_date", "ect" },
				},
			},

			quick_keys = true, -- Quick keys window

			notes = {
				icon = "📓",
			},

			scratchpad = {
				syntax_highlight = "markdown",
			},

			-- Per-project todos
			per_project = {
				enabled = true, -- Enable per-project todos
				default_filename = "dooing.json", -- Default filename for project todos
				auto_gitignore = false, -- Auto-add to .gitignore (true/false/"prompt")
				on_missing = "prompt", -- What to do when file missing ("prompt"/"auto_create")
				auto_open_project_todos = false, -- Auto-open project todos on startup if they exist
			},

			-- Nested tasks
			nested_tasks = {
				enabled = true, -- Enable nested subtasks
				indent = 2, -- Spaces per nesting level
				retain_structure_on_complete = true, -- Keep nested structure when completing tasks
				move_completed_to_end = true, -- Move completed nested tasks to end of parent group
				inherit_priority = false, -- Inherit parent priorities and skip the priority prompt
			},

			-- Due date notifications
			due_notifications = {
				enabled = true, -- Enable due date notifications
				on_startup = true, -- Show notification on Neovim startup
				on_open = true, -- Show notification when opening todos
			},

			-- Keymaps
			keymaps = {
				toggle_window = "<leader>td", -- Toggle global todos
				open_project_todo = "<leader>tD", -- Toggle project-specific todos
				show_due_notification = "<leader>tN", -- Show due items window
				new_todo = "o",
				create_nested_task = "<leader>tn", -- Create nested subtask under current todo
				toggle_todo = "x",
				delete_todo = "d",
				delete_completed = "D",
				close_window = "q",
				undo_delete = "u",
				add_due_date = "H",
				remove_due_date = "X",
				toggle_help = "?",
				toggle_tags = "t",
				toggle_priority = "<Space>",
				clear_filter = "c",
				edit_todo = "r",
				edit_tag = "r",
				edit_priorities = "p",
				delete_tag = "d",
				search_todos = "/",
				add_time_estimation = "T",
				remove_time_estimation = "R",
				import_todos = "I",
				export_todos = "E",
				remove_duplicates = "<leader>D",
				open_todo_scratchpad = "<leader>p",
				refresh_todos = "f",
			},

			calendar = {
				language = "en",
				start_day = "sunday", -- or "monday"
				icon = "",
				keymaps = {
					previous_day = "h",
					next_day = "l",
					previous_week = "k",
					next_week = "j",
					previous_month = "H",
					next_month = "L",
					select_day = "<CR>",
					close_calendar = "q",
				},
			},

			-- Priority settings
			priorities = {
				{
					name = "important",
					weight = 4,
				},
				{
					name = "urgent",
					weight = 2,
				},
			},
			priority_groups = {
				high = {
					members = { "important", "urgent" },
					color = nil,
					hl_group = "DiagnosticError",
				},
				medium = {
					members = { "important" },
					color = nil,
					hl_group = "DiagnosticWarn",
				},
				low = {
					members = { "urgent" },
					color = nil,
					hl_group = "DiagnosticInfo",
				},
			},
			hour_score_value = 1 / 8,
			done_sort_by_completed_time = false,
		})
	end,
}
