return {
    'tigion/nvim-asciidoc-preview',
    ft = { 'asciidoc' },
    build = 'cd server && npm install --omit=dev --no-save',
    ---@module 'asciidoc-preview'
    ---@type asciidoc-preview.Config
    keys = {
        {
            '<Leader>ap',
            '<cmd>AsciiDocPreview<CR>',
            desc = '[A]sciiDoc [P]review',
            silent = true,
        },
        {
            '<Leader>as',
            '<cmd>AsciiDocPreviewStop<CR>',
            desc = '[A]sciiDoc [S]top preview',
            silent = true,
        },
    },
    opts = {
        -- Add user configuration here
    },
}
