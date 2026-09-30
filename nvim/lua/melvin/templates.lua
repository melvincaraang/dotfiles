-- This file contains key mappings for inserting templates into the current buffer.
-- Each mapping should be prefixed with "i" to indicate that it is for insertion.

-- Current Date
vim.keymap.set('n', '<leader>id', function()
    local date = os.date("%Y-%m-%d")
    vim.api.nvim_put({ date }, "", false, true)
end, { desc = 'Insert current date' })

-- Notes
vim.keymap.set('n', '<leader>inotes', function()
    local template_path = vim.fn.stdpath("config") .. "/templates/notes_template.md"
    local date = os.date("%Y-%m-%d")
    local lines = vim.fn.readfile(template_path)
    table.insert(lines, 1, "# " .. date)
    vim.api.nvim_put(lines, "", true, true)
end, { desc = 'Insert notes template' })
