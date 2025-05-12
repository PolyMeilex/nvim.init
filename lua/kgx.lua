local M = {}

---@param command string
function M.in_new_tab(command)
  local handle
  ---@diagnostic disable-next-line: missing-fields, missing-parameter
  handle = vim.loop.spawn("kgx", {
    args = {
      "--tab",
      "-e",
      "fish",
      "-C",
      command,
    },
    stdio = { nil, nil, nil },
    function()
      handle:close()
    end,
  })
end

return M
