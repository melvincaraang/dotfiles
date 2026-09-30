local model = "gemini-2.5-flash"
-- local model = "gemini-2.5-flash-preview-04-17"

function PromptLLM()
    vim.ui.input({ prompt = "LLM Prompt: ", default = "" }, function(user_prompt)
        if not user_prompt or user_prompt == "" then return end

        local buf = vim.api.nvim_get_current_buf()
        local filename = vim.api.nvim_buf_get_name(buf)
        local mode = vim.fn.mode()
        local tmpfile = "/tmp/nvim_llm_input.txt"
        local lines = {}

        -- Check if we're in visual mode
        if mode:match("[vV\x16]") then
            -- Exit visual mode
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

            -- Get the selected lines
            local start_line = vim.fn.line("'<")
            local end_line = vim.fn.line("'>")
            lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)
        else
            -- If no selection, capture the full file content
            lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        end

        -- Write the context (code) and user input to the temporary file
        local f = io.open(tmpfile, "w")
        f:write("Context: \n")
        for _, line in ipairs(lines) do
            f:write(line .. "\n")
        end
        f:write("\n\nUser Prompt: \n" .. user_prompt .. "\n")
        f:close()

        -- Create the floating window and run the LLM command
        local buf_floating, win_floating = CreateFloatingWindow()

        -- LLM command (pipe the code context and user prompt to llm)
        local cmd = "cat " ..
            tmpfile .. " | llm -m " .. model .. " | tee /tmp/glowbuf.md && clear && glow -p /tmp/glowbuf.md"

        -- Run the command in the terminal window
        vim.fn.termopen(cmd, {
            on_exit = function(_, _)
                -- Close the floating window when the command exits
                vim.api.nvim_win_close(win_floating, true)
                vim.api.nvim_buf_delete(buf_floating, { force = true })
            end,
        })
    end)
end

function CreateFloatingWindow()
    -- Create a terminal buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    -- Window dimensions (80% width, 60% height)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.6)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create floating window
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
    })

    -- Set keybind to close window with 'q' or '<Esc>'
    vim.keymap.set('t', '<Esc>', '<C-\\><C-n>:q<CR>', { buffer = buf })
    vim.keymap.set('t', 'q', '<C-\\><C-n>:q<CR>', { buffer = buf })
    return buf, win
end

vim.keymap.set({ 'n', 'v' }, '<leader>llm', PromptLLM, { noremap = true, silent = true, desc = "Prompt the LLM" })
