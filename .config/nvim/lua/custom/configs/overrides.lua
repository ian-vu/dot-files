local M = {}

M.treesitter = {
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "c",
    "markdown",
    "markdown_inline",
    "python"
  },
  indent = {
    enable = true,
    -- disable = {
    --   "python"
    -- },
  },
}

M.mason = {
  ensure_installed = {
    -- lua stuff
    "lua-language-server",
    "stylua",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "deno",
    "prettier",

    -- c/cpp stuff
    "clangd",
    "clang-format",

    -- shell stuff
    "shfmt",

    --my own stuff
    --python stuff
    "pyright",
    "mypy",
    "black",
    "ruff",
    "debugpy"
  },
}

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = false,
  },

  filters = {
    dotfiles = true,
    custom = {
      'node_modules',
      -- Python related
      '.venv',
      '__pycache__',
      '.mypy_cache',
      '.pytest_cache'
    },
  },

  renderer = {
    root_folder_label = true,
    highlight_git = true,
    indent_markers = {
      enable = true,
    },
    icons = {
      show = {
        folder_arrow = false,
        git = true,
      },
      git_placement = "after",
      glyphs = {
        folder = {
          default = "",
          empty = "",
          empty_open = "",
          open = "",
          symlink = "",
          symlink_open = "",
          arrow_open = "",
          arrow_closed = "",
        },
      },
    }
  },
}

return M
