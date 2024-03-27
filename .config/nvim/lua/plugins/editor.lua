return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>/", false },
    },
    opts = {
      defaults = {
        layout_config = {
          prompt_position = "top",
          vertical = { width = 0.1 },
          horizontal = { preview_width = 0.5 },
        },
        results_title = false,
        path_display = { "truncate" }, -- Clip the path if too long, always showing the file name
        dynamic_preview_title = true, -- Show title of file in preview window at top
        scroll_strategy = "limit", -- Don't cycle to top of list when reaching bottom
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
  {
    -- Show underline of current words under cursor
    "RRethy/vim-illuminate",
    event = "LazyFile",
    opts = {
      delay = 100,
    },
  },
  {
    -- Allow for commenting
    "numToStr/Comment.nvim",
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      menu = {
        width = vim.api.nvim_win_get_width(0) - 4,
      },
      settings = {
        -- Save when changes to UI without needing to :w
        save_on_toggle = true,
        sync_on_ui_close = true,
        mark_branch = true, -- set marks specific to each git branch inside git repository
        tabline = false, -- enable tabline with harpoon marks
      },
    },
  },
  -- {
  --   "rmagatti/auto-session",
  --   config = function(_, opts)
  --     require("auto-session").setup(opts)
  --   end,
  -- },
  {
    "jackMort/ChatGPT.nvim",
    enabled = false,
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("chatgpt").setup({
        api_key_cmd = "op read op://kt76oi5s3tqjg54lvlolplvvaq/ywcqft6be3aw45ic3wirvts5su/password",
      })
    end,
  },
  {
    -- Small pop up window that replaces go to <definition/typing/etc>
    "dnlhc/glance.nvim",
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      defaults = {
        ["<leader>g"] = { name = "+glance" },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = function()
      local bufferline = require("bufferline")
      return {
        options = {
          hightlights = {
            tab_separator = {
              underline = "blue",
            },
          },
          diagnostics = false,
          indicator = {
            style = "underline", -- default is icon on left
          },
          show_buffer_icons = false,
          show_close_icon = false,
          show_buffer_close_icon = false,
          hover = {
            enabled = true,
            delay = 100,
            reveal = { "close" },
          },
          sort_by = "insert_at_end",
          style_preset = { bufferline.style_preset.no_italic },
          offsets = {
            {
              filetype = "neo-tree",
              text = "",
              highlight = "Directory",
              text_align = "left",
            },
            {
              filetype = "Diffview",
              text = "",
              highlight = "Directory",
              text_align = "left",
            },
          },
        },
      }
    end,
  },
  {
    "diegoulloao/nvim-file-location",
    opts = {
      keymap = "<leader>cyf",
      mode = "workdir",
      add_line = false,
      add_column = false,
      default_register = "*",
    },
    keys = {
      {
        "<leader>cyf",
        "<cmd>lua NvimFileLocation.copy_file_location('workdir', false, false)<cr>",
        desc = "Yank file path from cwd",
      },
      {
        "<leader>cyF",
        "<cmd>lua NvimFileLocation.copy_file_location('absolute', false, false)<cr>",
        desc = "Yank file path from cwd",
      },
    },
  },
  {
    -- add signature for nvim-file-location
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      defaults = {
        mode = { "n", "v" },
        ["<leader>cy"] = { name = "+yank" },
      },
    },
  },
}
