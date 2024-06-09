local IsNotVsCode = require('vscode').IsNotVsCode()

return {
  'nvim-lualine/lualine.nvim',
  enabled = IsNotVsCode,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'SmiteshP/nvim-navic',
  },
  config = function()
    require('nvim-navic').setup({
      highlight = true,
    })

    require("lualine").setup({
      options = {
        disabled_filetypes = { 'neo-tree' },
      },
      winbar = {
        lualine_c = {
          'navic',
        },
      },
      sections = {
        lualine_c = { { "filename", path = 1 } },
      },
    })
  end,
}
