local icons = require("poly.icons")

local harpoon_keys = { "h", "j", "k", "l", ";" }

local diagnostic_hls = {
  [vim.diagnostic.severity.ERROR] = "DiagnosticError",
  [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
  [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
  [vim.diagnostic.severity.HINT] = "DiagnosticHint",
}

local hidden_filetypes = {
  ["neo-tree"] = true,
  ["DiffviewFiles"] = true,
}

local function add_hl(hl, label)
  return "%#" .. hl .. "#" .. label .. "%*"
end

local function add_on_click(level, fn, component)
  return "%" .. level .. "@v:lua." .. fn .. "@" .. component .. "%X"
end

_G.my_harpoon_click_handler = function(minwid)
  require("harpoon"):list():select(minwid)
end

-- "a/b/c/d.lua" -> "b/c/d.lua"
local function short_path(path)
  local parts = {}
  for part in path:gmatch("[^/]+") do
    table.insert(parts, part)
  end
  return table.concat(parts, "/", math.max(1, #parts - 2))
end

local function hjkl_harpoon()
  local paths = {}
  for _, item in ipairs(require("harpoon"):list().items) do
    if item.value ~= "" then
      table.insert(paths, item.value)
    end
  end

  local current_filepath = vim.fn.expand("%:.")
  local tabs = {}

  for id = 1, math.min(#paths, #harpoon_keys) do
    local path = paths[id]
    local label_hl = path == current_filepath and "GruvboxGreenBold" or "GruvboxFg0"
    local tab = add_hl("GruvboxFg4", "[" .. harpoon_keys[id] .. "]") .. add_hl(label_hl, " " .. short_path(path) .. " ")
    table.insert(tabs, add_on_click(id, "my_harpoon_click_handler", tab))
  end

  return table.concat(tabs)
end

local function diagnostics_status()
  local count = vim.diagnostic.count(0)
  local list = {}

  for severity, hl in ipairs(diagnostic_hls) do
    local n = count[severity] or 0
    if n > 0 then
      table.insert(list, add_hl(hl, icons.diagnostic_signs[severity] .. n))
    end
  end

  if #list == 0 then
    return ""
  end

  local empty = add_hl("GruvboxFg0", " ")
  return empty .. table.concat(list, empty) .. empty
end

_G.my_winbar = function()
  if hidden_filetypes[vim.bo.filetype] then
    return ""
  end

  return require("lsp-code-context").get_label() .. "%=" .. hjkl_harpoon()
end

_G.my_statusline = function()
  if hidden_filetypes[vim.bo.filetype] then
    return ""
  end

  local file_status = vim.bo.modified and "[+] " or ""
  local right = add_hl("Comment", vim.lsp.status())
  return diagnostics_status() .. add_hl("GruvboxFg0", "%f " .. file_status) .. "%=" .. right
end

local M = {}

function M.setup()
  require("lsp-code-context").setup()

  require("harpoon"):extend({
    ADD = function()
      vim.cmd("redrawstatus!")
    end,
  })

  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    command = "redrawstatus!",
  })

  vim.api.nvim_create_autocmd("LspProgress", {
    command = "redrawstatus",
  })

  vim.o.winbar = "%{%v:lua.my_winbar()%}"
  vim.o.statusline = "%{%v:lua.my_statusline()%}"
end

return M
