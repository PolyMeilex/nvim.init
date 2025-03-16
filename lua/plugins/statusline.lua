local IsNotVsCode = require("vscode").IsNotVsCode()

local function add_hl(hl, label)
  return "%#" .. hl .. "#" .. label .. "%*"
end

local function add_on_click(level, fn, component)
  return "%" .. level .. "@v:lua." .. fn .. "@" .. component .. "%X"
end

_G.my_harpoon_click_handler = function(minwid, _, _, _)
  local harpoon = require("harpoon")
  harpoon:list():select(minwid)
end

local function my_navic()
  local navic = require("lsp-code-context").get_location()

  if #navic == 0 then
    return ""
  end

  return navic
end

local function hjkl_harpoon()
  local harpoon = require("harpoon")

  local function filter_empty_string(list)
    local next = {}
    for idx = 1, #list do
      if list[idx].value ~= "" then
        table.insert(next, list[idx].value)
      end
    end

    return next
  end

  local function split(source, delimiters)
    local elements = {}
    local pattern = "([^" .. delimiters .. "]+)"
    string.gsub(source, pattern, function(value)
      elements[#elements + 1] = value
    end)
    return elements
  end

  local function add_fg_hl(label)
    return add_hl("GruvboxFg0", label)
  end

  local function add_key_hl(label)
    return add_hl("GruvboxFg4", label)
  end

  local function add_orange_hl(label)
    return add_hl("GruvboxGreenBold", label)
  end

  local function add_green_hl(label)
    return add_hl("GruvboxGreenBold", label)
  end

  local function add_click(level, component)
    return add_on_click(level, "my_harpoon_click_handler", component)
  end

  local list = filter_empty_string(harpoon:list().items)
  local current_filepath = vim.fn.expand("%:.")

  local function nth_item(id)
    local item = list[id]

    if item == nil then
      return ""
    end

    local path = split(item, "/")
    local label = ""

    if #path >= 3 then
      label = path[#path - 2] .. "/" .. path[#path - 1] .. "/" .. path[#path]
    elseif #path == 2 then
      label = path[#path - 1] .. "/" .. path[#path]
    elseif #path == 1 then
      label = path[#path]
    end

    label = " " .. label .. " "

    local key = "[_]"
    if id == 1 then
      key = "[h]"
    elseif id == 2 then
      key = "[j]"
    elseif id == 3 then
      key = "[k]"
    elseif id == 4 then
      key = "[l]"
    end

    if item == current_filepath then
      return add_key_hl(key) .. add_orange_hl(label)
    else
      return add_key_hl(key) .. add_fg_hl(label)
    end
  end

  local tabs = {}

  if #list >= 1 then
    table.insert(tabs, add_click(1, nth_item(1)))
  end

  if #list >= 2 then
    table.insert(tabs, add_click(2, nth_item(2)))
  end

  if #list >= 3 then
    table.insert(tabs, add_click(3, nth_item(3)))
  end

  if #list >= 4 then
    table.insert(tabs, add_click(4, nth_item(4)))
  end

  return table.concat(tabs, "")
end

local icons = {
  error = "󰅚 ",
  warn = "󰀪 ",
  info = "󰋽 ",
  hint = "󰌶 ",
}

local function diagnostics_status()
  local count = vim.diagnostic.count(0)
  local error_count = count[vim.diagnostic.severity.ERROR] or 0
  local warning_count = count[vim.diagnostic.severity.WARN] or 0
  local info_count = count[vim.diagnostic.severity.INFO] or 0
  local hint_count = count[vim.diagnostic.severity.HINT] or 0

  local list = {}

  if error_count > 0 then
    table.insert(list, add_hl("DiagnosticError", icons.error .. error_count))
  end

  if warning_count > 0 then
    table.insert(list, add_hl("DiagnosticWarn", icons.warn .. warning_count))
  end

  if info_count > 0 then
    table.insert(list, add_hl("DiagnosticInfo", icons.info .. info_count))
  end

  if hint_count > 0 then
    table.insert(list, add_hl("DiagnosticHint", icons.hint .. hint_count))
  end

  if #list > 0 then
    local empty = add_hl("GruvboxFg0", " ")
    return empty .. table.concat(list, empty) .. empty
  end

  return ""
end

_G.my_winbar = function()
  if vim.bo.filetype == "neo-tree" then
    return ""
  end

  if vim.bo.filetype == "DiffviewFiles" then
    return ""
  end

  return my_navic() .. "%=" .. hjkl_harpoon()
end

_G.my_git_blame_button = function()
  require("gitblame").toggle()
  vim.api.nvim_command("redrawstatus!")
end

_G.my_statusline = function()
  if vim.bo.filetype == "neo-tree" then
    return ""
  end

  if vim.bo.filetype == "DiffviewFiles" then
    return ""
  end

  local file_status = ""
  if vim.bo.modified then
    file_status = "[+] "
  end

  local git_icon = add_on_click(1, "my_git_blame_button", "")

  if vim.g.gitblame_enabled then
    git_icon = add_hl("GruvboxOrange", git_icon)
  else
    git_icon = add_hl("GruvboxFg0", git_icon)
  end

  return diagnostics_status() .. add_hl("GruvboxFg0", "%f " .. file_status) .. "%=" .. git_icon
end

return {
  dir = "~/.config/nvim/lsp-code-context",
  enabled = IsNotVsCode,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "ThePrimeagen/harpoon",
  },
  config = function()
    require("lsp-code-context").setup({
      highlight = true,
      click = true,
      lsp = {
        auto_attach = true,
      },
    })

    require("harpoon"):extend({
      ADD = function()
        vim.api.nvim_command("redrawstatus!")
      end,
    })

    vim.api.nvim_create_autocmd("DiagnosticChanged", {
      callback = function(_)
        vim.api.nvim_command("redrawstatus!")
      end,
    })

    vim.o.winbar = "%{%v:lua.my_winbar()%}"
    vim.o.statusline = "%{%v:lua.my_statusline()%}"
  end,
}
