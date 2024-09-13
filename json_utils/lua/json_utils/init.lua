local function get_keys(root)
  local keys = {}
  for node, name in root:iter_children() do
    if name == "key" then
      table.insert(keys, node)
    end

    if node:child_count() > 0 then
      for _, child in pairs(get_keys(node)) do
        table.insert(keys, child)
      end
    end
  end
  return keys
end

local function all_keys(bufnr)
  local tree = vim.treesitter.get_parser(bufnr, "json"):parse()[1]
  local root = tree:root()
  return get_keys(root)
end

local M = {}

M.is_json = function() return vim.bo.filetype == "json" end

M.setup = function()
  require("json_utils.lsp").register_bendec_lsp_autocmd()
end

-- Get all values from keys called `name`
M.values_for_key = function(name)
  if not M.is_json() then return {} end

  local bufnr = vim.api.nvim_get_current_buf()

  local out = {}
  for _, node in pairs(all_keys(bufnr)) do
    local key_as_string = vim.treesitter.get_node_text(node:child(1), bufnr)

    if key_as_string == name then
      local line, col = node:start()

      local parent = node:parent()
      local value = parent:field("value")[1]:child(1)
      local value_as_string = vim.treesitter.get_node_text(value, bufnr)
      table.insert(out, { line = line + 1, col = col, name = value_as_string });
    end
  end

  return out
end

M.find_key_value = function(bufnr, key, value)
  for _, node in pairs(all_keys(bufnr)) do
    local key_as_string = vim.treesitter.get_node_text(node:child(1), bufnr)

    if key_as_string == key then
      local line, col = node:start()

      local parent = node:parent()
      local v = parent:field("value")[1]:child(1)
      local value_as_string = vim.treesitter.get_node_text(v, bufnr)

      if value_as_string == value then
        return { line = line, col = col }
      end
    end
  end

  return nil
end

return M
