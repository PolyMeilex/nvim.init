-- TODO: Save the result for use in next/prev keybinds
-- vim.lsp.handlers['textDocument/documentHighlight'] = function(_, result, ctx, _)
--   if not result then return end
--
--   local client = vim.lsp.get_client_by_id(ctx.client_id)
--   if not client then return end
--
--   -- for _, obj in pairs(result) do
--   --   vim.print(obj.range.start)
--   -- end
--
--   vim.lsp.util.buf_highlight_references(ctx.bufnr, result, client.offset_encoding)
-- end
--
--
-- vim.keymap.set('n', 'gn', function()
--   goto_next_reference()
-- end, {})
-- vim.keymap.set('n', 'gN', function()
--   goto_prev_reference()
-- end, {})

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "textDocument/document_highlight on CursorMoved",
  callback = function(event)
    ---@type vim.lsp.Client|nil
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client == nil then
      return
    end

    if not client.supports_method("textDocument/documentHighlight") then
      return
    end

    local bufnr = event.buf
    local timer = vim.loop.new_timer()
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

return {}
