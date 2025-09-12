return {
  {
    -- Garbage collector that stops inactive LSP clients to free RAM
    "zeioth/garbage-day.nvim",
    dependencies = "neovim/nvim-lspconfig",
    event = "VeryLazy",
    opts = {},
  },
}
