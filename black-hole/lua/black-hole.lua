local M = {}

--- Remap to black hole register
local function map(left, modes)
  local right = '"_' .. left
  for _, mode in pairs(modes) do
    vim.keymap.set(mode, left, right, { noremap = false, silent = true })
  end
end

function M.setup()
  map("c", { "n", "x" })
  map("cc", { "n" })
  map("C", { "n", "x" })
  map("d", { "n", "x" })
  map("dd", { "n" })
  map("D", { "n", "x" })
  map("x", { "n", "x" })
  map("X", { "n", "x" })

  vim.keymap.set("n", "m", "d")
  vim.keymap.set("x", "m", "d")

  vim.keymap.set("n", "mm", "dd")
  vim.keymap.set("n", "M", "D")
  vim.keymap.set("v", "P", "p")
  vim.keymap.set("v", "p", "P")
end

return M
