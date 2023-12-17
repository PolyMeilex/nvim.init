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
