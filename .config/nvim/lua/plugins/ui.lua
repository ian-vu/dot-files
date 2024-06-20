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
    enabled = true,
    opts = {
      indent = {
        -- left aligned
        -- char = "▏",
        -- tab_char = "▏",
        -- char = "│",
        -- tab_char = "│",
        char = "┊",
        tab_char = "┊",
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
    dependencies = { "hrsh7th/nvim-cmp" },
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
        command_palette = false,
        bottom_search = false, -- when using / or ?
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
      cmdline = {
        opts = {
          position = { row = "10%", column = "50%" },
        },
        format = {
          cmdline = { pattern = "^:", icon = "", lang = "vim" },
          search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
          search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
          filter = { pattern = "^:%s*!", icon = "$", lang = "bash", title = " Bash " },
          lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = " ", lang = "lua" },
          input = {}, -- Used by input()
        },
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
      indent = {
        enable = false, -- disable since doesn't seem to be working. enabled lukas-reineke/indent-blankline.nvim instead
        chars = {
          -- "│",
          -- "¦",
          -- "┆",
          "┊",
        },
      },
      blank = {
        enable = false,
      },
      line_num = {
        enable = false,
      },
      chunk = {
        enable = true, -- Disable since it isn't working well with Gruvbox
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          -- right_arrow = ">",
          right_arrow = "",
          -- right_arrow = "─",
        },
        style = {
          -- fg = "#686d43",
          -- fg = "#d5d6d3",
          -- { fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui") },
        },
        duration = 150,
        delay = 50,
      },
    },
  },
}
