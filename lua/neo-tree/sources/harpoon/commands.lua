local cc = require("neo-tree.sources.common.commands")
local manager = require("neo-tree.sources.manager")

local vim = vim

local M = {}

M.refresh = function(state)
  manager.refresh("harpoon", state)
end

M.show_debug_info = function(state)
  print(vim.inspect(state))
end

cc._add_common_commands(M)
return M
