---@type fun(motion: fun(motion: string): string)
local set_operatorfunc = vim.fn[vim.api.nvim_exec([[
  func s:set_opfunc(val)
    let &operatorfunc = a:val
  endfunc
  echon get(function('s:set_opfunc'), 'name')
]], true)]

local add_to_jumplist = function() vim.cmd([[normal! m']]) end

---@param node TSNode
local jump_to_node = function(node)
  add_to_jumplist()
  local row, col = node:start()
  vim.api.nvim_win_set_cursor(0, { row + 1, col })
end

local treesitter_parent = function()
  local cur_pos = vim.api.nvim_win_get_cursor(0)

  local node = vim.treesitter.get_node({ pos = { cur_pos[1] - 1, cur_pos[2] } })
  if node == nil then return end

  while true do
    local parent = node:parent()
    if parent == nil then return end

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
    if parent == nil then return end

    if parent:type() == 'block' then
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

---@param direction string
local treesitter_block = function(direction)
  local cur_pos = vim.api.nvim_win_get_cursor(0)

  local node = vim.treesitter.get_node({ pos = { cur_pos[1] - 1, cur_pos[2] } })
  if node == nil then return end

  if node:type() == 'block' then
    if direction == 'next' then
      node = next_search_block_child(node, cur_pos[1] - 1)
    elseif direction == 'prev' then
      node = prev_search_block_child(node, cur_pos[1] - 1)
    end
    if node == nil then return end
    jump_to_node(node)
    return
  end

  ---@param node TSNode
  ---@param next fun(TSNode): TSNode
  local function until_significant(node, next)
    while true do
      local n = next(node)
      if n == nil then break end

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

  local next_fn
  if direction == 'next' then
    next_fn = function(n) return n:next_named_sibling() end
  elseif direction == 'prev' then
    next_fn = function(n) return n:prev_named_sibling() end
  end

  local block, child = ascend_to_block(node)
  if child == nil then return end

  node = until_significant(child, next_fn)

  if node == nil then return end
  jump_to_node(node)
end

vim.keymap.set('n', ']q', ':cn<CR>', { silent = true })
vim.keymap.set('n', '[q', ':cp<CR>', { silent = true })

local dot_repeat = function(fn, ...)
  local args = ...
  ---@type fun(motion: string): string
  local op
  op = function(motion)
    if motion == nil then
      set_operatorfunc(op)
      return "g@ "
    end
    fn(args)
    return ''
  end

  return op
end

vim.keymap.set('n', '[p', dot_repeat(treesitter_parent), { expr = true })

vim.keymap.set('n', '[t', dot_repeat(treesitter_block, 'prev'), { expr = true })
vim.keymap.set('n', ']t', dot_repeat(treesitter_block, 'next'), { expr = true })

return {}
