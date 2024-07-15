return {
  {
    "vhyrro/luarocks.nvim",
    enabled = false,
    priority = 1000,
    config = true,
    opts = {
      rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
    },
  },
  {
    "rest-nvim/rest.nvim",
    ft = "http",
    enabled = false,
    dependencies = { "luarocks.nvim" },
    opts = {
      result = {
        split = {
          horizontal = true,
        },
      },
    },
    config = function(_, opts)
      require("rest-nvim").setup(opts)
    end,
    -- config = function(_, opts)
    --   require("rest").setup(opts)
    -- end,
    keys = {
      { "<leader>rr", "<cmd>Rest run<cr>", "Run request under cursor" },
      { "<leader>rl", "<cmd>Rest run<cr>", "Run last request" },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "http" })
      end
    end,
  },
}
