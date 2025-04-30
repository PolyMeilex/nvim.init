local M = {}

M.diagnostics = {}

function M.load()
  M.diagnostics = {}
  for _, d in pairs(vim.diagnostic.get()) do
    local severity = d.severity or 1000
    local path = vim.api.nvim_buf_get_name(d.bufnr)

    local old = M.diagnostics[path] or 1000

    ---@diagnostic disable-next-line: param-type-mismatch
    M.diagnostics[path] = math.min(old, severity)
  end
end

---@param path string
---@return vim.diagnostic.Severity
function M.get(path)
  for p, severity in pairs(M.diagnostics) do
    if vim.startswith(p, path) then
      return severity
    end
  end

  ---@diagnostic disable-next-line: return-type-mismatch
  return M.diagnostics[path] or 1000
end

return M
