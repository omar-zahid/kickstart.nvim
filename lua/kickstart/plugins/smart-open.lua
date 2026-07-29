return {
  'danielfalk/smart-open.nvim',
  branch = '0.2.x',
  config = function()
    -- smart-open's default ignore list contains '*.git/*', which it turns into the
    -- anchored Lua pattern '^.*%.git/.*$' (see smart-open/util/init.lua filemask).
    -- That matches any absolute path merely *containing* '.git/', so in a bare-repo
    -- worktree layout (e.g. ~/code/work/portal-ui.git/next/...) every project file
    -- looks ignored and is never recorded in the frecency db -- no recent files.
    -- '*/.git/*' still excludes real .git metadata dirs without eating the project.
    local defaults = require 'telescope._extensions.smart_open.default_config'

    local ignore_patterns = vim.tbl_filter(function(pattern)
      return pattern ~= '*.git/*'
    end, vim.deepcopy(defaults.ignore_patterns))

    table.insert(ignore_patterns, '*/.git/*')

    -- Call setup directly so the corrected patterns reach history:setup regardless of
    -- whether this plugin or telescope loads first. load_extension re-invokes setup
    -- with telescope's (empty) ext config, but nil values are ignored there.
    require('smart-open').setup { ignore_patterns = ignore_patterns }
    require('telescope').load_extension 'smart_open'
  end,
  dependencies = {
    'kkharji/sqlite.lua',
    -- Only required if using match_algorithm fzf
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    -- Optional.  If installed, native fzy will be used when match_algorithm is fzy
    { 'nvim-telescope/telescope-fzy-native.nvim' },
  },
}
