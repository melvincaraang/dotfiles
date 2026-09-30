return {
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        config = function()
            require("mason").setup()
        end,
    },

    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("mason-tool-installer").setup({
                ensure_installed = {
                    "basedpyright",
                    "cfn-lint",
                    "lua-language-server",
                    "ruff",
                    "sqlfmt",
                    "yamlfmt",
                    "yamllint",
                },
                auto_update = false,
                run_on_start = true,
            })
        end,
    }
}
