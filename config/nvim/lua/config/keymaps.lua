vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- Save
map("n", "<leader>w", "<cmd>w<cr>", {
	desc = "Save file",
})

-- Quit
map("n", "<leader>q", "<cmd>q<cr>", {
	desc = "Quit",
})

-- Clear search
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlighting" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })

-- Keep selected text selected while indenting
map("v", "<", "<gv", { desc = "Indent selection left" })
map("v", ">", ">gv", { desc = "Indent selection right" })

-- Move selected lines
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Close buffer" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>xx", vim.diagnostic.setqflist, { desc = "All diagnostics" })
