-- LRU cache
local LRUCache = {}

-- Node constructor
local function new_node(key, value)
  return { key = key, value = value, prev = nil, next = nil }
end

function LRUCache:new(max_size)
  local obj = {
    cache = {},
    head = nil,
    tail = nil,
    max_size = max_size or 100,
    size = 0,
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

-- Move node to the head of the list
function LRUCache:move_to_head(node)
  if node == self.head then
    return
  end
  self:remove(node)
  self:add_to_head(node)
end

-- Add node to the head of the list
function LRUCache:add_to_head(node)
  node.next = self.head
  node.prev = nil
  if self.head then
    self.head.prev = node
  end
  self.head = node
  if not self.tail then
    self.tail = node
  end
  self.size = self.size + 1
end

-- Remove node from the list
function LRUCache:remove(node)
  if node.prev then
    node.prev.next = node.next
  else
    self.head = node.next
  end
  if node.next then
    node.next.prev = node.prev
  else
    self.tail = node.prev
  end
  self.size = self.size - 1
end

-- Remove the tail node
function LRUCache:remove_tail()
  if not self.tail then
    return nil
  end
  local tail_node = self.tail
  self:remove(tail_node)
  return tail_node
end

-- Get the value of a key
function LRUCache:get(key)
  local node = self.cache[key]
  if not node then
    return nil
  end
  self:move_to_head(node)
  return node.value
end

-- Put a key-value pair into the cache
function LRUCache:put(key, value)
  local node = self.cache[key]
  if node then
    node.value = value
    self:move_to_head(node)
  else
    if self.size >= self.max_size then
      local tail_node = self:remove_tail()
      if tail_node then
        self.cache[tail_node.key] = nil
      end
    end
    local newNode = new_node(key, value)
    self:add_to_head(newNode)
    self.cache[key] = newNode
  end
end

return LRUCache
