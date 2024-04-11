return {
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
        -- api_key_cmd = "op read op://kt76oi5s3tqjg54lvlolplvvaq/ywcqft6be3aw45ic3wirvts5su/password",
        api_key_cmd = 'age --decrypt --identity ~/.age/secret-key.txt ~/.age/encrypted/open-api-key.txt.age"',
      })
    end,
  },
  {
    -- Small pop up window that replaces go to <definition/typing/etc>
    "dnlhc/glance.nvim",
  },
  { -- add whichkey for glance
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      defaults = {
        ["<leader>cg"] = { name = "+goto" },
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
            style = "none", -- default is icon on left using `icon` | `underline`
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
              text = "󰙅",
              highlight = "Directory",
              text_align = "right",
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
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
  },
  {
    "folke/zen-mode.nvim",
    opts = {
      window = {
        backdrop = 0.90,
      },
      plugins = {
        options = {
          -- Disable status line = 0
          -- Enable status line = 3
          laststatus = 3,
          showcmd = false, -- disables the command in the last line of the screen
        },
        tmux = { enabled = false }, -- set to true to disable tmux
      },
    },
  },
  -- {
  --   "mg979/vim-visual-multi",
  --   branch = "master",
  --   init = function()
  --     vim.g.VM_maps = {
  --       ["Find Under"] = "<C-S-d>",
  --       ["Find Subword Under"] = "<C-S-d>",
  --     }
  --   end,
  -- },
  {
    "mbbill/undotree",
    event = "BufRead",
    config = function()
      vim.g.undotree_WindowLayout = 3
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.g.undotree_TreeNodeShape = ""
      vim.g.undotree_DiffpanelHeight = 20
      vim.g.undotree_SplitWidth = 40
    end,
  },
}
