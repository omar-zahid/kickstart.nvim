local function web_formatters(bufnr)
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
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },
        javascript = web_formatters,
        html = web_formatters,
        typescript = web_formatters,
        typescriptreact = web_formatters,
        astro = { 'prettierd', 'prettier', stop_after_first = true },
        json = web_formatters,
        jsonc = web_formatters,
        scss = web_formatters,
        css = web_formatters,
        terraform = { 'terraform_fmt' },
        yaml = web_formatters,
        yml = web_formatters,
        markdown = web_formatters,
      },
    },
  },
}
-- vim: ts=2 sts=2 sw=2 et
