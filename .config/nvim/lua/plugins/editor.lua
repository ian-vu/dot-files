return {
  { -- illuminate word under cursor
    'RRethy/vim-illuminate',
    enable = false,
    event = 'BufRead',
    opts = {
      delay = 50,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { 'lsp' },
      },
    },
    config = function(_, opts)
      require('illuminate').configure(opts)
    end,
  },
  {
    'NMAC427/guess-indent.nvim', -- Detect tabstop and shiftwidth automatically
    enabled = false,
    event = 'BufRead',
  },
  { -- Navigate between tmux panes
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
    },
  },
  -- Highlight todo, notes, etc in comments
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },
  { -- Easy commenting to be used with keymaps
    'numToStr/Comment.nvim',
    event = 'BufRead',
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },
  {
    'folke/flash.nvim',
    enabled = true,
    event = 'VeryLazy',
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
  { -- undo history
    'mbbill/undotree',
    event = 'BufRead',
    config = function()
      vim.g.undotree_WindowLayout = 3
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.g.undotree_TreeNodeShape = ''
      vim.g.undotree_DiffpanelHeight = 20
      vim.g.undotree_SplitWidth = 40
    end,
  },
  {
    'folke/trouble.nvim',
    -- lazy = false,
    -- optional = true,
    opts = {
      win = {
        -- input = {
        --   keys = {
        --     ['<c-t>'] = {
        --       'trouble_open',
        --       mode = { 'n', 'i' },
        --     },
        --   },
        -- },
        size = 0.3,
      },
    },
    cmd = 'Trouble',
  },
  { -- cycle through paste | yank history
    'gbprod/yanky.nvim',
    event = 'BufRead',
    enabled = true,
    dependencies = {
      { 'kkharji/sqlite.lua' },
    },
    opts = {
      highlight = { timer = 200 },
      ring = { storage = 'sqlite' },
    },
    keys = {
      {
        '<leader>sp',
        function()
          Snacks.picker.yanky { layout = { preset = 'dropdown' } }
        end,
        mode = { 'n', 'x' },
        desc = 'Open Yank History',
      },
      { '<c-p>', '<Plug>(YankyPreviousEntry)', mode = { 'n', 'x' }, desc = 'Yanky previous entry' },
      { '<leader>p', '<Plug>(YankyPreviousEntry)', mode = { 'n', 'x' }, desc = 'Yanky previous entry' },

      -- Below is commented out because shift is not working
      -- { "<c-s-p>", "<Plug>(YankyPreviousEntry)", mode = { "n", "x" }, desc = "Yanky previous entry" },
      { 'y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank Text' },
      { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' }, desc = 'Put Yanked Text After Cursor' },
      { 'P', '<Plug>(YankyPutBefore)', mode = { 'n', 'x' }, desc = 'Put Yanked Text Before Cursor' },
      { 'gp', '<Plug>(YankyGPutAfter)', mode = { 'n', 'x' }, desc = 'Put Yanked Text After Selection' },
      { 'gP', '<Plug>(YankyGPutBefore)', mode = { 'n', 'x' }, desc = 'Put Yanked Text Before Selection' },
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
      { '=p', '<Plug>(YankyPutAfterFilter)', desc = 'Put After Applying a Filter' },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = 'BufRead',
    opts = {
      multiwindow = true,
      seperator = '~',
    },
    config = function(_, opts)
      require('treesitter-context').setup(opts)
      -- vim.cmd 'hi TreesitterContext None'
      -- vim.cmd("hi TreesitterContextBottom gui=underline guisp=Grey")
      -- vim.cmd 'hi TreesitterContextLineNumberBottom gui=underline guisp=Grey'
    end,
  },
  { -- better quick fix qflist
    'stevearc/quicker.nvim',
    event = 'FileType qf',
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {},
  },
}
