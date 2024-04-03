return {
  -- { -- Audo dark mode
  --   "f-person/auto-dark-mode.nvim",
  --   config = {
  --     update_interval = 5000,
  --     set_dark_mode = function()
  --       vim.api.nvim_set_option("background", "dark")
  --       -- vim.cmd("colorscheme rose-pine-moon")
  --       vim.cmd("colorscheme tokyonight-storm")
  --     end,
  --     set_light_mode = function()
  --       vim.api.nvim_set_option("background", "light")
  --       -- vim.cmd("colorscheme rose-pine-dawn")
  --       vim.cmd("colorscheme tokyonight-day")
  --     end,
  --   },
  -- },
  {
    "echasnovski/mini.indentscope",
    enabled = false,
    opts = {
      draw = {
        -- Disable as it conflicts with Colemak keymaps
        -- mode = "background",
        delay = 0,
      },
      symbol = "│",
      mappings = {
        -- Disable as it conflicts with Colemak keymaps
        object_scope = "",
        object_scope_with_border = "",
        goto_top = "",
        goto_bottom = "",
      },
    },
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    enabled = false,
    opts = {
      indent = {
        -- left aligned
        -- char = "▏",
        -- tab_char = "▏",
        char = "│",
        tab_char = "│",
      },
      whitespace = {
        highlight = { "Whitespace" },
        remove_blankline_trail = true,
      },
    },
  },
  {
    "rcarriga/nvim-notify",
    opts = {
      fps = 60,
      render = "default",
      top_down = false,
      timeout = 1000,
    },
  },
  {
    "folke/noice.nvim",
    depends = { "hrsh7th/nvim-cmp.nvim" },
    opts = {
      -- cmdline = { view = "cmdline_popup" },
      -- messages = { enabled = true },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
          ["vim.lsp.util.stylize_markdown"] = false,
          ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp.nvim
        },
      },
      presets = {
        bottom_search = false, -- when using / or ?
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      plugins = { spelling = true },
      defaults = {
        -- defaults from LazyVim
        mode = { "n", "v" },
        ["g"] = { name = "+goto" },
        ["gs"] = { name = "+surround" },
        ["]"] = { name = "+next" },
        ["["] = { name = "+prev" },
        ["<leader><tab>"] = { name = "+tabs" },
        ["<leader>b"] = { name = "+buffer" },
        ["<leader>c"] = { name = "+code" },
        ["<leader>e"] = { name = "+explorer" },
        ["<leader>f"] = { name = "+file/find" },
        ["<leader>g"] = { name = "+git" },
        ["<leader>gh"] = { name = "+hunks" },
        ["<leader>q"] = { name = "+quit/session" },
        ["<leader>s"] = { name = "+search" },
        ["<leader>u"] = { name = "+ui" },
        ["<leader>w"] = { name = "+windows" },
        ["<leader>x"] = { name = "+diagnostics/quickfix" },
        -- extras
        ["<leader>h"] = { name = "+harpoon" },
      },
    },
  },
  {
    -- Highlight indent lines
    "shellRaining/hlchunk.nvim",
    event = { "UIEnter" },
    opts = {
      blank = {
        enable = false,
      },
      line_num = {
        enable = false,
      },
      chunk = {
        enable = true,
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          -- right_arrow = ">",
          right_arrow = "",
          -- right_arrow = "─",
        },
        style = "#806d9c",
      },
    },
  },
}
