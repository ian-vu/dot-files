-- Navigation
-- vim.keymap.del({ "n", "x", "o" }, "n")
-- Allow for navigation with wrapped lines
vim.keymap.set({ "n", "x" }, "n", "v:count == 0 ? 'gj' : 'j'", { expr = true, noremap = true, silent = true })
vim.keymap.set({ "v", "o" }, "n", "j", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "N", "J", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "j", "nzz", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "J", "Nzz", { noremap = true, silent = true })

-- Allow for navigation with wrapped lines
vim.keymap.set({ "n", "x" }, "e", "v:count == 0 ? 'gk' : 'k'", { expr = true, noremap = true, silent = true })
vim.keymap.set({ "v", "o" }, "e", "k", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "E", "K", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "k", "e", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "K", "E", { noremap = true, silent = true })

vim.keymap.set({ "n", "v", "x", "o" }, "i", "l", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "I", "L", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "l", "i", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "L", "I", { noremap = true, silent = true })
-- vim.keymap.set({ "n", "v", "x", "o" }, "<c-k>", "<c-i>", { noremap = true, silent = true })

-- Pane navigation
vim.keymap.set({ "n", "v", "i" }, "<C-n>", "<cmd>TmuxNavigateDown<cr>", { noremap = true, desc = "Move to pane up" })
vim.keymap.set({ "n", "v", "i" }, "<C-e>", "<cmd>TmuxNavigateUp<cr>", { noremap = true, desc = "Move to pane down" })
vim.keymap.set(
  { "n", "v", "i" },
  "<C-i>",
  "<cmd>TmuxNavigateRight<cr>",
  { noremap = true, desc = "Move to pane right" }
)

-- scroll buffer down
vim.keymap.set({ "n", "v" }, "<C-k>", "<C-e>", { noremap = true, desc = "Scroll buffer down one line" })

-- vim.keymap.set({ "n", "v", "i" }, "<C-h>", "<C-w>h", { desc = "Go to left window", noremap = true })
-- vim.keymap.set({ "n", "v", "i" }, "<C-n>", "<C-w>j", { desc = "Go to lower window", noremap = true })
-- vim.keymap.set({ "n", "v", "i" }, "<C-e>", "<C-w>k", { desc = "Go to upper window", noremap = true })
-- vim.keymap.set({ "n", "v", "i" }, "<C-i>", "<C-w>l", { desc = "Go to right window", noremap = true })

-- Buffer
vim.keymap.set("n", "I", "<cmd>bnext<cr>", { desc = "Next buffer", noremap = true })

-- Jump list forwards
vim.keymap.set("n", "<C-m>", "<C-i>", { desc = "Jump list forwards", noremap = true })
