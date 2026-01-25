local treesitter = require("json_utils.treesitter")
local bendec = require("json_utils.bendec")

local M = {}

M.is_json = function(buf)
  return vim.bo[buf or 0].filetype == "json"
end

M.setup = function()
  require("json_utils.lsp").register_bendec_lsp_autocmd()
end

M.bendec_symbols = function(bufnr)
  bufnr = bufnr or 0

  if M.is_json(bufnr) == false then
    return {}
  end

  local tree = vim.treesitter.get_parser(bufnr, "json"):parse()[1]
  local document = tree:root()
  assert(document:type() == "document")

  local root = document:child(0)

  if root == nil then
    return {}
  end

  return bendec.build_json_conteiner(bufnr, root)
end

M.find_key_value = function(bufnr, key, value)
  for _, node in pairs(treesitter.all_keys(bufnr)) do
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
