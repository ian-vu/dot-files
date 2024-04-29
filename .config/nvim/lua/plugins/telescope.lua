return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>/", false },
    },
    opts = {
      pickers = {
        find_files = {
          hidden = true,
        },
        live_grep = {
          file_ignore_patterns = { ".git", "node_modules", "venv", ".venv" },
          additional_args = function(_)
            return { "--hidden" }
          end,
        },
      },
      defaults = {
        layout_config = {
          prompt_position = "top",
          vertical = { width = 0.1 },
          horizontal = { preview_width = 0.5 },
        },
        results_title = false,
        path_display = { "truncate" }, -- Clip the path if too long, always showing the file name
        dynamic_preview_title = true, -- Show title of file in preview window at top
        -- Uncommenting the below causes issues with egrepify
        -- scroll_strategy = "limit", -- Don't cycle to top of list when reaching bottom
        sorting_strategy = "ascending",
        wrap_results = false,
        hl_result_eol = false,
        mappings = {
          i = {
            ["<esc>"] = require("telescope.actions").close,
            ["<C-j>"] = require("telescope.actions").cycle_history_next,
            ["<C-n>"] = require("telescope.actions").cycle_history_next,
            ["<C-k>"] = require("telescope.actions").cycle_history_prev,
            ["<C-e>"] = require("telescope.actions").cycle_history_prev,
            ["<D-j>"] = require("telescope.actions").cycle_history_next,
            ["<D-n>"] = require("telescope.actions").cycle_history_next,
            ["<D-k>"] = require("telescope.actions").cycle_history_prev,
            ["<D-e>"] = require("telescope.actions").cycle_history_prev,
          },
        },
      },
    },
  },
  {
    -- Allow for telescope plugin that groups results by files
    "fdschmidt93/telescope-egrepify.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").load_extension("egrepify")
    end,
  },
}
