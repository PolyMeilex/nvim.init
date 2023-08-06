require('lsp-progress').setup({
  format = function(client_messages)
    local sign = " LSP"
    return #client_messages > 0
        and (sign .. " " .. table.concat(client_messages, " "))
        or ""
  end,
})

require('nvim-navic').setup({
  highlight = true,
})

require("lualine").setup({
  winbar = {
    lualine_c = {
      'navic',
    },
    lualine_y = { "require('lsp-progress').progress()" },
  }
})

vim.api.nvim_create_augroup("lualine_augroup", { clear = true })
vim.api.nvim_create_autocmd("User LspProgressStatusUpdated", {
  group = "lualine_augroup",
  callback = require("lualine").refresh,
})
