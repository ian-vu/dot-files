return {
  {
    -- Git diff view
    "sindrets/diffview.nvim",
    opts = function()
      local actions = require("diffview.actions")
      return {
        keymaps = {
          file_panel = {
            { "n", "<C-d>", actions.scroll_view(0.4), { desc = "Scroll down half page" } },
            { "n", "<C-u>", actions.scroll_view(-0.4), { desc = "Scroll up half page" } },
            { "n", "<C-f>", actions.scroll_view(0.8)({ desc = "Scroll down full page" }) },
            { "n", "<C-b>", actions.scroll_view(-0.8), { desc = "Scroll up full page" } },
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
                  vim.cmd("Git commit -m " .. '"' .. msg .. '"')
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
    -- Allow for opening files in github
    "almo7aya/openingh.nvim",
    opts = {},
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      defaults = {
        ["<leader>go"] = { name = "+open" },
      },
    },
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
    "tpope/vim-fugitive",
    opt = true,
    cmd = { "G", "Git" },
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
