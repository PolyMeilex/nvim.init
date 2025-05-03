vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or not client:supports_method("textDocument/completion") then
      return
    end

    vim.api.nvim_create_autocmd("InsertCharPre", {
      buffer = args.buf,
      -- TODO: Debounce?
      callback = vim.schedule_wrap(vim.lsp.completion.get),
    })

    vim.lsp.completion.enable(true, client.id, args.buf, {
      autotrigger = false,
      convert = function(item)
        local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Unknown"
        local icon = LspItemTypeIcons[item.kind] or ""
        return {
          kind = icon .. " " .. kind,
          kind_hlgroup = LspItemTypeHighlight[item.kind] or nil,
          menu = "",
        }
      end,
    })
  end,
})

vim.keymap.set("i", "<c-n>", vim.lsp.completion.get)
vim.o.completeopt = "menuone,noinsert"

return {}
