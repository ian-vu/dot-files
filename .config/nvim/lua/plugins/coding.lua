return {
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
    version = false, -- last release is way too old
    event = { "InsertEnter", "CmdLineEnter" },
    dependencies = {
      "hrsh7th/cmp-cmdline",
    },
    keys = {
      { "<Tab>", false },
      { "<S-Tab>", false },
      { "<CR>", false },
      { "<S-CR>", false },
    },
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.experimental.ghost_text = false
      opts.window = {
        -- completion = cmp.config.window.bordered(),
        -- documentation = cmp.config.window.bordered(),
      }
      -- opts.completion.completeopt = "menu,noselect,preview"
      opts.completion.completeopt = "menu,menuone,noselect"
      opts.mapping = cmp.mapping.preset.insert({
        -- ["<CR>"] = cmp.mapping.confirm({ select = true, behaviour = cmp.ConfirmBehavior.Replace }),
        ["<CR>"] = cmp.mapping.confirm({ select = false, behaviour = cmp.ConfirmBehavior.Replace }),
        -- ["<Tab>"] = cmp.mapping.confirm({ select = true, behaviour = cmp.ConfirmBehavior.Replace }),
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
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
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
          mappings = {
            edit = "i", --replaces the default `e` which clashes with colemak
          },
          layouts = {
            {
              elements = {
                { id = "stacks", size = 0.23 },
                { id = "scopes", size = 0.31 },
                { id = "watches", size = 0.23 },
                { id = "breakpoints", size = 0.23 },
              },
              position = "left",
              size = 50,
            },
            {
              elements = {
                { id = "repl", size = 0.9 },
                { id = "console", size = 0.1 },
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
