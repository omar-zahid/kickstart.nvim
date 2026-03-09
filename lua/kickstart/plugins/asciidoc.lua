return {
    'tigion/nvim-asciidoc-preview',
    ft = { 'asciidoc' },
    build = 'cd server && npm install --omit=dev --no-save',
    ---@module 'asciidoc-preview'
    ---@type asciidoc-preview.Config
    keys = {
        {
            '<Leader>cp',
            '<cmd>AsciiDocPreview<CR>',
            desc = 'Preview AsciiDoc document',
            silent = true,
        },
    },
    opts = {
        -- Add user configuration here
    },
}
