local M = {}

function M.get_keys(root)
  local keys = {}
  for node, name in root:iter_children() do
    if name == "key" then
      table.insert(keys, node)
    end

    if node:child_count() > 0 then
      for _, child in pairs(M.get_keys(node)) do
        table.insert(keys, child)
      end
    end
  end
  return keys
end

function M.all_keys(bufnr)
  local tree = vim.treesitter.get_parser(bufnr, "json"):parse()[1]
  local root = tree:root()
  return M.get_keys(root)
end

function M.parse_string(bufnr, string)
  assert(string:type() == "string")
  return vim.treesitter.get_node_text(string:child(1), bufnr)
end

function M.parse_pair(bufnr, pair)
  assert(pair:type() == "pair")
  return M.parse_string(bufnr, pair:field("key")[1]), pair:field("value")[1]
end

function M.parse_object(bufnr, object)
  assert(object:type() == "object")

  local iter = object:iter_children()

  return function()
    while true do
      local child = iter()
      if child == nil then
        return
      end

      if child:type() == "pair" then
        return M.parse_pair(bufnr, child)
      end
    end
  end
end

return M
