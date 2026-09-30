-- fugitive.lua
return {
    'tpope/vim-fugitive',
    dependencies = { 'tpope/vim-rhubarb' },
    keys = {
        { "<leader>gs", vim.cmd.Git,    desc = "Git status" },
        { "<leader>gb", ":GBrowse<CR>", mode = "n",         desc = "GBrowse current file on branch" },
        {
            "<leader>gb",
            function()
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
                vim.schedule(function()
                    vim.cmd("'<,'>GBrowse")
                end)
            end,
            mode = "v",
            desc = "GBrowse selected lines on branch",
        },
    },
}
