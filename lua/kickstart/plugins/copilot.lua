return {
    {
        'github/copilot.vim',
        lazy = true,
        cmd = { 'Copilot', 'Copilot panel', 'Copilot setup', 'Copilot status' },
        config = function()
            vim.keymap.set('n', '<leader>cp', ':Copilot panel<CR>', { desc = 'Copilot Panel' })
            vim.keymap.set('n', '<leader>cc', ':Copilot enable<CR>', { desc = 'Copilot Enable' })
            vim.keymap.set('n', '<leader>cd', ':Copilot disable<CR>', { desc = 'Copilot Disable' })
            vim.keymap.set('n', '<leader>cs', ':Copilot status<CR>', { desc = 'Copilot Status' })

            vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
                expr = true,
                replace_keycodes = false
            })
            vim.g.copilot_no_tab_map = true
        end,
    },
}
