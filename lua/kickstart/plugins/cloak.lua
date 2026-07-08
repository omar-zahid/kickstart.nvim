return {
    "laytan/cloak.nvim",
    config = function()
        require("cloak").setup({
        })
        vim.keymap.set('n', '<leader>ck', '<cmd>CloakToggle<CR>', { desc = '[C]loa[K] toggle' })
    end,
}
