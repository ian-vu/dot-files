return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "rose-pine-moon",
      colorscheme = "catppuccin",
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    -- config = function(_, opts)
    --   require("catppuccin").setup(opts)
    --   vim.cmd.colorscheme("catppuccino")
    -- end,
    opts = {
      integrations = {
        telescope = { enabled = false },
        neotree = true,
        noice = true,
        harpoon = true,
        which_key = true,
      },
    },
  },
  -- {
  --   "rose-pine/neovim",
  --   name = "rose-pine",
  --   opts = {
  --     enable = {
  --       legacy_highlights = false,
  --     },
  --     styles = {
  --       italic = false,
  --     },
  --     groups = {
  --       git_untracked = "rose",
  --     },
  --   },
  -- },
  -- {
  --   "rmehri01/onenord.nvim",
  -- },
  -- {
  --   "olimorris/onedarkpro.nvim",
  --   priority = 1000, -- Ensure it loads first
  -- },
}
