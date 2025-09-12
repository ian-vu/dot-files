return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>/", false },
    },
    opts = function(_, opts)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "TelescopeResults",
        callback = function(ctx)
          vim.api.nvim_buf_call(ctx.buf, function()
            vim.fn.matchadd("TelescopeParent", "\t\t.*$")
            vim.api.nvim_set_hl(0, "TelescopeParent", { link = "Comment" })
          end)
        end,
      })

      local function filenameFirst(_, path)
        local tail = vim.fs.basename(path)
        local parent = vim.fs.dirname(path)
        if parent == "." then
          return tail
        end
        return string.format("%s\t\t%s", tail, parent)
      end

      FILE_IGNORE_PATTERNS = {
        ".git",
        "node_modules",
        "node_modules",
        "package-lock.json",
        "venv",
        ".venv",
        "__pycache__",
        ".mypy_cache",
        ".pytest_cache",
        ".idea",
        "Env",
      }

      -- opts.pickers = vim.tbl_deep_extend("force", opts.pickers or {}, {
      --   find_files = {
      --     hidden = true,
      --     no_ignore = true,
      --     file_ignore_patterns = FILE_IGNORE_PATTERNS,
      --   },
      --   live_grep = {
      --     file_ignore_patterns = FILE_IGNORE_PATTERNS,
      --     additional_args = function(_)
      --       return { "--hidden" }
      --     end,
      --   },
      -- })

      local trouble = require("trouble.sources.telescope")
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      local custom_actions = {}

      -- Open quickfix list if multiple files are selected, otherwise open quickfix list with all results
      function custom_actions.maybe_multi_select_qlist_open(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        local num_selections = table.getn(picker:get_multi_selection())

        if num_selections > 1 then
          actions.send_selected_to_qflist(prompt_bufnr)
          actions.open_qflist()
        else
          actions.send_to_qflist()
          actions.open_qflist()
        end
      end

      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        -- layout_strategy = "vertical",
        layout_config = {
          prompt_position = "top",
          -- mirror = true,
          preview_cutoff = 10, -- ensure previewer is show unless less than this many lines
          vertical = { width = 0.1 },
          horizontal = { preview_width = 0.5 },
        },
        results_title = false,
        -- path_display = { "truncate" }, -- Clip the path if too long, always showing the file name
        path_display = filenameFirst,
        dynamic_preview_title = true, -- Show title of file in preview window at top
        -- Uncommenting the below causes issues with egrepify
        scroll_strategy = "limit", -- Don't cycle to top of list when reaching bottom
        sorting_strategy = "ascending",
        wrap_results = false,
        hl_result_eol = false,
        file_ignore_patterns = FILE_IGNORE_PATTERNS,
        mappings = {
          i = {
            ["<esc>"] = require("telescope.actions").close,
            ["<C-j>"] = require("telescope.actions").cycle_history_next,
            ["<C-n>"] = require("telescope.actions").cycle_history_next,
            ["<C-k>"] = require("telescope.actions").cycle_history_prev,
            ["<C-e>"] = require("telescope.actions").cycle_history_prev,
            ["<C-d>"] = require("telescope.actions").results_scrolling_down,
            ["<C-u>"] = require("telescope.actions").results_scrolling_up,
            ["<D-j>"] = require("telescope.actions").cycle_history_next,
            ["<D-n>"] = require("telescope.actions").cycle_history_next,
            ["<D-k>"] = require("telescope.actions").cycle_history_prev,
            ["<D-e>"] = require("telescope.actions").cycle_history_prev,
            ["<C-t>"] = trouble.open,
            ["<tab>"] = actions.toggle_selection + actions.move_selection_next,
            ["<s-tab>"] = actions.toggle_selection + actions.move_selection_previous,
            ["<C-q>"] = custom_actions.maybe_multi_select_qlist_open,
            ["<C-x>"] = require("telescope.actions").delete_buffer,
          },
        },
      })
    end,
  },
  {
    -- Allow for telescope plugin that groups results by files
    "fdschmidt93/telescope-egrepify.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").load_extension("egrepify")
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function()
      if LazyVim.pick.want() ~= "telescope" then
        return
      end
      local Keys = require("lazyvim.plugins.lsp.keymaps").get()
      -- stylua: ignore
      vim.list_extend(Keys, {
        { "gd", function() vim.lsp.buf.definition() end, desc = "Goto Definition", has = "definition" },
        { "gr", "<cmd>Telescope lsp_references<cr>", desc = "References", nowait = true },
        { "gI", function() require("telescope.builtin").lsp_implementations({ reuse_win = true }) end, desc = "Goto Implementation" },
        { "gy", function() require("telescope.builtin").lsp_type_definitions({ reuse_win = true }) end, desc = "Goto T[y]pe Definition" },
      })
    end,
  },
}
