local treesitter = require("json_utils.treesitter")

local M = {}

---@param node TSNode
---@return lsp.Range
local function lsp_node_range(node)
  local line, col = node:start()
  local end_line, end_col = node:end_()

  return {
    start = {
      line = line,
      character = col,
    },
    ["end"] = {
      line = end_line,
      character = end_col,
    },
  }
end

---@param bufnr integer
---@param object TSNode
---@return lsp.DocumentSymbol?
local function build_bendec_symbol(bufnr, object)
  assert(object:type() == "object")

  local kind = nil
  local name = nil
  local description = nil
  local fields = {}

  for key, value in treesitter.parse_object(bufnr, object) do
    if key == "kind" then
      kind = treesitter.parse_string(bufnr, value)
    elseif key == "name" then
      name = treesitter.parse_string(bufnr, value)
    elseif key == "description" then
      description = treesitter.parse_string(bufnr, value)
    elseif key == "fields" then
      for field, _ in value:iter_children() do
        if field:type() == "object" then
          table.insert(fields, M.build_bendec_object_field(bufnr, field))
        end
      end
    end
  end

  if kind == nil or name == nil then
    return nil
  end

  local range = lsp_node_range(object)

  local symbol_kind = vim.lsp.protocol.SymbolKind.Field
  if kind == "Struct" then
    symbol_kind = vim.lsp.protocol.SymbolKind.Object
  elseif kind == "Enum" then
    symbol_kind = vim.lsp.protocol.SymbolKind.Enum
  elseif kind == "Primitive" then
    symbol_kind = vim.lsp.protocol.SymbolKind.Number
  end

  return {
    kind = symbol_kind,
    name = name,
    detail = description,
    children = fields,
    range = range,
    selectionRange = range,
  }
end

---@param bufnr integer
---@param object TSNode
---@return lsp.DocumentSymbol
function M.build_bendec_object_field(bufnr, object)
  assert(object:type() == "object")

  local name = nil
  local type = nil
  local description = nil

  for key, value in treesitter.parse_object(bufnr, object) do
    if key == "name" then
      name = treesitter.parse_string(bufnr, value)
    elseif key == "type" then
      type = treesitter.parse_string(bufnr, value)
    elseif key == "description" then
      description = treesitter.parse_string(bufnr, value)
    end
  end

  local range = lsp_node_range(object)

  return {
    name = name,
    detail = type or description or "",
    kind = vim.lsp.protocol.SymbolKind.Field,
    range = range,
    selectionRange = range,
    children = {},
  }
end

---@return lsp.DocumentSymbol[]
function M.build_json_array(bufnr, node)
  assert(node:type() == "array")

  local res = {}

  for child, _ in node:iter_children() do
    if child:type() == "object" then
      vim.list_extend(res, M.build_json_object(bufnr, child))
    elseif child:type() == "array" then
      vim.list_extend(res, M.build_json_array(bufnr, child))
    end
  end

  return res
end

---@return lsp.DocumentSymbol[]
function M.build_json_object(bufnr, node)
  assert(node:type() == "object")

  local res = {}

  local bendec_symbol = build_bendec_symbol(bufnr, node)

  if bendec_symbol then
    table.insert(res, bendec_symbol)
  else
    for child, _ in node:iter_children() do
      if child:type() == "pair" then
        local value = child:field("value")[1]
        vim.list_extend(res, M.build_json_conteiner(bufnr, value))
      end
    end
  end

  return res
end

---@return lsp.DocumentSymbol[]
function M.build_json_conteiner(bufnr, node)
  if node:type() ~= "object" and node:type() ~= "array" then
    return {}
  end

  local res = {}

  if node:type() == "object" then
    vim.list_extend(res, M.build_json_object(bufnr, node))
  elseif node:type() == "array" then
    vim.list_extend(res, M.build_json_array(bufnr, node))
  end

  return res
end

return M
