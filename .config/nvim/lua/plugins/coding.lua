return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    opts = {
      suggestion = { enabled = true },
      panel = { enabled = true },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
  },
  -- Use <tab> for completion and snippets (supertab)
  -- first: disable default <tab> and <s-tab> behavior in LuaSnip
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      return {}
    end,
  },
  {
    -- Auto completion
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdLineEnter" },
    dependencies = {
      "hrsh7th/cmp-cmdline",
    },
    keys = {
      { "<Tab>", false },
      { "<S-Tab>", false },
    },
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      }
      -- opts.completion.completeopt = "menu,noselect,preview"
      opts.completion.completeopt = "menu,menuone,select"
      opts.mapping = cmp.mapping.preset.insert({
        ["<Tab>"] = cmp.mapping.select_next_item(),
        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<S-CR>"] = cmp.config.disable,
        -- opts.mapping["<S-CR>"] = cmp.config.disable
      })
      -- Set up command line autocomplete
      -- https://www.reddit.com/r/neovim/comments/154822d/lazyvimnoice_way_to_automate_cmdhelp_input/
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          {
            name = "cmdline",
            option = {
              ignore_cmds = { "Man", "!" },
            },
          },
        }),
      })
    end,
  },
  {
    "nvim-neotest/neotest",
    opts = {
      status = { enabled = true, virtual_text = true },
      summary = {
        mappings = { expand_all = "E" },
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {

      -- fancy UI for the debugger
      {
        "rcarriga/nvim-dap-ui",
      -- stylua: ignore
      keys = {
        { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
        { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
      },
        opts = {
          mappings = { edit = "i" },
          layouts = {
            {
              elements = {
                {
                  id = "scopes",
                  size = 0.31,
                },
                {
                  id = "breakpoints",
                  size = 0.23,
                },
                {
                  id = "stacks",
                  size = 0.23,
                },
                {
                  id = "watches",
                  size = 0.23,
                },
              },
              position = "left",
              size = 50,
            },
            {
              elements = {
                {
                  id = "repl",
                  size = 0.5,
                },
                {
                  id = "console",
                  size = 0.5,
                },
              },
              position = "bottom",
              size = 20,
            },
          },
        },
        config = function(_, opts)
          -- setup dap config by VsCode launch.json file
          -- require("dap.ext.vscode").load_launchjs()
          local dap = require("dap")
          local dapui = require("dapui")
          dapui.setup(opts)
          dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open({})
          end
          dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close({})
          end
          dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close({})
          end
        end,
      },
    },
  },
  { "tpope/vim-fugitive", opt = true, cmd = { "G", "Git" } },
  {
    -- Update Code when making directory changes in NeoTree, see another config for annother file manager
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim",
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
}
