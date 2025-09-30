return {
    {
        'tpope/vim-fugitive',
        dependencies = { 'tpope/vim-rhubarb' }, -- <-- GitHub provider for :GBrowse
        config = function()
            vim.keymap.set('n', '<leader>gs', vim.cmd.Git)
            vim.keymap.set('n', 'gf', '<cmd>diffget //2<CR>')
            vim.keymap.set('n', 'gj', '<cmd>diffget //3<CR>')

            vim.keymap.set('n', 'gb', function()
                vim.cmd('GBrowse')
            end, { noremap = true, silent = true, desc = 'GBrowse: open in browser' })

            vim.keymap.set('v', 'gb', ':GBrowse<CR>',
                { noremap = true, silent = true, desc = 'GBrowse: open anchored to selection' })

            local Omar_Fugutive = vim.api.nvim_create_augroup('Omar_Fugutive', {})

            local autocmd = vim.api.nvim_create_autocmd
            autocmd('BufWinEnter', {
                group = Omar_Fugutive,
                pattern = '*',
                callback = function()
                    if vim.bo.ft ~= 'fugitive' then
                        return
                    end

                    local bufnr = vim.api.nvim_get_current_buf()
                    local opts = { buffer = bufnr, remap = false }
                    vim.keymap.set('n', '<leader>p', function()
                        vim.cmd.Git 'push'
                    end, opts)

                    -- rebase always
                    vim.keymap.set('n', '<leader>P', function()
                        vim.cmd.Git 'pull --rebase'
                    end, opts)

                    -- NOTE: It allows me to easily set the branch i am pushing and any tracking
                    -- needed if i did not set the branch up correctly
                    vim.keymap.set('n', '<leader>t', ':Git push -u origin ', opts)
                end,
            })
        end,
    },
}
