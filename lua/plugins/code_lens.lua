vim.api.nvim_create_user_command("CodeLensRun", function()
  local old = vim.lsp.codelens.on_codelens
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.codelens.on_codelens = function(err, result, ctx)
    local res = old(err, result, ctx)
    vim.lsp.codelens.run()
    vim.lsp.codelens.clear()
    return res
  end
  vim.lsp.codelens.refresh()
  vim.lsp.codelens.on_codelens = old
end, {})

return {}
