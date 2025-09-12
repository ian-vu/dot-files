return {
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = function()
      -- local logo = [[
      --      ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z
      --      ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z
      --      ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z
      --      ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z
      --      ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║
      --      ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝
      -- ]]
      local logo = [[
 ███▄    █ ▓█████  ▒█████   ██▒   █▓ ██▓ ███▄ ▄███▓
 ██ ▀█   █ ▓█   ▀ ▒██▒  ██▒▓██░   █▒▓██▒▓██▒▀█▀ ██▒
▓██  ▀█ ██▒▒███   ▒██░  ██▒ ▓██  █▒░▒██▒▓██    ▓██░
▓██▒  ▐▌██▒▒▓█  ▄ ▒██   ██░  ▒██ █░░░██░▒██    ▒██ 
▒██░   ▓██░░▒████▒░ ████▓▒░   ▒▀█░  ░██░▒██▒   ░██▒
░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒░▒░▒░    ░ ▐░  ░▓  ░ ▒░   ░  ░
░ ░░   ░ ▒░ ░ ░  ░  ░ ▒ ▒░    ░ ░░   ▒ ░░  ░      ░
   ░   ░ ░    ░   ░ ░ ░ ▒       ░░   ▒ ░░      ░   
         ░    ░  ░    ░ ░        ░   ░         ░   
                                ░                  
      ]]
      --      local logo = [[
      -- ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
      -- ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
      -- ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
      -- ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
      -- ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
      -- ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
      --      ]]

      logo = string.rep("\n", 8) .. logo .. string.rep("\n", 3)
      local opts = {
        theme = "doom",
        hide = {
          -- this is taken care of by lualine
          -- enabling this messes up the actual laststatus setting after loading a file
          statusline = false,
        },
        config = {
          header = vim.split(logo, "\n"),
          -- stylua: ignore
          center = {
            { action = 'lua require("persistence").load()', desc = " Restore Session", icon = " ", key = "s"},
            { action = 'lua require("oil").open()',         desc = " Explorer",        icon = "󱏒 ", key = "e"},
            { action = "ene | startinsert",                 desc = " New file",        icon = " ", key = "n"},
            { action = "ObsidianToday",                     desc = " Today's note",    icon = "󰇈 ", key = "t"},
            { action = "ObsidianTomorrow",                  desc = " Tomorrow's note", icon = "󰇈 ", key = "T"},
            { action = "qa",                                desc = " Quit",            icon = " ", key = "q"},
          },
          footer = {},
          -- Show Neovim metadata
          -- footer = function()
          --   local stats = require("lazy").stats()
          --   local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          --   return { "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
          -- end,
        },
      }

      -- Set format
      for _, button in ipairs(opts.config.center) do
        button.desc = button.desc .. string.rep(" ", 41 - #button.desc)
        button.key_format = "{ %s }"
      end

      -- close Lazy and re-open when the dashboard is ready
      if vim.o.filetype == "lazy" then
        vim.cmd.close()
        vim.api.nvim_create_autocmd("User", {
          pattern = "DashboardLoaded",
          callback = function()
            require("lazy").show()
          end,
        })
      end

      return opts
    end,
  },
}
