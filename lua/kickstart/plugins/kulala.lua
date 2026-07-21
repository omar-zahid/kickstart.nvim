return {
  'mistweaverco/kulala.nvim',
  opts = {
    global_keymaps = {
      ['Send request'] = { -- sets global mapping
        '<leader>rr',
        function()
          require('kulala').run()
        end,
        mode = { 'n', 'v' }, -- optional mode, default is n
        ft = { 'http', 'rest' }, -- sets mapping for specified file types
        desc = 'Send request', -- optional description, otherwise inferred from the key
      },
      ['Send all requests'] = {
        '<leader>ra',
        function()
          require('kulala').run_all()
        end,
        mode = { 'n', 'v' },
        ft = { 'http', 'rest' }, -- sets mapping for specified file types
      },
      ['Replay the last request'] = {
        '<leader>rl',
        function()
          require('kulala').replay()
        end,
        ft = { 'http', 'rest' }, -- sets mapping for specified file types
      },
      ['Copy request as cURL'] = {
        '<leader>rc',
        function()
          require('kulala').copy()
        end,
        ft = { 'http', 'rest' }, -- sets mapping for specified file types
        desc = 'Copy request as cURL',
      },
      ['Find request'] = false, -- set to false to disable
    },
  },
}
