---@class RailgunConfig
---@field data_path string

local M = {}

---@param config? RailgunConfig
---@return RailgunConfig
function M.new(config)
  config = config or {}
  config.data_path = config.data_path or vim.fn.stdpath("data") .. "/railgun"
  return config
end

return M
