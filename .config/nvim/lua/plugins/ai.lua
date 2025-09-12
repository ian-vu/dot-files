return {
  {
    'supermaven-inc/supermaven-nvim',
    event = 'InsertEnter',
    enabled = true,
    opts = {
      keymaps = {
        accept_suggestion = '<Tab>',
        -- clear_suggestion = "<C-]>",
        -- accept_word = '<C-Tab>',
      },
      log_level = 'off',
    },
  },
}
