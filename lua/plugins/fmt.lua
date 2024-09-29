local function run_stylua(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local buffer_as_string = table.concat(lines, "\n")

  local out = vim
    .system(
      { "stylua", "--search-parent-directories", "--stdin-filepath", file, "-" },
      { stdin = buffer_as_string, text = true }
    )
    :wait()

  if out.code == 0 then
    local new_lines = vim.split(out.stdout, "\n")
    table.remove(new_lines)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP fmt attach actions",
  callback = function(event)
    local bufnr = event.buf
    local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

    ---@type vim.lsp.Client|nil
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client == nil then
      return
    end

    if client.supports_method("textDocument/formatting") then
      if filetype == "rust" then
        -- Format the current buffer on save
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ bufnr = bufnr, id = client.id, async = false })
          end,
        })
      end
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.lua",
  callback = function()
    local bufnr = vim.fn.expand("<abuf>")
    run_stylua(tonumber(bufnr))
  end,
})

return {}
