return {
    'rose-pine/neovim',
    as = 'rose-pine',
    config = function()
        local color = color or "rose-pine"
        vim.cmd("colorscheme rose-pine")
        vim.cmd.colorscheme(color)

        vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    end
}
