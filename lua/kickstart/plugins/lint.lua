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
              local path = vim.api.nvim_buf_get_name(0)
              if require('js-toolchain').linter(path) == 'eslint_d' then
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
            local _, root = require('js-toolchain').linter(vim.api.nvim_buf_get_name(0))
            local ok = pcall(lint.try_lint, name, { cwd = root, ignore_errors = true })
            if not ok then
              -- silently skip; comment in the next line if you want visibility:
              vim.notify('lint: failed to run ' .. name, vim.log.levels.DEBUG)
            end
          end
        end,
      })
    end,

    -- set keymap to run eslint_d --fix on current buffer if its of type javascript or typescript or react
    vim.keymap.set('n', '<leader>lf', function()
      local bufnr = vim.api.nvim_get_current_buf()
      local path = vim.api.nvim_buf_get_name(bufnr)
      local linter, root = require('js-toolchain').linter(path)
      if linter == 'oxlint' and vim.api.nvim_buf_get_commands(bufnr, {}).LspOxlintFixAll then
        vim.cmd 'LspOxlintFixAll'
      elseif linter == 'eslint_d' then
        if vim.bo[bufnr].modified then
          vim.cmd.write()
        end
        vim.system(
          { 'eslint_d', '--fix', path },
          { cwd = root, text = true },
          vim.schedule_wrap(function(result)
            if result.code ~= 0 then
              vim.notify(result.stderr, vim.log.levels.ERROR)
            elseif vim.api.nvim_buf_is_valid(bufnr) then
              vim.api.nvim_buf_call(bufnr, function()
                vim.cmd.checktime()
                require('lint').try_lint('eslint_d', { cwd = root, ignore_errors = true })
              end)
            end
          end)
        )
      else
        vim.notify('No Oxlint or ESLint fixer configured for this file', vim.log.levels.WARN)
      end
    end, { desc = 'Run the project linter fix on current file' }),
  },
}
