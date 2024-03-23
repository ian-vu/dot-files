return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = "Neotree",
  keys = {
    { "<leader>fe", false },
    { "<leader>fE", false },
    { "<leader>e", false },
    { "<leader>E", false },
  },
  opts = {
    enable_normal_mode_for_inputs = true,
    enable_diagnostics = false,
    enable_git_status = true,
    popup_border_style = "rounded",
    filesystem = {
      filtered_items = {
        hide_gitignored = false,
        always_show = { ".github", ".docker" },
        never_show = { "venv", ".venv", ".git", "node_modules", ".cache", ".DS_Store", "__pycache__" },
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
      width = "40",
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
}
