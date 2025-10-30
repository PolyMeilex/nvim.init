local lib = require("lsp-code-context.lib")

local M = {}

function M.setup()
  local breadcrumbs_augroup = vim.api.nvim_create_augroup("Breadcrumbs", { clear = true })

  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    group = breadcrumbs_augroup,
    callback = lib.update_label,
    desc = "Update breadcrumbs label",
  })

  vim.api.nvim_create_autocmd({ "InsertLeave", "BufEnter", "CursorHold" }, {
    group = breadcrumbs_augroup,
    callback = lib.request_symbols,
    desc = "Update breadcrumbs lsp symbols",
  })
end

function M.get_label()
  return lib.get_label()
end

function M.get_data(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local context_data = require("lsp-code-context.my").get_context_data(bufnr)

  if context_data == nil then
    return nil
  end

  local ret = {}

  for _, v in ipairs(context_data) do
    table.insert(ret, {
      kind = v.kind,
      type = lib.adapt_lsp_num_to_str(v.kind),
      name = v.name,
      icon = lib.icons[v.kind],
      scope = {
        start = {
          line = v.range.start.line + 1,
          character = v.range.start.character,
        },
        ["end"] = {
          line = v.range["end"].line + 1,
          character = v.range["end"].character,
        },
      },
    })
  end

  return ret
end

return M
