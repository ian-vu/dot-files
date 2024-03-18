-- Confuguration for neovide
-- https://neovide.dev/configuration.html
if vim.g.neovide then
  --Allow for copy and paste
  -- vim.keymap.set("n", "<D-s>", ":w<CR>") -- Save
  -- vim.keymap.set("v", "<D-c>", '"+y') -- Copy
  -- vim.keymap.set("n", "<D-v>", '"+P') -- Paste normal mode
  -- vim.keymap.set("v", "<D-v>", '"+P') -- Paste visual mode
  -- vim.keymap.set("c", "<D-v>", "<C-R>+") -- Paste command mode
  -- vim.keymap.set("i", "<D-v>", '<ESC>l"+Pli') -- Paste insert mode

  -- Currently cannot get this to show smooth line with gitsigns :(
  vim.opt.linespace = 4 -- Space between lines

  -- Scale UI
  vim.g.neovide_scale_factor = 1.2
  local change_scale_factor = function(delta)
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
  end
  vim.keymap.set("n", "<leader>u+", function()
    change_scale_factor(1.1)
  end, { desc = "Increase Neovide UI scale" })
  vim.keymap.set("n", "<leader>u-", function()
    change_scale_factor(1 / 1.1)
  end, { desc = "Descrease Neovide UI scale" })

  vim.g.neovide_window_blurred = true
  -- vim.g.neovide_transparency = 0.99
  vim.g.neovide_transparency = 1
  vim.g.neovide_show_border = true
  vim.g.neovide_floating_shadow = true
  vim.g.neovide_theme = "auto" -- mirror the system theme
  vim.g.neovide_confirm_quit = true
  vim.g.neovide_remember_window_size = true

  -- animation
  vim.g.neovide_cursor_animation_length = 0.02
  vim.g.neovide_cursor_animate_command_line = true
  vim.g.neovide_scroll_animation_length = 0.1
end
