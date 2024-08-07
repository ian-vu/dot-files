return {
  {
    "supermaven-inc/supermaven-nvim",
    dependencies = {
      -- ensure this is loaded before supermaven to allow for <tab> keymap to work
      "hrsh7th/nvim-cmp",
    },
    opts = {
      keymaps = {
        accept_suggestion = "<Tab>",
        -- clear_suggestion = "<C-]>",
        accept_word = "<C-Tab>",
      },
      log_level = "off",
    },
  },
  { -- Copilot with only ghost
    "github/copilot.vim",
    enabled = false,
  },
  -- { -- copilot
  --   "zbirenbaum/copilot.lua",
  --   event = "InsertEnter",
  --   cmd = "Copilot",
  --   build = ":Copilot auth",
  --   opts = {
  --     suggestion = { enabled = false },
  --     panel = { enabled = false },
  --     filetypes = {
  --       yaml = true,
  --       markdown = true,
  --       help = true,
  --       gitcommit = true,
  --
  --       gitrebase = true,
  --       hgcommit = true,
  --       svn = true,
  --       cvs = true,
  --       ["."] = true,
  --     },
  --   },
  -- },
  -- -- copilot cmp source
  -- {
  --   "nvim-cmp",
  --   dependencies = {
  --     {
  --       "zbirenbaum/copilot-cmp",
  --       dependencies = "copilot.lua",
  --       opts = {},
  --       config = function(_, opts)
  --         local copilot_cmp = require("copilot_cmp")
  --         copilot_cmp.setup(opts)
  --         -- attach cmp source whenever copilot attaches
  --         -- fixes lazy-loading issues with the copilot cmp source
  --         require("lazyvim.util").lsp.on_attach(function(client)
  --           if client.name == "copilot" then
  --             copilot_cmp._on_insert_enter({})
  --           end
  --         end)
  --       end,
  --     },
  --   },
  --   ---@param opts cmp.ConfigSchema
  --   opts = function(_, opts)
  --     table.insert(opts.sources, 1, {
  --       name = "copilot",
  --       group_index = 1,
  --       priority = 100,
  --     })
  --   end,
  -- },
}
