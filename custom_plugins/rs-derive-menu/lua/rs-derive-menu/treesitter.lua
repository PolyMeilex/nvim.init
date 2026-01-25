local parser = require("rs-derive-menu.parser")

--- @param s string
--- @return boolean
local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

local M = {}

--- @class DeriveNodeInfo
--- @field bufnr integer
--- @field derives table
--- @field start_line integer
--- @field end_line integer
--- @field replace boolean

--- @param ctx RustNodeContext
--- @return TSNode | nil
local function find_preexisting_derive(ctx)
  for _, node in pairs(ctx.attribute_items) do
    if parser.attribute_item_ident(ctx.bufnr, node) == "derive" then
      return node
    end
  end
  return nil
end

--- @return DeriveNodeInfo | nil
M.get_derives_at_cursor = function()
  local bufnr = vim.api.nvim_get_current_buf()

  local ctx = parser.parse(bufnr)
  if not ctx then
    return nil
  end

  local preexisting_derive = find_preexisting_derive(ctx)

  local attribute_item = preexisting_derive

  if not attribute_item then
    local struct = ctx.root

    if not struct then
      return nil
    end

    local last = ctx.attribute_items[#ctx.attribute_items] or struct
    local start_line = last:start()

    return {
      bufnr = bufnr,
      derives = {},
      start_line = start_line,
      end_line = start_line,
      replace = false,
    }
  end

  local attribute = parser.attribute_from_attribute_item(attribute_item)
  if attribute == nil then
    return nil
  end

  local arguments_node = parser.attribute_arguments(attribute)
  if arguments_node == nil then
    return nil
  end

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
