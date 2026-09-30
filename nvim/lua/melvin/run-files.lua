-- This script sets up key mappings to run files, usually in a floating terminal window

function PipeToLess(cmd)
    local pipe_cmd = cmd .. " 2>&1 | tee /tmp/nvim_run_out.log && less +G /tmp/nvim_run_out.log"
    return pipe_cmd
end

-- Run python file
vim.keymap.set('n', '<leader>rp', function()
    local filepath = vim.fn.expand("%:p")
    local filedir = vim.fn.fnamemodify(filepath, ":h")

    -- Create a new floating terminal buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set the size of the floating window (80% width and 60% height of the screen)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.6)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Open the floating window
    vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })

    -- Run the Python file in the terminal inside the floating window
    local cmd = string.format(PipeToLess("cd %s && python %s"),
        vim.fn.shellescape(filedir),
        vim.fn.shellescape(filepath))
    vim.fn.termopen(cmd)

    -- Automatically enter insert mode
    vim.cmd("startinsert")
end, { desc = "Run Python file in floating terminal" })

-- Run zsh file
vim.keymap.set('n', '<leader>rb', function()
    local filepath = vim.fn.expand("%:p")
    local filedir = vim.fn.fnamemodify(filepath, ":h")

    -- Create a new floating terminal buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set the size of the floating window (80% width and 60% height of the screen)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.6)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Open the floating window
    vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })

    -- Run the Python file in the terminal inside the floating window
    local cmd = string.format(PipeToLess("cd %s && %s"), vim.fn.shellescape(filedir), vim.fn.shellescape(filepath))
    vim.fn.termopen(cmd)

    -- Automatically enter insert mode
    vim.cmd("startinsert")
end, { desc = "Run bash file in floating terminal" })


-- Run python unit tests using unittest in a floating terminal
function FindRootDir(start_dir)
    local dir = start_dir
    while dir ~= "/" do
        if vim.fn.isdirectory(dir .. "/.git") == 1 or
            vim.fn.filereadable(dir .. "/setup.py") == 1 or
            vim.fn.filereadable(dir .. "/pyproject.toml") == 1 then
            return dir
        end
        dir = vim.fn.fnamemodify(dir, ":h") -- Move to the parent directory
    end
    return nil                              -- Return nil if no root is found
end

vim.keymap.set('n', '<leader>rt', function()
    local filepath = vim.fn.expand("%:p")

    -- Find the root directory of the project
    local root_dir = FindRootDir(vim.fn.fnamemodify(filepath, ":h"))
    if not root_dir then
        print("Root directory not found.")
        return
    end

    -- Create a new floating terminal buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set the size of the floating window (80% width and 60% height of the screen)
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.6)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Open the floating window
    vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })

    -- Run the unit tests using python unittest in the terminal inside the floating window
    local cmd = string.format(PipeToLess("cd %s && python -m unittest %s"), vim.fn.shellescape(root_dir),
        vim.fn.shellescape(filepath))
    vim.fn.termopen(cmd)

    -- Automatically enter insert mode
    vim.cmd("startinsert")
end, { desc = "Run unit tests with unittest in floating terminal" })


-- Run markdown file using glow in a floating terminal
vim.keymap.set('n', '<leader>rm', function()
    local filepath = vim.fn.expand("%:p")
    local filedir = vim.fn.fnamemodify(filepath, ":h")

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

    -- Run glow command
    local cmd = string.format("cd %s && glow -p %s", vim.fn.shellescape(filedir), vim.fn.shellescape(filepath))
    vim.fn.termopen(cmd)

    -- Enter terminal mode
    vim.cmd("startinsert")
end, { desc = "Render markdown file in floating terminal with glow" })
