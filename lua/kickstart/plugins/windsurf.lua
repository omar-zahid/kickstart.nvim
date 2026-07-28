return {
  'Exafunction/windsurf.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'hrsh7th/nvim-cmp',
  },
  config = function()
    -- The arm64 language server segfaults on Apple M5 (go-m1cpu bug, Exafunction/codeium#291),
    -- so use the x86_64 build via Rosetta when it is available.
    local x64_server = vim.fn.stdpath 'cache' .. '/codeium/bin/1.20.9/language_server_macos_x64'
    local tools = vim.fn.executable(x64_server) == 1 and { language_server = x64_server } or nil

    require('codeium').setup {
      tools = tools,
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
