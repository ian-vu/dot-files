return {
  -- cool animations
  {
    "eandrju/cellular-automaton.nvim",
  },
  {
    "RRethy/vim-illuminate",
    event = "LazyFile",
    opts = {
      delay = 50,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { "lsp" },
      },
    },
    config = function(_, opts)
      require("illuminate").configure(opts)
    end,
  },
  {
    -- this is configured in lazyVim after vim-iluminate
    "neovim/nvim-lspconfig",
    opts = { document_highlight = { enabled = false } },
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
    enabled = false,
  },
  {
    "akinsho/bufferline.nvim",
    enabled = false,
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
          -- Below doesn't seem to work
          -- custom_filter = function(buf_number, buf_numbers)
          --   if vim.bo.filetype ~= "dashboard" then
          --     return true
          --   end
          --   if vim.bo[buf_number].filetype ~= "dashboard" then
          --     return true
          --   end
          -- end,
        },
      }
    end,
  },
  {
    "diegoulloao/nvim-file-location",
    -- dir = "/Users/ivu/dev/git/nvim-file-location",
    -- init = function()
    --   require("nvim-file-location").setup()
    -- end,
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
    "folke/which-key.nvim",
    optional = true,
    event = "VeryLazy",
    opts = {
      spec = {
        {
          mode = { "n", "v" },
          { "<leader>cy", group = "yank" },
        },
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
  -- {
  --   "echasnovski/mini.animate",
  --   version = "*",
  --   opts = {},
  -- },
  --
  -- better yank/paste
  {
    "gbprod/yanky.nvim",
    enabled = false,
    dependencies = not LazyVim.is_win() and { "kkharji/sqlite.lua" } or {},
    opts = {
      highlight = { timer = 200 },
      ring = { storage = LazyVim.is_win() and "shada" or "sqlite" },
    },
    keys = {
        -- stylua: ignore
      { "<leader>sp", function() require("telescope").extensions.yank_history.yank_history({ }) end, desc = "Paste History" },
      { "<c-p>", "<Plug>(YankyPreviousEntry)", mode = { "n", "x" }, desc = "Yanky previous entry" },
      { "<c-s-p>", "<Plug>(YankyNextEntry)", mode = { "n", "x" }, desc = "Yanky previous entry" },
      -- Below is commented out because shift is not working
      -- { "<c-s-p>", "<Plug>(YankyPreviousEntry)", mode = { "n", "x" }, desc = "Yanky previous entry" },
      { "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank Text" },
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put Yanked Text After Cursor" },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put Yanked Text Before Cursor" },
      { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put Yanked Text After Selection" },
      { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put Yanked Text Before Selection" },
      -- { "[y", "<Plug>(YankyCycleForward)", desc = "Cycle Forward Through Yank History" },
      -- { "]y", "<Plug>(YankyCycleBackward)", desc = "Cycle Backward Through Yank History" },
      -- { "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After Cursor (Linewise)" },
      -- { "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before Cursor (Linewise)" },
      -- { "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After Cursor (Linewise)" },
      -- { "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before Cursor (Linewise)" },
      -- { ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and Indent Right" },
      -- { "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and Indent Left" },
      -- { ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put Before and Indent Right" },
      -- { "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put Before and Indent Left" },
      { "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put After Applying a Filter" },
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
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      action_keys = {
        -- remove `<tab>` from default list
        jump = { "<cr>", "<2-leftmouse>" }, -- jump to the diagnostic or open / close folds
      },
    },
  },
  {
    "hedyhli/outline.nvim",
    opts = {
      outline_window = {
        position = "right",
        width = 35,
        relative_width = false, -- set to true for % based width. false for fixed integer width
      },
      preview_window = {
        auto_preview = false,
      },
      keymaps = {
        close = "q",
        toggle_preview = "<c-p>",
        unfold = "i",
        fold_all = "H",
        unfold_all = "I",
        -- Move down/up by one line and peek_location immediately.
        -- You can also use outline_window.auto_jump=true to do this for any
        -- j/k/<down>/<up>.
        down_and_jump = "<C-n>",
        up_and_jump = "<C-e>",
      },
    },
  },

  { -- Show gutter motion hints
    "tris203/precognition.nvim",
    enabled = false,
    --event = "VeryLazy",
    config = {
      -- startVisible = true,
      -- showBlankVirtLine = true,
      -- highlightColor = { link = "Comment" },
      -- hints = {
      --      Caret = { text = "^", prio = 2 },
      --      Dollar = { text = "$", prio = 1 },
      --      MatchingPair = { text = "%", prio = 5 },
      --      Zero = { text = "0", prio = 1 },
      --      w = { text = "w", prio = 10 },
      --      b = { text = "b", prio = 9 },
      --      e = { text = "e", prio = 8 },
      --      W = { text = "W", prio = 7 },
      --      B = { text = "B", prio = 6 },
      --      E = { text = "E", prio = 5 },
      -- },
      -- gutterHints = {
      --     G = { text = "G", prio = 10 },
      --     gg = { text = "gg", prio = 9 },
      --     PrevParagraph = { text = "{", prio = 8 },
      --     NextParagraph = { text = "}", prio = 8 },
      -- },
    },
  },

  { -- breadcrumbs
    "Bekaboo/dropbar.nvim",
    -- optional, but required for fuzzy finder support
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
    },

    opts = {
      icons = {
        enable = true,
        kinds = {
          symbols = {
            -- Array = "",
            -- Boolean = "",
            -- BreakStatement = "",
            -- Call = "",
            -- CaseStatement = "",
            -- Class = "",
            -- Color = "",
            -- Constant = "",
            -- Constructor = "",
            -- ContinueStatement = "",
            -- Copilot = "",
            -- Declaration = "",
            -- Delete = "",
            -- DoStatement = "",
            -- Enum = "",
            -- EnumMember = "",
            -- Event = "",
            -- Field = "",
            -- File = "",
            -- Folder = "",
            -- ForStatement = "",
            -- Function = "",
            -- H1Marker = "", -- Used by markdown treesitter parser
            -- H2Marker = "",
            -- H3Marker = "",
            -- H4Marker = "",
            -- H5Marker = "",
            -- H6Marker = "",
            -- Identifier = "",
            -- IfStatement = "",
            -- Interface = "",
            -- Keyword = "",
            -- List = "",
            -- Log = "",
            -- Lsp = "",
            -- Macro = "",
            -- MarkdownH1 = "", -- Used by builtin markdown source
            -- MarkdownH2 = "",
            -- MarkdownH3 = "",
            -- MarkdownH4 = "",
            -- MarkdownH5 = "",
            -- MarkdownH6 = "",
            -- Method = "",
            -- Module = "",
            -- Namespace = "",
            -- Null = "",
            -- Number = "",
            -- Object = "",
            -- Operator = "",
            -- Package = "",
            -- Pair = "",
            -- Property = "",
            -- Reference = "",
            -- Regex = "",
            -- Repeat = "",
            -- Scope = "",
            -- Snippet = "",
            -- Specifier = "",
            -- Statement = "",
            -- String = "",
            -- Struct = "",
            -- SwitchStatement = "",
            -- Terminal = "",
            -- Text = "",
            -- Type = "",
            -- TypeParameter = "",
            -- Unit = "",
            -- Value = "",
            -- Variable = "",
            -- WhileStatement = "",
          },
        },
      },
      bar = {
        debounce = 200,
      },
    },
  },
}
