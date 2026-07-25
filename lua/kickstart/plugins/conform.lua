--- Formatting is chosen per project, never mixed:
---   Oxc projects    -> oxfmt
---   Legacy projects -> prettierd (falling back to a local prettier)
---
--- Oxfmt targets Prettier-compatible output but is not a universal drop-in
--- (different default `printWidth`, no Prettier plugins), so legacy projects
--- keep using their own Prettier.
---@param bufnr integer
---@return conform.FiletypeFormatter
local function web(bufnr)
  if require('js-toolchain').formatter(vim.api.nvim_buf_get_name(bufnr)) == 'oxfmt' then
    return { 'oxfmt' }
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
          require('conform').format { async = true, lsp_format = 'fallback' }
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
    end,
    opts = {
      notify_on_error = true,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
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
