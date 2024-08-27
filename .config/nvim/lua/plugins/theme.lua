return {
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "rose-pine-moon",
      -- colorscheme = "catppuccin-mocha",
      -- colorscheme = "gruvbox",
      -- colorscheme = "gruvbox-material",
    },
  },
  {
    "f-person/auto-dark-mode.nvim",
    enabled = true,
    opts = {
      update_interval = 5000,
      set_dark_mode = function()
        vim.api.nvim_set_option_value("background", "dark", { scope = "global" })
      end,
      set_light_mode = function()
        vim.api.nvim_set_option_value("background", "light", { scope = "global" })
      end,
    },
  },
  {
    "ellisonleao/gruvbox.nvim",
    enabled = false,
    priority = 1000,
    config = function() end,
    opts = {
      inverse = true,
    },
  },
  {
    "sainnhe/gruvbox-material",
    priority = 1000,
    config = function()
      -- vim.cmd("set background=light")
      -- vim.cmd("set background=dark")
      vim.cmd("let g:gruvbox_material_background = 'hard'") -- soft | medium | hard
      vim.cmd("let g:gruvbox_material_foreground = 'mix'") -- material | mix | original
      -- vim.cmd("let g:gruvbox_material_transparent_background = 2")
      -- vim.cmd("let g:gruvbox_material_better_performance = 1")
      vim.cmd("let g:gruvbox_material_enable_bold = 0")
      vim.cmd("let g:gruvbox_material_enable_italic = 1")
      -- vim.cmd("let g:gruvbox_material_dim_inactive_windows = 1")
      -- vim.cmd("let g:gruvbox_material_visual = 'blue background'")
      vim.cmd("let g:gruvbox_material_spell_foreground = 1")
      -- vim.cmd("let g:gruvbox_material_diagnostic_text_highlight = 1")
      vim.cmd("let g:gruvbox_material_diagnostic_virtual_text = 'colored'") -- 'highlighted' for extra
      -- How to highlight the current cursor word
      vim.cmd("let g:gruvbox_material_current_word = 'grey background'") -- 'underline' or 'grey background'
      vim.cmd("colorscheme gruvbox-material")
    end,
    opts = {
      inverse = true,
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
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        telescope = false,
        treesitter = true,
        treesitter_context = true,
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
