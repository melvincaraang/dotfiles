-- Use spaces instead of tabs
vim.opt.expandtab = true

-- Set the width of a tab to 4 spaces
vim.opt.tabstop = 4

-- Set the number of spaces for each indentation level
vim.opt.shiftwidth = 4

-- Make editing behavior match tabstop
vim.opt.softtabstop = 4

vim.opt.smartindent = true
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.diagnostic.config({ virtual_text = { current_line = true } })

vim.opt.guicursor = ""

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"
vim.opt.cursorline = true
vim.opt.cursorcolumn = false

-- Format Options
vim.api.nvim_create_autocmd("FileType", {
    pattern = "json",
    callback = function()
        vim.opt_local.formatprg = "jq"
    end,
})
