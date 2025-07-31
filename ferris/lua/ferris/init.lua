local M = {}

---Returns the Rust-Analyzer client of the given buffer.
---@param bufnr integer? # The buffer number or nil for current
---@return vim.lsp.Client?
function M.ra_client(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr or 0, name = "rust_analyzer" })
  return clients and clients[1] or nil
end

function M.setup()
  vim.api.nvim_create_user_command("FerrisExpandMacro", require("ferris.expand_macro"), {})
  vim.api.nvim_create_user_command("FerrisViewMemoryLayout", require("ferris.view_memory_layout"), {})
  vim.api.nvim_create_user_command("FerrisOpenDocumentation", require("ferris.open_documentation"), {})
end

return M
