--- Formatting is chosen per project, never mixed:
---   Oxc projects    -> oxfmt
---   Legacy projects -> prettierd (falling back to a local prettier)
---
--- Oxfmt targets Prettier-compatible output but is not a universal drop-in
--- (different default `printWidth`, no Prettier plugins), so legacy projects
--- keep using their own Prettier.
---
--- Oxc projects format through the `oxfmt` language server rather than the CLI.
--- The formatting engine is native either way, but the CLI pays for a Node
--- start plus a re-parse of the TypeScript `vite.config.ts` on every save
--- (~370ms), while the server keeps both resident (~1ms). `lsp_format =
--- 'prefer'` still falls back to the CLI when the server is not running.
---@param bufnr integer
---@return conform.FiletypeFormatter
local function web(bufnr)
  if require('js-toolchain').formatter(vim.api.nvim_buf_get_name(bufnr)) == 'oxfmt' then
    return { 'oxfmt', lsp_format = 'prefer', name = 'oxfmt' }
  end
  return { 'prettierd', 'prettier', stop_after_first = true }
end

return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>ff',
        function()
          -- `lsp_format` is deliberately not passed: explicit options win over
          -- per-filetype ones, which would stop Oxc projects preferring the
          -- oxfmt language server.
          require('conform').format { async = true }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    init = function()
      vim.api.nvim_create_autocmd('VimLeavePre', {
        group = vim.api.nvim_create_augroup('PrettierdCleanup', { clear = true }),
        callback = function()
          vim.fn.jobstart({ 'prettierd', 'stop' }, { detach = true })
        end,
      })

      -- Warm the formatter in the background the first time a web file is
      -- opened in a project.
      --
      -- The first run is far slower than the rest because `prettierd` has to
      -- boot its daemon and load the project's config (~850ms, versus ~60ms
      -- once warm), and the daemon is stopped on exit above, so every session
      -- starts cold. Doing it here means the cost is paid while reading the
      -- file instead of on the first save.
      local warmed = {} ---@type table<string, boolean>
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('FormatterWarmup', { clear = true }),
        pattern = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'css', 'scss', 'html', 'json', 'jsonc', 'yaml', 'markdown' },
        callback = function(event)
          local path = vim.api.nvim_buf_get_name(event.buf)
          local formatter, root = require('js-toolchain').formatter(path)
          root = root or vim.fn.getcwd()

          local key = formatter .. root
          if warmed[key] then
            return
          end
          warmed[key] = true

          -- Prefer the project's own binary, like conform does.
          local binary = vim.fs.joinpath(root, 'node_modules', '.bin', formatter == 'oxfmt' and 'oxfmt' or 'prettierd')
          if vim.fn.executable(binary) == 0 then
            binary = formatter == 'oxfmt' and 'oxfmt' or 'prettierd'
          end
          if vim.fn.executable(binary) == 0 then
            return
          end

          local cmd = formatter == 'oxfmt' and { binary, '--stdin-filepath', path } or { binary, path }
          pcall(vim.system, cmd, { cwd = root, stdin = 'const _warmup = 1;\n', text = true }, function() end)
        end,
      })
    end,
    opts = {
      notify_on_error = true,
      -- Filled in only where a filetype does not set its own value, so Oxc
      -- projects can still ask for `prefer` to reach the oxfmt server.
      default_format_opts = {
        lsp_format = 'fallback',
      },
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          -- `lsp_format` is left to the filetype and `default_format_opts`.
          return {
            -- Generous enough for a cold `prettierd` daemon (~850ms) and for a
            -- fallback to the `oxfmt` CLI, which costs ~370ms per run.
            timeout_ms = 3000,
          }
        end
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        terraform = { 'terraform_fmt' },
        -- Web filetypes resolve their formatter from the project.
        css = web,
        graphql = web,
        html = web,
        javascript = web,
        javascriptreact = web,
        json = web,
        jsonc = web,
        markdown = web,
        scss = web,
        typescript = web,
        typescriptreact = web,
        yaml = web,
        -- Oxfmt does not support Astro, so always use Prettier there.
        astro = { 'prettierd', 'prettier', stop_after_first = true },
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
