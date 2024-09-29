local IsNotVsCode = require("vscode").IsNotVsCode()

-- TODO: Remove after next update, that includes those spaces by default
vim.api.nvim_create_autocmd({ "FileType" }, {
  desc = "Force commentstring to include spaces",
  callback = function()
    local cs = vim.bo.commentstring

    if not cs or not cs:match("%%s") then
      return
    end

    vim.bo.commentstring = cs:gsub("%s*%%s%s*", " %%s "):gsub("%s*$", "")
  end,
})

-- ft.vala = { '//%s', '/*%s*/' }
-- ft.wgsl = { '//%s', '/*%s*/' }

return {}
