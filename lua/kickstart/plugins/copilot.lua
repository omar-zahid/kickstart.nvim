return {
  {
    'github/copilot.vim',
    lazy = true,
    event = 'InsertEnter',
    cmd = { 'Copilot', 'Copilot panel', 'Copilot setup', 'Copilot status' },
    config = function()
      vim.keymap.set('n', '<leader>cp', ':Copilot panel<CR>', { desc = 'Copilot Panel' })
      vim.keymap.set('n', '<leader>cc', ':Copilot enable<CR>', { desc = 'Copilot Enable' })
      vim.keymap.set('n', '<leader>cd', ':Copilot disable<CR>', { desc = 'Copilot Disable' })
      vim.keymap.set('n', '<leader>cs', ':Copilot status<CR>', { desc = 'Copilot Status' })
    end,
  },
}
