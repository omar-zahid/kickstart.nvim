return {
  'Exafunction/windsurf.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'hrsh7th/nvim-cmp',
  },
  config = function()
    require('codeium').setup {
      enable_codeium_in_insert_mode = false,
      virtual_text = {
        map_keys = true,
        key_bindings = {
          accept = '<C-J>', -- Change this if <Tab> is conflicted
        },
      },
    }
    vim.g.codeium_enabled = false

    vim.keymap.set('n', '<leader>cc', ':Codeium Enable<CR>', { desc = 'Windsurf Enable' })
    vim.keymap.set('n', '<leader>cd', ':Codeium Disable<CR>', { desc = 'Windsurf Disable' })
  end,
}
