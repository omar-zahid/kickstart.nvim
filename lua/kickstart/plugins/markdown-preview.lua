return {
  'iamcco/markdown-preview.nvim',
  cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  ft = { 'markdown' },
  build = 'cd app && npm install',
  keys = {
    {
      '<Leader>mp',
      '<cmd>MarkdownPreviewToggle<CR>',
      ft = 'markdown',
      desc = '[M]arkdown [P]review toggle',
      silent = true,
    },
  },
}
