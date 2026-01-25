function _G.MyInsideOperator(start_char, end_char)
  local pos = vim.api.nvim_win_get_cursor(0)

  local line = vim.fn.getline(".")

  local s, e = line:find(start_char .. "([^" .. end_char .. "]+)" .. end_char)

  if s == nil or e == nil then
    vim.cmd("normal! \28\14") -- `<C-\><C-n>`
    return
  end

  vim.cmd("noautocmd normal! v")
  vim.api.nvim_win_set_cursor(0, { pos[1], s })
  vim.cmd("noautocmd normal! o")
  vim.api.nvim_win_set_cursor(0, { pos[1], e - 2 })
end

local function inside_motion()
  local res = vim.fn.getcharstr()

  -- 'ci|' binding for rust development
  if res == "|" then
    return "<cmd>lua MyInsideOperator('|', '|')<CR>"
  end

  return "i" .. res
end

local M = {}

function M.setup()
  vim.keymap.set("o", "i", inside_motion, { expr = true, desc = "Augmented inside motion" })
end

return M
