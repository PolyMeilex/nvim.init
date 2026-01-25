vim.api.nvim_create_autocmd("LspAttach", {
  desc = "textDocument/document_highlight on CursorMoved",
  callback = function(event)
    ---@type vim.lsp.Client|nil
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client == nil then
      return
    end

    if not client:supports_method("textDocument/documentHighlight") then
      return
    end

    local bufnr = event.buf
    local timer = vim.uv.new_timer()
    if timer == nil then
      return
    end

    local last_word = nil
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      buffer = bufnr,
      callback = function()
        local word = vim.fn.expand("<cword>")
        if last_word ~= word then
          last_word = word

          timer:stop()
          timer:start(
            200,
            0,
            vim.schedule_wrap(function()
              vim.lsp.buf.clear_references()
              vim.lsp.buf.document_highlight()
            end)
          )
        end
      end,
    })
  end,
})
