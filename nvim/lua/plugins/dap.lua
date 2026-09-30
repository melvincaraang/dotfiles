return {
    'mfussenegger/nvim-dap',
    lazy = true,
    cmd = {
        "DapContinue", "DapToggleBreakpoint", "DapStepOver", "DapStepInto",
        "DapStepOut", "DapTerminate"
    },
    keys = {
        { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
        { "<leader>dc", function() require("dap").continue() end,          desc = "Continue Debugging" },
        { "<leader>do", function() require("dap").step_over() end,         desc = "Step Over" },
        { "<leader>di", function() require("dap").step_into() end,         desc = "Step Into" },
        { "<leader>dO", function() require("dap").step_out() end,          desc = "Step Out" },
        { "<leader>dt", function() require("dap").terminate() end,         desc = "Terminate Debugging" },
        { "<leader>du", function() require("dapui").toggle() end,          desc = "Toggle Dap UI" },
    },
    dependencies = {
        {
            "mfussenegger/nvim-dap-python",
            config = function()
                require("dap-python").setup("~/.venvs/debugpy/bin/python")
            end,
        },
        {
            "rcarriga/nvim-dap-ui",
            dependencies = { "nvim-neotest/nvim-nio" },
            config = function()
                require("dapui").setup()
            end,
        },
    },
    config = function()
        -- Optional general DAP configuration here
    end,
}
