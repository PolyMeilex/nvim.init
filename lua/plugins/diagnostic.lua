local icons = require("icons")

vim.diagnostic.config({
  virtual_text = {
    severity = vim.diagnostic.severity.ERROR,
  },
  signs = { text = icons.diagnostic_signs },
})

vim.keymap.set("n", "gl", vim.diagnostic.open_float)

vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump({ count = -1, severity = { min = vim.diagnostic.severity.WARN } })
end)
vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump({ count = 1, severity = { min = vim.diagnostic.severity.WARN } })
end)

vim.keymap.set("n", "[D", function()
  vim.diagnostic.jump({ count = -1, severity = { min = vim.diagnostic.severity.ERROR } })
end)
vim.keymap.set("n", "]D", function()
  vim.diagnostic.jump({ count = 1, severity = { min = vim.diagnostic.severity.ERROR } })
end)

return {}
