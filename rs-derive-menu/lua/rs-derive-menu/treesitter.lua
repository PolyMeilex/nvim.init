--- @param s string
--- @return boolean
local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

--- @return TSNode | nil
local function search_for_struct(node)
  while node:type() ~= "struct_item" do
    node = node:parent()
    if not node then return nil end
  end

  return node
end

--- @return string | nil
local function attribute_ident(bufnr, attribute)
  local ident = attribute:child(0)
  if not ident then return nil end
  return vim.treesitter.get_node_text(ident, bufnr)
end

--- @return string | nil
local function attribute_item_ident(bufnr, attribute_item)
  local attribute = attribute_item:child(2)
  if not attribute then return nil end
  return attribute_ident(bufnr, attribute)
end

--- @return TSNode | nil
local function search_for_attribute_item(bufnr, node)
  while node:type() ~= "attribute_item" do
    node = node:parent()
    if not node then return nil end
  end

  if attribute_item_ident(bufnr, node) ~= "derive" then return nil end

  return node
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
  if not cursor_node then return end

  local attribute_item = search_for_attribute_item(bufnr, cursor_node)

  -- TODO: Make this smarter
  if not attribute_item then
    local struct = search_for_struct(cursor_node)

    if struct == nil then return nil end

    local sibling = struct:prev_sibling()

    local start_line = struct:start()

    if sibling ~= nil and sibling:type() == 'attribute_item' then
      attribute_item = sibling
    else
      return {
        bufnr = bufnr,
        derives = {},
        start_line = start_line,
        end_line = start_line,
        replace = false,
      }
    end
  end

  vim.print(attribute_item:type())

  local attribute = attribute_item:child(2)
  if attribute == nil then return nil end

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

  local out = "#[derive(" .. table.concat(derives, ", ") .. ")]"
  if info.replace then
    vim.api.nvim_buf_set_lines(info.bufnr, info.start_line, info.end_line + 1, false, { out })
  else
    vim.api.nvim_buf_set_lines(info.bufnr, info.start_line, info.end_line, false, { out })
  end
end

return M
