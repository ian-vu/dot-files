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
    -- Auto completion
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      }
    end,
  },
  {
    -- Allow for commenting
    "numToStr/Comment.nvim",
  },
  {
    -- Git diff view
    "sindrets/diffview.nvim",
    opts = function()
      local actions = require("diffview.actions")
      return {
        keymaps = {
          file_panel = {
            { "n", "j", actions.select_next_entry, { desc = "Open the diff for the next file" } },
            { "n", "k", actions.select_prev_entry, { desc = "Open the diff for the next file" } },
            {
              "n",
              "cc",
              function()
                vim.ui.input({ prompt = "Commit message: " }, function(msg)
                  if not msg then
                    return
                  end
                  local results = vim.cmd("Git commit -m " .. '"' .. msg .. '"')
                end)
              end,
            },
            {
              "n",
              "cC",
              "<Cmd>Git commit <bar> wincmd J<CR>",
              { desc = "Commit staged changes" },
            },
            {
              "n",
              "ca",
              "<Cmd>Git commit --amend <bar> wincmd J<CR>",
              { desc = "Amend the last commit" },
            },
            -- {
            --   "n",
            --   "cC",
            --   ':Git commit -m "',
            --   { desc = "Commit staged changes" },
            -- },
            -- {
            --   "n",
            --   "ca",
            --   "<cmd>Git commit --amend<CR>",
            --   { desc = "Amend the last commit" },
            -- },
            -- {
            --   "n",
            --   "cc",
            --   "<cmd>Git commit<CR>",
            --   { desc = "Commit staged changes in buffer" },
            -- },
          },
        },
      }
    end,
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {
      -- Show labels before the search word
      label = {
        before = true,
        after = false,
      },
      modes = {
        -- Disable flash for `/`
        search = { enabled = false },

        -- Disable flash when using `f`, `F`, `t`, `T`, `;` and `,` motions
        char = { enabled = false },
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        -- symbol = "▏",
        add = { text = "▏" },
        change = { text = "▏" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▏" },
        untracked = { text = "▏" },
      },
    },
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
  -- {
  --   "SuperBo/fugit2.nvim",
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --     "nvim-tree/nvim-web-devicons",
  --     "nvim-lua/plenary.nvim",
  --     {
  --       "chrisgrieser/nvim-tinygit",
  --       dependencies = { "stevearc/dressing.nvim" },
  --     },
  --   },
  --   opts = {},
  --   cmd = { "Fugit2", "Fugit2Graph" },
  -- },
  -- {
  --   "NeogitOrg/neogit",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim", -- required
  --     "sindrets/diffview.nvim", -- optional - Diff integration
  --
  --     -- Only one of these is needed, not both.
  --     "nvim-telescope/telescope.nvim", -- optional
  --   },
  --   config = true,
  -- },
}
