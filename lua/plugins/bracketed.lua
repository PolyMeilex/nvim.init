local add_to_jumplist = function()
  vim.cmd([[normal! m']])
end
local center_viewport = function()
  vim.cmd([[normal! zz']])
end

---@param node TSNode
local jump_to_node = function(node)
  add_to_jumplist()
  local row, col = node:start()
  vim.api.nvim_win_set_cursor(0, { row + 1, col })
end

local goto_parent = function()
  local cur_pos = vim.api.nvim_win_get_cursor(0)

  local node = vim.treesitter.get_node({ pos = { cur_pos[1] - 1, cur_pos[2] } })
  if node == nil then
    return
  end

  while true do
    local parent = node:parent()
    if parent == nil then
      return
    end

    local row, col = node:start()
    local parent_row, parent_col = parent:start()

    if row ~= parent_row or col ~= parent_col then
      jump_to_node(parent)
      break
    end

    node = parent
  end
end

---@param child_node TSNode
---@return TSNode | nil, TSNode | nil
local ascend_to_block = function(child_node)
  while true do
    local parent = child_node:parent()
    if parent == nil then
      return
    end

    if parent:type() == "block" then
      return parent, child_node
    else
      child_node = parent
    end
  end
end

---@param block TSNode
---@param row integer
---@return TSNode | nil
local next_search_block_child = function(block, row)
  for _, child in pairs(block:named_children()) do
    local child_row, _ = child:start()
    if child_row > row then
      return child
    end
  end
end

---@param block TSNode
---@param row integer
---@return TSNode | nil
local prev_search_block_child = function(block, row)
  for i = block:named_child_count() - 1, 0, -1 do
    local child = block:named_child(i)
    local child_end, _ = child:end_()
    if child_end < row then
      return child
    end
  end
end

---@param node TSNode
---@param next fun(TSNode): TSNode
local function until_significant(node, next)
  while true do
    local n = next(node)
    if n == nil then
      break
    end

    local prev_row, _ = node:start()
    local row, _ = n:start()

    if prev_row ~= nil then
      if math.abs(prev_row - row) > 1 then
        return n
      end
    end

    node = n
  end
end

---@param node TSNode
---@return boolean
local is_declaration_list = function(node)
  if node:type() == "declaration_list" then
    return true
  end
  -- Rust toplevel node
  if node:type() == "source_file" then
    return true
  end
  -- Lua toplevel node
  if node:type() == "chunk" then
    return true
  end
  return false
end

---@param child_node TSNode
---@return TSNode | nil, TSNode | nil
local ascend_to_declaration_list = function(child_node)
  while true do
    local parent = child_node:parent()
    if parent == nil then
      return
    end

    if is_declaration_list(parent) then
      return parent, child_node
    else
      child_node = parent
    end
  end
end

---@param direction string
local goto_sibling = function(direction)
  local cur_pos = vim.api.nvim_win_get_cursor(0)

  local node = vim.treesitter.get_node({ pos = { cur_pos[1] - 1, cur_pos[2] } })
  if node == nil then
    return
  end

  if node:type() == "block" or is_declaration_list(node) then
    if direction == "next" then
      node = next_search_block_child(node, cur_pos[1] - 1)
    elseif direction == "prev" then
      node = prev_search_block_child(node, cur_pos[1] - 1)
    end
    if node == nil then
      return
    end
    jump_to_node(node)

    if direction == "next" then
      center_viewport()
    end
    return
  end

  local next_fn
  if direction == "next" then
    next_fn = function(n)
      return n:next_named_sibling()
    end
  elseif direction == "prev" then
    next_fn = function(n)
      return n:prev_named_sibling()
    end
  end

  local block, child = ascend_to_block(node)
  if child == nil then
    block, child = ascend_to_declaration_list(node)
  end
  if child == nil then
    return
  end

  node = until_significant(child, next_fn)

  if node == nil then
    return
  end
  jump_to_node(node)

  if direction == "next" then
    center_viewport()
  end
end

vim.keymap.set("n", "]q", ":cn<CR>", { silent = true })
vim.keymap.set("n", "[q", ":cp<CR>", { silent = true })

local dot_repeat = require("dot_repeat")
vim.keymap.set("n", "[p", dot_repeat(goto_parent), { expr = true })
vim.keymap.set("n", "[s", dot_repeat(goto_sibling, "prev"), { expr = true })
vim.keymap.set("n", "]s", dot_repeat(goto_sibling, "next"), { expr = true })

return {}
