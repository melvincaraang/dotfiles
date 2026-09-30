return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        build = ":TSUpdate",
        config = function()
            local configs = require("nvim-treesitter.configs")
            configs.setup({
                ensure_installed = {
                    "c", "lua", "vim", "vimdoc", "python",
                    "javascript", "typescript", "tsx", "json",
                    "html", "css", "yaml", "toml", "svelte",
                    "sql", "markdown", "jinja", "jinja_inline", "gitignore"
                },
                sync_install = false,
                highlight = { enable = true },
                indent = { enable = true },
            })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        opts = {
            enable = true,
            max_lines = 0,
            trim_scope = "outer",
            mode = "cursor",
            separator = nil,
        },
    },
}
