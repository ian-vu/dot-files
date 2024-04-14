return {
  {
    "epwalsh/obsidian.nvim",
    event = "VeryLazy",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = false,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
    --   "BufReadPre path/to/my-vault/**.md",
    --   "BufNewFile path/to/my-vault/**.md",
    -- },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",
      -- "hrsh7th/nvim-cmp",
      -- "nvim-telescope/telescope.nvim",
      -- "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      notes_subdir = "neovim",
      completion = {
        min_chars = 2,
      },
      workspaces = {
        {
          name = "obsidian",
          path = "/Users/ivu/Library/Mobile Documents/com~apple~CloudDocs/obsidian",
        },
      },
    },
  },
}
