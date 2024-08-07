return {
  {
    -- Git diff view
    "sindrets/diffview.nvim",
    opts = function()
      local actions = require("diffview.actions")
      return {
        enhanced_diff_hl = false,
        keymaps = {
          view = {
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          },
          file_panel = {
            {
              "n",
              " ",
              actions.toggle_stage_entry,
              { desc = "Stage / unstage the selected entry" },
            },
            { "n", "<C-d>", actions.scroll_view(0.4), { desc = "Scroll down half page" } },
            { "n", "<C-u>", actions.scroll_view(-0.4), { desc = "Scroll up half page" } },
            { "n", "<C-f>", actions.scroll_view(0.8)({ desc = "Scroll down full page" }) },
            { "n", "<C-b>", actions.scroll_view(-0.8), { desc = "Scroll up full page" } },
            { "n", "j", actions.select_next_entry, { desc = "Open the diff for the next file" } },
            { "n", "k", actions.select_prev_entry, { desc = "Open the diff for the next file" } },
            { "n", "<cr>", actions.focus_entry, { desc = "Focus entry" } },
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
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
            { "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
          },
        },
        view = {
          merge_tool = {
            layout = "diff3_horizontal",
          },
        },
        file_panel = {
          win_config = {
            position = "bottom",
            height = 12,
          },
        },
      }
    end,
  },
  {
    -- Allow for opening files in github
    "almo7aya/openingh.nvim",
    opts = {},
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        {
          mode = { "n", "v" },
          { "<leader>go", group = "open" },
        },
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
      current_line_blame_opts = {
        delay = 0,
      },
    },
  },
  {
    "tpope/vim-fugitive",
    opts = {},
    cmd = { "G", "Git" },
    config = function() end, -- do nothing as this is a vim plugin
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
  --
  -- { -- github pr
  --   "pwntester/octo.nvim",
  --   requires = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-telescope/telescope.nvim",
  --     "nvim-tree/nvim-web-devicons",
  --   },
  --   opts = {},
  -- },
  {
    "julienvincent/hunk.nvim",
    cmd = { "DiffEditor" },
    config = function()
      require("hunk").setup()
    end,
  },
}
