require('nvim-navic').setup({
  highlight = true,
})

require("lualine").setup({
  winbar = {
    lualine_c = {
      'navic',
    },
  },
  sections = {
    lualine_c = { { "filename", path = 1 } },
  },
})
