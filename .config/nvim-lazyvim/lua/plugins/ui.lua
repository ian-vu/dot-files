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
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      dashboard = { enabled = false },
      lazygit = { enabled = false },
      rename = { enabled = false },
      scratch = { enabled = false },
      terminal = { enabled = false },
      notifier = {
        top_down = false,
      },
    },
  },
  {
    "echasnovski/mini.indentscope",
    enabled = true,
    opts = function(_, opts)
      return {
        draw = {
          -- Disable as it conflicts with Colemak keymaps
          -- mode = "background",
          delay = 100,
          -- animation = require("mini.indentscope").gen_animation.none(),
          animation = require("mini.indentscope").gen_animation.none(),
        },
        symbol = "│",
        mappings = {
          -- Disable as it conflicts with Colemak keymaps
          object_scope = "",
          object_scope_with_border = "",
          goto_top = "",
          goto_bottom = "",
        },
      }
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    enabled = true,
    opts = {
      scope = {
        enabled = false,
        show_start = false,
        show_end = false,
      },
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
        -- highlight = { "Whitespace" },
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
      -- time to show notification
      timeout = 1250,
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
    -- Highlight indent lines
    "shellRaining/hlchunk.nvim",
    enabled = false,
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
          fg = "#686d43",
          -- fg = "#d5d6d3",
          -- { fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui") },
        },
        duration = 150,
        delay = 50,
      },
    },
  },
}
