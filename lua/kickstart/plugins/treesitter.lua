-- nvim-treesitter `main` branch (Neovim 0.12+).
--
-- This branch is a full rewrite: `setup()` only accepts `install_dir`. Parsers
-- are installed with `install()`, and the features themselves come from Neovim
-- and are opt-in per filetype, so highlighting, indentation and folding are
-- enabled from a FileType autocommand below.
local parsers = {
  -- Web
  'css',
  'graphql',
  'html',
  'javascript',
  'jsdoc',
  'json',
  'json5',
  'scss',
  'tsx',
  'typescript',
  -- Config and docs
  'bash',
  'diff',
  'dockerfile',
  'gitcommit',
  'git_rebase',
  'gitignore',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'regex',
  'toml',
  'vim',
  'vimdoc',
  'yaml',
  -- Other languages in use
  'c',
  'rust',
}

--- Filetypes that should get treesitter highlighting and indentation.
--- Several filetypes map onto one parser, so this is not the parser list.
local filetypes = {
  'bash',
  'c',
  'css',
  'diff',
  'dockerfile',
  'gitcommit',
  'gitignore',
  'gitrebase',
  'graphql',
  'html',
  'javascript',
  'javascriptreact',
  'json',
  'json5',
  'jsonc',
  'lua',
  'markdown',
  'query',
  'rust',
  'scss',
  'sh',
  'toml',
  'typescript',
  'typescriptreact',
  'vim',
  'yaml',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    -- This branch does not support lazy-loading.
    lazy = false,
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').setup()

      -- No-op for parsers that are already present.
      require('nvim-treesitter').install(parsers)

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('kickstart-treesitter', { clear = true }),
        pattern = filetypes,
        callback = function(event)
          -- Highlighting is provided by Neovim itself.
          pcall(vim.treesitter.start, event.buf)

          -- NOTE: treesitter folding is intentionally not enabled. Setting
          -- 'foldmethod' to expr closes every fold when a file opens, and
          -- operators like `gcc` then act on the whole closed fold instead of
          -- the current line. See `:h vim.treesitter.foldexpr()` if you ever
          -- want folds; it needs 'foldlevel' raised to stay open.

          -- Treesitter indentation is still experimental upstream.
          vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    keys = {
      -- Same objects as before: parameters, functions and classes.
      { 'aa', desc = 'Select outer parameter', mode = { 'x', 'o' } },
      { 'ia', desc = 'Select inner parameter', mode = { 'x', 'o' } },
      { 'af', desc = 'Select outer function', mode = { 'x', 'o' } },
      { 'if', desc = 'Select inner function', mode = { 'x', 'o' } },
      { 'ac', desc = 'Select outer class', mode = { 'x', 'o' } },
      { 'ic', desc = 'Select inner class', mode = { 'x', 'o' } },
    },
    config = function()
      require('nvim-treesitter-textobjects').setup {
        select = {
          -- Jump forward to the text object, similar to targets.vim.
          lookahead = true,
        },
      }

      local objects = {
        aa = '@parameter.outer',
        ia = '@parameter.inner',
        af = '@function.outer',
        ['if'] = '@function.inner',
        ac = '@class.outer',
        ic = '@class.inner',
      }

      for key, query in pairs(objects) do
        vim.keymap.set({ 'x', 'o' }, key, function()
          require('nvim-treesitter-textobjects.select').select_textobject(query, 'textobjects')
        end, { desc = 'Select ' .. query })
      end
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
