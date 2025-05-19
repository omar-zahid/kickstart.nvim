return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      -- Filename toggle logic
      _G.show_full_path = false

      function _G.get_filename_status()
        return _G.show_full_path and '%f' or '%t'
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_filename = function()
        return '%{%v:lua.get_filename_status()%}'
      end

      -- Git branch name shortening logic
      -- For example, linear branch names starts with 'feature/' followed by
      -- ticket number and hyphen, e.g. 'feature/1234-branch-name'

      local function shorten_git_branch(branch)
        local short = branch:match '^([^/]+/[^-]+%-[^-]+)'
        return short or branch
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_git = function()
        local branch = vim.b.gitsigns_head
        if branch then
          return shorten_git_branch(branch)
        end
        return branch
      end

      -- Keymap to toggle filename display in statusline
      vim.keymap.set('n', '<leader>fp', function()
        _G.show_full_path = not _G.show_full_path
        vim.cmd 'redrawstatus'
      end, { desc = 'Toggle full path in statusline' })

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
