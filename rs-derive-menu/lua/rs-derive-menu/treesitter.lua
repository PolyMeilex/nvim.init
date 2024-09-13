local parsers = require("nvim-treesitter.parsers")

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

M.get_derives_at_cursor = function()
  local bufnr = vim.api.nvim_get_current_buf()

  local cursor_node = vim.treesitter.get_node()
  if not cursor_node then return end

  local attribute_item = search_for_attribute_item(bufnr, cursor_node)

  -- TODO: Make this smarter
  if not attribute_item then
    attribute_item = search_for_struct(cursor_node)

    if attribute_item == nil then return nil end

    attribute_item = attribute_item:prev_sibling()

    if attribute_item == nil then return nil end
  end

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
  }
end

--- @param bufnr integer
--- @param start_line integer
--- @param end_line integer
--- @param derive_list DeriveList
M.replace_derive = function(bufnr, start_line, end_line, derive_list)
  local derives = {}

  for _, v in pairs(derive_list.list) do
    if v.on == true then
      table.insert(derives, v.name)
    end
  end

  local out = "#[derive(" .. table.concat(derives, ", ") .. ")]"
  vim.api.nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, { out })
end

return M
