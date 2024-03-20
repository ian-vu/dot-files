-- Navigation
-- vim.keymap.del({ "n", "x", "o" }, "n")
vim.keymap.set({ "n", "v", "x", "o" }, "n", "j", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "N", "J", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "j", "n", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "J", "N", { noremap = true, silent = true })

vim.keymap.set({ "n", "v", "x", "o" }, "e", "k", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "E", "K", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "k", "e", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "K", "E", { noremap = true, silent = true })

vim.keymap.set({ "n", "v", "x", "o" }, "i", "l", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "I", "L", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "l", "i", { noremap = true, silent = true })
vim.keymap.set({ "n", "v", "x", "o" }, "L", "I", { noremap = true, silent = true })

-- Pane navigation
vim.keymap.set({ "n", "v", "i" }, "<C-h>", "<C-w>h", { desc = "Go to left window", noremap = true })
vim.keymap.set({ "n", "v", "i" }, "<C-n>", "<C-w>j", { desc = "Go to lower window", noremap = true })
vim.keymap.set({ "n", "v", "i" }, "<C-e>", "<C-w>k", { desc = "Go to upper window", noremap = true })
vim.keymap.set({ "n", "v", "i" }, "<C-i>", "<C-w>l", { desc = "Go to right window", noremap = true })

-- Buffer
vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
