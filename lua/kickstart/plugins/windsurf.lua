return {
  'Exafunction/windsurf.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'hrsh7th/nvim-cmp',
  },
  config = function()
    require('codeium').setup {
      virtual_text = {
        enabled = true,
        map_keys = true,
        key_bindings = {
          accept = '<C-J>', -- Change this if <Tab> is conflicted
        },
      },
    }
    require('codeium').disable()

    vim.keymap.set('n', '<leader>cc', function()
      require('codeium').enable()
    end, { desc = 'Windsurf Enable' })
    vim.keymap.set('n', '<leader>cd', function()
      require('codeium').disable()
    end, { desc = 'Windsurf Disable' })
  end,
}
