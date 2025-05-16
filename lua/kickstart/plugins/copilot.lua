return {
  {
    'github/copilot.vim',
    lazy = true,
    cmd = 'Copilot',
    config = function()
      vim.keymap.set('n', '<leader>cp', ':Copilot panel<CR>', { desc = 'Copilot Panel' })
      vim.keymap.set('n', '<leader>cc', ':Copilot enable<CR>', { desc = 'Copilot Enable' })
      vim.keymap.set('n', '<leader>cd', ':Copilot disable<CR>', { desc = 'Copilot Disable' })
    end,
  },
}
