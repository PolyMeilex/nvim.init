--- @param s string
--- @return boolean
local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

--- @return TSNode | nil
local function search_for_struct_or_enum(node)
  while node:type() ~= "struct_item" and node:type() ~= "enum_item" do
    node = node:parent()
    if not node then
      return nil
    end
  end

  return node
end

--- @return string | nil
local function attribute_ident(bufnr, attribute)
  local ident = attribute:child(0)
  if not ident then
    return nil
  end
  return vim.treesitter.get_node_text(ident, bufnr)
end

--- @return string | nil
local function attribute_item_ident(bufnr, attribute_item)
  local attribute = attribute_item:child(2)
  if not attribute then
    return nil
  end
  return attribute_ident(bufnr, attribute)
end

--- @return TSNode | nil
local function search_for_attribute_item(bufnr, node)
  while node:type() ~= "attribute_item" do
    node = node:parent()
    if not node then
      return nil
    end
  end

  if attribute_item_ident(bufnr, node) ~= "derive" then
    return nil
  end

  return node
end

--- @return TSNode[]
local function attribute_items_for_node(node)
  local siblings = {}
  local sibling = node:prev_sibling()

  while sibling:type() == "attribute_item" do
    table.insert(siblings, sibling)
    sibling = sibling:prev_sibling()
    if sibling == nil then
      break
    end
  end

  return siblings
end

--- @param attribute_items TSNode[]
--- @return TSNode | nil, boolean
local function searach_for_derive(bufnr, attribute_items)
  local last = nil

  for _, node in pairs(attribute_items) do
    last = node
    if attribute_item_ident(bufnr, last) == "derive" then
      return last, true
    end
  end

  return last, false
end

local M = {}

--- @class DeriveNodeInfo
--- @field bufnr integer
--- @field derives table
--- @field start_line integer
--- @field end_line integer
--- @field replace boolean

---@return DeriveNodeInfo | nil
M.get_derives_at_cursor = function()
  local bufnr = vim.api.nvim_get_current_buf()

  local cursor_node = vim.treesitter.get_node()
  if not cursor_node then
    return
  end

  local attribute_item = search_for_attribute_item(bufnr, cursor_node)

  -- TODO: Make this smarter
  if not attribute_item then
    local struct = search_for_struct_or_enum(cursor_node)

    if not struct then
      return nil
    end

    local attributes = attribute_items_for_node(struct)
    local last, found = searach_for_derive(bufnr, attributes)

    if found and last then
      attribute_item = last
    else
      if not last then
        last = struct
      end
      local start_line = last:start()

      return {
        bufnr = bufnr,
        derives = {},
        start_line = start_line,
        end_line = start_line,
        replace = false,
      }
    end
  end

  local attribute = attribute_item:child(2)
  if attribute == nil then
    return nil
  end

  local arguments_node = attribute:field("arguments")[1]

  local body = vim.treesitter.get_node_text(arguments_node, bufnr)

  body = string.sub(body, 2, string.len(body) - 1)

  local derives = {}

  for i in vim.gsplit(body, ",") do
    table.insert(derives, trim(i))
  end

  local start_line = attribute_item:start()
  local end_line = attribute_item:end_()

  return {
    bufnr = bufnr,
    derives = derives,
    start_line = start_line,
    end_line = end_line,
    replace = true,
  }
end

--- @param info DeriveNodeInfo
--- @param derive_list DeriveList
M.replace_derive = function(info, derive_list)
  local derives = {}

  for _, v in pairs(derive_list.list) do
    if v.on == true then
      table.insert(derives, v.name)
    end
  end

  local out = ""
  if #derives ~= 0 then
    out = "#[derive(" .. table.concat(derives, ", ") .. ")]"
  end

  if info.replace then
    vim.api.nvim_buf_set_lines(info.bufnr, info.start_line, info.end_line + 1, false, { out })
  else
    vim.api.nvim_buf_set_lines(info.bufnr, info.start_line, info.end_line, false, { out })
  end
end

return M
