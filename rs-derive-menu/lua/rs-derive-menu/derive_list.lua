--- @class DeriveList
--- @field list NuiTree.Node[]
local DeriveList = {}
DeriveList.__index = DeriveList

function DeriveList:new(list)
  return setmetatable({
    list = list or {},
  }, self)
end

function DeriveList:get(name)
  for _, v in pairs(self.list) do
    if v.name == name then
      return v
    end
  end

  return nil
end

function DeriveList:insert(node)
  for _, v in pairs(self.list) do
    if v.name == node.name then
      v.on = node.on
      return
    end
  end

  table.insert(self.list, node)
end

return DeriveList
