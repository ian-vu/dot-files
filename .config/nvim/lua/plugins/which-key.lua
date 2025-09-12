return {
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'helix',
      spec = {
        {
          mode = { 'n', 'v' },
          { '<leader>cy', group = 'yank' },
          { '<leader>g', group = '[g]it' },
          { '<leader>gp', group = '[p]ull request' },
        },
      },
      filter = function(mapping)
        return not string.find(mapping.lhs or '', '<esc>', 1, true)
      end,
    },
  },
}
