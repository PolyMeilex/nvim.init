local M = {}

---@param bufnr integer
---@param linenr_start integer (1-indexed)
---@param linenr_end integer (1-indexed,inclusive)
function M.clear_lines(bufnr, linenr_start, linenr_end)
  local count = linenr_end - linenr_start + 1
  if count < 1 then
    return
  end

  local lines = {}
  for i = 1, count do
    lines[i] = ""
  end

  vim.api.nvim_buf_set_lines(bufnr, linenr_start - 1, linenr_end, false, lines)
end

---@param lines (string|RenuiLine)[]
---@param bufnr number
---@param ns_id number
---@param linenr_start integer (1-indexed)
---@param linenr_end? integer (1-indexed,inclusive)
---@param byte_start? integer (0-indexed)
---@param byte_end? integer (0-indexed,exclusive)
function M.render_lines(lines, bufnr, ns_id, linenr_start, linenr_end, byte_start, byte_end)
  local row_start = linenr_start - 1
  local row_end = linenr_end or row_start + 1

  local content = vim.tbl_map(function(line)
    if type(line) == "string" then
      return line
    end
    return line:content()
  end, lines)

  if byte_start then
    local col_start = byte_start
    local col_end = byte_end or #vim.api.nvim_buf_get_lines(bufnr, row_start, row_end, false)[1]
    vim.api.nvim_buf_set_text(bufnr, row_start, col_start, row_end - 1, col_end, content)
  else
    vim.api.nvim_buf_set_lines(bufnr, row_start, row_end, false, content)
  end

  for linenr, line in ipairs(lines) do
    if type(line) ~= "string" then
      line:highlight(bufnr, ns_id, linenr + row_start, byte_start)
    end
  end
end

return M
