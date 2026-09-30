vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Move blocks of code
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Concat line under and keep cursor at beginnig of current line
vim.keymap.set("n", "J", "mzJ`z")

-- Make half-page scrolling better
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Keep searched text in the middle
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Copy to system clipboard
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

-- Remap "Go to last file opened"
vim.keymap.set("n", "<leader><Tab>", "<C-^>")

-- Resize Window Height
vim.keymap.set('n', '<leader>+', ':resize +2<CR>')
vim.keymap.set('n', '<leader>-', ':resize -2<CR>')

-- Resize Window Width
vim.keymap.set('n', '<leader>>', ':vertical resize +5<CR>')
vim.keymap.set('n', '<leader><', ':vertical resize -5<CR>')
