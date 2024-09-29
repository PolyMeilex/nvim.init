local Config = require("railgun.config")
local Db = require("railgun.db")

local M = {}

---@param config? RailgunConfig
function M.setup(config)
  config = Config.new(config)

  M.db = Db:new(config)

  vim.api.nvim_create_user_command("RailgunMark", function(opts)
    M.add(opts.args)
  end, { nargs = "?" })
end

---@param annotation? string
function M.add(annotation)
  if vim.trim(annotation or "") == "" then
    annotation = nil
  end

  local project = vim.loop.cwd()
  local buf = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local file = vim.api.nvim_buf_get_name(buf)

  if annotation == nil then
    annotation = vim.trim(vim.api.nvim_buf_get_text(buf, pos[1] - 1, 0, pos[1] - 1, -1, {})[1] or "Unknown")
  end

  M.db:add(project, file, pos[1], pos[2], annotation)
end

---@param file_path string
---@param line integer
---@param col integer
function M.remove(file_path, line, col)
  local project = vim.loop.cwd()
  M.db:remove(project, file_path, line, col)
end

return M
