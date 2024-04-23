return {
  {
    "epwalsh/obsidian.nvim",
    event = "VeryLazy",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
    --   "BufReadPre path/to/my-vault/**.md",
    --   "BufNewFile path/to/my-vault/**.md",
    -- },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",
      -- "hrsh7th/nvim-cmp",
      -- "nvim-telescope/telescope.nvim",
      -- "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      completion = {
        min_chars = 1,
      },
      workspaces = {
        {
          name = "obsidian",
          path = "~/obsidian",
        },
      },
      notes_subdir = "/",
      templates = {
        subdir = "03 Resources/obsidian/templates",
      },
      daily_notes = {
        folder = "04 Archive/daily-notes",
        template = "daily-note.md",
      },
      ui = {
        enable = false,
      },

      -- Sets the file name and id of new notes
      -- Override defualt which includes a timestamp
      note_id_function = function(title)
        return title
      end,

      -- `true` indicates that you don't want obsidian.nvim to manage frontmatter.
      -- ie. New notes won't have the top metadata section.
      disable_frontmatter = true,

      -- Optional, customize how wiki links are formatted. You can set this to one of:
      --  * "use_alias_only", e.g. '[[Foo Bar]]'
      --  * "prepend_note_id", e.g. '[[foo-bar|Foo Bar]]'
      --  * "prepend_note_path", e.g. '[[foo-bar.md|Foo Bar]]'
      --  * "use_path_only", e.g. '[[foo-bar.md]]'
      -- Or you can set it to a function that takes a table of options and returns a string, like this:
      wiki_link_func = function(opts)
        return require("obsidian.util").wiki_link_alias_only(opts)
      end,
    },
  },
}
