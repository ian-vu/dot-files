return {
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    event = 'BufRead',
    opts = {
      signs = {
        add = { text = '│' },
        change = { text = '│' },
        delete = { text = '' },
        topdelete = { text = '' },
        changedelete = { text = '│' },
        untracked = { text = '│' },
      },
      signs_staged = {
        add = { text = '│' },
        change = { text = '│' },
        delete = { text = '' },
        topdelete = { text = '' },
        changedelete = { text = '│' },
        untracked = { text = '│' },
      },
    },
  },
  {
    -- Git diff view
    'sindrets/diffview.nvim',
    event = 'VeryLazy',
    opts = function()
      local actions = require 'diffview.actions'
      return {
        enhanced_diff_hl = false,
        keymaps = {
          view = {
            {
              'n',
              '<tab>',
              '<cmd>TmuxNavigateRight<cr>',
              { desc = 'Right pane' },
            },
            { 'n', ']q', actions.select_next_entry, { desc = 'Open the diff for the next file' } },
            { 'n', '[q', actions.select_prev_entry, { desc = 'Open the diff for the next file' } },
            { 'n', '<c-q>', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
            { 'n', '<s-tab>', nil }, -- disable shift tab
          },
          file_panel = {
            { 'n', '<c-q>', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
            -- {
            --   "n",
            --   " ",
            --   actions.toggle_stage_entry,
            --   { desc = "Stage / unstage the selected entry" },
            -- },
            { 'n', '<C-d>', actions.scroll_view(0.4), { desc = 'Scroll down half page' } },
            { 'n', '<C-u>', actions.scroll_view(-0.4), { desc = 'Scroll up half page' } },
            { 'n', '<C-f>', actions.scroll_view(0.8) { desc = 'Scroll down full page' } },
            { 'n', '<C-b>', actions.scroll_view(-0.8), { desc = 'Scroll up full page' } },
            { 'n', ']q', actions.select_next_entry, { desc = 'Open the diff for the next file' } },
            { 'n', '[q', actions.select_prev_entry, { desc = 'Open the diff for the next file' } },
            { 'n', 'n', actions.select_next_entry, { desc = 'Open the diff for the next file' } },
            { 'n', 'e', actions.select_prev_entry, { desc = 'Open the diff for the next file' } },
            { 'n', '<tab>', nil }, -- disable shift tab
            { 'n', '<cr>', actions.focus_entry, { desc = 'Focus entry' } },
            { 'n', '<c-q>', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
            {
              'n',
              'c',
              function()
                vim.ui.input({ prompt = 'Commit message: ' }, function(msg)
                  if not msg then
                    return
                  end
                  vim.cmd('Git commit -m ' .. '"' .. msg .. '"')
                end)
              end,
            },
            {
              'n',
              '<S-c',
              '<Cmd>Git commit <bar> wincmd J<CR>',
              { desc = 'Commit staged changes' },
            },
            {
              'n',
              '<S-a>',
              '<Cmd>Git commit --amend <bar> wincmd J<CR>',
              { desc = 'Amend the last commit' },
            },
          },
          file_history_panel = {
            { 'n', '<c-q>', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
            {
              'n',
              '<tab>',
              '<cmd>TmuxNavigateRight<cr>',
              { desc = 'Right pane' },
            },
          },
          option_panel = {
            {
              'n',
              '<tab>',
              '<cmd>TmuxNavigateRight<cr>',
              { desc = 'Right pane' },
            },
          },
        },
        view = {
          merge_tool = {
            layout = 'diff3_horizontal',
          },
        },
        file_panel = {
          win_config = {
            position = 'bottom',
            height = 12,
          },
        },
      }
    end,
  },
  { -- github pull request pr
    'pwntester/octo.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
      'folke/snacks.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    event = 'VeryLazy',
    opts = {
      picker = 'snacks',
      use_local_fs = true,
      mappings = {
        review_thread = {
          close_review_tab = { lhs = '<C-q>', desc = 'close review tab' },
        },
        submit_win = {
          close_review_tab = { lhs = '<C-q>', desc = 'close submit tab', mode = { 'n', 'i' } },
        },
        review_diff = {
          close_review_tab = { lhs = '<C-q>', desc = 'close review tab' },
          -- select_next_entry = { lhs = "<tab>", desc = "move to next changed file" },
          -- select_prev_entry = { lhs = "<s-tab>", desc = "move to previous changed file" },
          add_review_comment = { lhs = '<leader>gpc', desc = 'add a new review comment', mode = { 'n', 'x' } },
          add_review_suggestion = { lhs = '<leader>gps', desc = 'add a new review suggestion', mode = { 'n', 'x' } },
        },
        file_panel = {
          close_review_tab = { lhs = '<C-q>', desc = 'close review tab' },
        },
      },
    },
  },
}
