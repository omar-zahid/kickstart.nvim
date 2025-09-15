return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        -- markdown = { 'markdownlint' },
        javascript = { 'eslint_d' },
        javascriptreact = { 'eslint_d' },
        typescript = { 'eslint_d' },
        typescriptreact = { 'eslint_d' },
        astro = { 'eslint_d' },
      }

      -- To allow other plugins to add linters to require('lint').linters_by_ft,
      -- instead set linters_by_ft like this:
      -- lint.linters_by_ft = lint.linters_by_ft or {}
      -- lint.linters_by_ft['markdown'] = { 'markdownlint' }
      --
      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      -- helper: does this buffer have an ESLint config somewhere up the tree?
      local function has_eslint_config(start_from)
        local found = vim.fs.find({
          -- Flat config (ESLint v9+)
          'eslint.config.js',
          'eslint.config.mjs',
          'eslint.config.cjs',
          'eslint.config.ts',
          'eslint.config.json',
          'eslint.config.yaml',
          'eslint.config.yml',
          -- Legacy config
          '.eslintrc',
          '.eslintrc.js',
          '.eslintrc.cjs',
          '.eslintrc.json',
          '.eslintrc.yaml',
          '.eslintrc.yml',
          -- package.json (only if it actually contains "eslintConfig")
          'package.json',
        }, { path = start_from or vim.api.nvim_buf_get_name(0), upward = true })[1]

        if not found then
          return false
        end
        if found:sub(-12) ~= 'package.json' then
          return true
        end

        -- Only treat package.json as config if it has "eslintConfig"
        local ok, pkg = pcall(vim.fn.json_decode, table.concat(vim.fn.readfile(found), '\n'))
        return ok and type(pkg) == 'table' and pkg.eslintConfig ~= nil
      end

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave', 'BufEnter' }, {
        group = lint_augroup,
        callback = function()
          if not vim.bo.modifiable then
            return
          end

          local ft = vim.bo.filetype
          local configured = lint.linters_by_ft[ft] or {}

          -- Filter out eslint_d if there's no config
          local to_run = {}
          for _, name in ipairs(configured) do
            if name == 'eslint_d' then
              if has_eslint_config(vim.api.nvim_buf_get_name(0)) then
                table.insert(to_run, name)
              end
            else
              table.insert(to_run, name)
            end
          end

          if #to_run == 0 then
            return
          end

          -- nvim-lint's try_lint takes one linter name (string), so run each
          for _, name in ipairs(to_run) do
            -- ignore parse/exec errors from any single linter to avoid noisy notifies
            local ok = pcall(lint.try_lint, name, { ignore_errors = true })
            if not ok then
              -- silently skip; comment in the next line if you want visibility:
              vim.notify('lint: failed to run ' .. name, vim.log.levels.DEBUG)
            end
          end
        end,
      })
    end,

    -- set keymap to run eslint_d --fix on current buffer if its of type javascript or typescript or react
    vim.keymap.set('n', '<leader>ef', function()
      local ft = vim.bo.filetype
      local allowed = {
        javascript = true,
        typescript = true,
        javascriptreact = true,
        typescriptreact = true,
      }
      if allowed[ft] then
        vim.cmd('silent! !eslint_d --fix ' .. vim.fn.expand '%:p')
        vim.cmd 'edit!'
      else
        vim.notify('eslint_d fix not applicable for filetype: ' .. ft, vim.log.levels.WARN)
      end
    end, { desc = 'Run eslint_d --fix on current file' }),
  },
}
