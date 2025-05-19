return {
  'catppuccin/nvim',
  lazy = false,
  name = 'catppuccin',
  priority = 1000,
  config = function()
    require('catppuccin').setup {
      flavour = 'mocha',
      integrations = {
        rainbow_delimiters = true,
        blink_cmp = true,
        copilot_vim = true,
      },
    }
    vim.cmd.colorscheme 'catppuccin'
  end,
}
