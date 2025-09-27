vim.api.nvim_create_autocmd({ "FileType" }, {
  desc = "Force commentstring to include spaces",
  callback = function()
    local cs = vim.bo.commentstring

    if not cs or not cs:match("%%s") then
      if vim.bo.filetype == "dart" or vim.bo.filetype == "wgsl" then
        vim.bo.commentstring = "// %s"
      elseif vim.bo.filetype == "plantuml" then
        vim.bo.commentstring = "' %s"
      end

      return
    end

    vim.bo.commentstring = cs:gsub("%s*%%s%s*", " %%s "):gsub("%s*$", "")
  end,
})

return {}
