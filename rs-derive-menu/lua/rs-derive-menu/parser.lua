local M = {}

--- @param node TSNode
local function is_struct_item(node)
  return node:type() == "struct_item"
end

--- @param node TSNode
local function is_enum_item(node)
  return node:type() == "enum_item"
end

--- @param node TSNode
local function is_union_item(node)
  return node:type() == "union_item"
end

--- @param node TSNode
local function is_attribute_item(node)
  return node:type() == "attribute_item"
end

--- @param node TSNode
local function is_comment(node)
  return node:type() == "line_comment" or node:type() == "block_comment"
end

--- @param node TSNode
local function is_struct_like(node)
  return is_struct_item(node) or is_enum_item(node) or is_union_item(node)
end

--- @param node TSNode
--- @param cb fun(TSNode): boolean
--- @return TSNode | nil
local function ascend_until(node, cb)
  while not cb(node) do
    local parent = node:parent()
    if not parent then
      return nil
    end
    node = parent
  end

  return node
end

--- @param node TSNode
--- @return TSNode | nil
local function ascend_for_attribute_item(node)
  return ascend_until(node, is_attribute_item)
end

--- @param node TSNode
--- @return TSNode | nil
local function ascend_for_struct_like(node)
  return ascend_until(node, function(n)
    return is_struct_like(n)
  end)
end

--- @param node TSNode
--- @param cb fun(TSNode): TSNode?
--- @return TSNode[]
local function sibling_attribute_items(node, cb)
  local sibling = cb(node)

  if not sibling then
    return {}
  end

  local siblings = {}
  while is_attribute_item(sibling) or is_comment(sibling) do
    if not is_comment(sibling) then
      table.insert(siblings, sibling)
    end
    sibling = cb(sibling)
    if sibling == nil then
      break
    end
  end

  return siblings
end

--- @param node TSNode
--- @return TSNode[]
local function sibling_attribute_items_before(node)
  return sibling_attribute_items(node, function(n)
    return n:prev_sibling()
  end)
end

--- @param node TSNode
--- @return TSNode[]
local function sibling_attribute_items_after(node)
  return sibling_attribute_items(node, function(n)
    return n:next_sibling()
  end)
end

--- @param node TSNode
--- @return TSNode?
local function sibling_struct_after(node)
  local sibling = node:next_sibling()

  if not sibling then
    return nil
  end

  while is_struct_like(sibling) or is_comment(sibling) do
    if is_struct_like(sibling) then
      return sibling
    end
    sibling = sibling:next_sibling()
    if sibling == nil then
      break
    end
  end

  return nil
end

--- @class RustNodeContext
--- @field root TSNode
--- @field attribute_items TSNode[]
--- @field bufnr number

---@param bufnr any
---@return RustNodeContext?
M.parse = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor_node = vim.treesitter.get_node()
  if not cursor_node then
    return nil
  end

  local attribute_item_under_cursor = ascend_for_attribute_item(cursor_node)

  if attribute_item_under_cursor then
    local before = sibling_attribute_items_before(attribute_item_under_cursor)
    table.insert(before, attribute_item_under_cursor)

    local after = sibling_attribute_items_after(attribute_item_under_cursor)
    local struct = nil
    if #after == 0 then
      struct = sibling_struct_after(attribute_item_under_cursor)
    else
      struct = sibling_struct_after(after[#after])
    end

    if not struct then
      error("Missing the struct/enum/union")
    end

    return {
      root = struct,
      attribute_items = vim.list_extend(before, after),
      bufnr = bufnr,
    }
  else
    local struct_under_cursor = ascend_for_struct_like(cursor_node)
    if not struct_under_cursor then
      return nil
    end

    local attribute_items = sibling_attribute_items_before(struct_under_cursor)

    return {
      root = struct_under_cursor,
      attribute_items = attribute_items,
      bufnr = bufnr,
    }
  end
end

--- @param attribute_item TSNode
--- @return TSNode | nil
function M.attribute_from_attribute_item(attribute_item)
  return attribute_item:child(2)
end

--- @param attribute TSNode
--- @return TSNode | nil
function M.attribute_arguments(attribute)
  return attribute:field("arguments")[1]
end

--- @return string | nil
function M.attribute_ident(bufnr, attribute)
  local ident = attribute:child(0)
  if not ident then
    return nil
  end
  return vim.treesitter.get_node_text(ident, bufnr)
end

--- @return string | nil
function M.attribute_item_ident(bufnr, attribute_item)
  local attribute = M.attribute_from_attribute_item(attribute_item)
  if not attribute then
    return nil
  end
  return M.attribute_ident(bufnr, attribute)
end

return M
