return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = false,
    branch = "v3.x",
    cmd = "Neotree",
    keys = {
      { "<leader>fe", false },
      { "<leader>fE", false },
      { "<leader>e", false },
      { "<leader>E", false },
    },
    opts = {
      -- This got deprecated
      -- enable_normal_mode_for_inputs = true,
      enable_diagnostics = false,
      enable_git_status = true,
      popup_border_style = "rounded",
      filesystem = {
        filtered_items = {
          hide_gitignored = false,
          hide_by_name = { "venv", ".venv", ".git", "node_modules" },
          always_show = { ".github", ".docker", ".config", ".zshrc" },
          never_show = { ".cache", ".DS_Store", "__pycache__" },
          never_show_by_pattern = { ".*_cache" },
          follow_current_file = {
            enabled = true,
            leave_dirs_open = false,
          },
        },
      },
      default_component_configs = {
        icon = {
          folder_open = "",
          folder_closed = "",
          folder_empty = "",
          fole = "",
        },
        git_status = {
          symbols = {
            -- Change type
            added = "", -- or "✚", but this is redundant info if you use git_status_colors on the name
            modified = "", -- or "", but this is redundant info if you use git_status_colors on the name
            deleted = "", -- this can only be used in the git_status source
            renamed = "", -- this can only be used in the git_status source
            -- Status type
            untracked = "",
            ignored = "",
            unstaged = "",
            staged = "",
            conflict = "",
          },
        },
        indent = {
          with_expanders = false,
        },
        file_size = { enabled = false },
        type = { enabled = false },
        last_modified = { enabled = false },
        created = { enabled = false },
        name = { trailing_slash = false },
      },
      window = {
        width = "35",
        -- min_width = 40,
        -- max_width = 60,
        mappings = {
          ["s"] = "open_split",
          ["v"] = "open_vsplit",
          ["o"] = { command = "open", nowait = true },
          [";"] = { command = "open", nowait = true },
          ["E"] = { command = "expand_all_nodes", nowait = true },
          ["c"] = { command = "close_all_subnodes", nowait = true },
          ["C"] = { command = "close_all_nodes", nowait = true },
          -- ["n"] = { command = "j", nowait = true },
          -- ["e"] = { command = "k", nowait = true },
          ["n"] = function(_)
            vim.cmd("norm!j")
          end,
          ["e"] = function(_)
            vim.cmd("norm!k")
          end,
        },
      },
      buffers = {
        window = {
          mappings = {
            ["x"] = "buffer_delete",
          },
        },
      },
    },
  },
  {
    "stevearc/oil.nvim",
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      -- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
      -- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
      -- Additionally, if it is a string that matches "actions.<name>",
      -- it will use the mapping at require("oil.actions").<name>
      -- Set to `false` to remove a keymap
      -- See :help oil-actions for a list of all available actions
      keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<S-s>"] = "actions.select_vsplit",
        -- ["<C-h>"] = "actions.select_split",
        ["<C-s>"] = {
          callback = function()
            require("oil").save()
          end,
        },
        ["<C-h>"] = false,
        ["<C-t>"] = "actions.select_tab",
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["<C-l>"] = "actions.refresh",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
        ["g\\"] = "actions.toggle_trash",
        -- custom keymaps

        ["<C-f>"] = "actions.preview_scroll_down",
        ["<C-b>"] = "actions.preview_scroll_up",
      },
      -- Buffer-local options to use for oil buffers
      buf_options = {
        buflisted = true,
        bufhidden = "hide",
      },
      view_options = {
        show_hidden = true,
      },
      float = {
        padding = 3,
      },
      -- Send deleted files to the trash instead of permanently deleting them (:help oil-trash)
      delete_to_trash = true,
      preview = {
        min_width = { 100, 0.8 },
      },
      -- Set to true to watch the filesystem for changes and reload oil
      watch_for_changes = true,
    },
  },
}
