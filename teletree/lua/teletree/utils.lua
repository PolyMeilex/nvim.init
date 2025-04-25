local M = {}

function M.split_path(path)
  local separator = package.config:sub(1, 1) -- Returns "/" on Unix, "\\" on Windows
  local segments = vim.split(path, separator, { plain = true, trimempty = true })
  return segments
end

function M.path_last_segment(path)
  local split = M.split_path(path)
  return split[#split]
end

return M
