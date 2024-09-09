local Popup      = require("nui.popup")
local Line       = require("nui.line")
local Text       = require("nui.text")
local event      = require("nui.utils.autocmd").event
local NuiTree    = require("nui.tree")
local DeriveList = require("rs-derive-menu.derive_list")
local RustTree   = require("rs-derive-menu.treesitter")

---@param tree NuiTree
---@param parent? string
---@return integer
local function calculate_height(tree, parent)
  local nodes = tree:get_nodes(parent)
  local count = 0

  for _, node in pairs(nodes) do
    count = count + 1

    if node:is_expanded() then
      count = count + calculate_height(tree, node:get_id())
    end
  end

  return count
end

---@param tree NuiTree
---@param parent? string
---@return integer
local function calculate_max_height(tree, parent)
  local nodes = tree:get_nodes(parent)
  local count = 0

  for _, node in pairs(nodes) do
    count = count + 1

    if node:has_children() then
      count = count + calculate_height(tree, node:get_id())
    end
  end

  return count
end

local M = {}

local function build_popup()
  local popup = Popup({
    enter = true,
    relative = "cursor",
    position = {
      row = 1,
      col = 0,
    },
    size = {
      width = 30,
      height = 5,
    },
    win_options = {
      cursorline = true,
      scrolloff = 1,
      sidescrolloff = 0,
      winhighlight = "Normal:Pmenu",
    },
  })

  local items = DeriveList:new({
    NuiTree.Node({ name = "Default", on = false, keybind = "df" }),
    NuiTree.Node({ name = "Debug", on = false, keybind = "db" }),
    NuiTree.Node({ name = "Clone", on = false, keybind = "cl" }),
    NuiTree.Node({ name = "Copy", on = false, keybind = "cp" }),
    NuiTree.Node({ name = "Eq", on = false, keybind = "e" }),
    NuiTree.Node({ name = "Ord", on = false, keybind = "o" }),
    NuiTree.Node({ name = "Hash", on = false, keybind = "h" }),
    NuiTree.Node({ name = "PartialEq", on = false, }),
    NuiTree.Node({ name = "PartialOrd", on = false, }),
  })

  local rs_tree = RustTree.get_derives_at_cursor() or {}

  for _, v in pairs(rs_tree.derives or {}) do
    items:insert(NuiTree.Node({ name = v, on = true }))
  end

  local nodes = {}

  for _, node in pairs(items.list) do
    table.insert(nodes, node)
  end

  local tree = NuiTree({
    bufnr = popup.bufnr,
    nodes = nodes,
    prepare_node = function(node, _)
      if not node.name then
        error("missing node.name")
      end

      local lines = {}

      local line = Line()

      local indent = string.rep("  ", node._depth - 1)
      line:append(indent)

      if node.on then
        local checkbox = Text(" ")
        line:append(checkbox)
      else
        local checkbox = Text(" ", "GruvboxGray")
        line:append(checkbox)
      end

      line:append(node.name)

      if node:has_children() then
        line:append(node:is_expanded() and " " or " ")
      end

      if node.keybind ~= nil then
        vim.print(line:content(), #line:content())
        local len = #line:content() + #node.keybind

        local pad = string.rep(" ", popup.win_config.width - len)

        line:append(pad)
        line:append(Text("[" .. node.keybind .. "]", "Comment"))
      end

      table.insert(lines, line)


      return lines
    end
  })

  popup:update_layout({
    size = {
      height = calculate_height(tree),
      width = 30,
    }
  })

  local height = calculate_height(tree)

  local P = {
    tree = tree,
    popup = popup,
  }

  P.collapse = function()
    local node = tree:get_node()
    if node ~= nil then
      node:collapse()
      height = calculate_height(tree)
      popup:update_layout({
        size = {
          height = height,
          width = 30,
        }
      })

      vim.cmd('normal! zb')
      tree:render()
    end
  end

  P.expand = function()
    local node = tree:get_node()
    if node ~= nil then
      node:expand()
      height = calculate_height(tree)
      popup:update_layout({
        size = {
          height = height,
          width = 30,
        }
      })
      tree:render()
    end
  end

  P.focus_next = function()
    local linenr = unpack(vim.api.nvim_win_get_cursor(popup.winid))
    if linenr == height then
      vim.api.nvim_win_set_cursor(popup.winid, { 1, 0 })
    else
      vim.api.nvim_win_set_cursor(popup.winid, { linenr + 1, 0 })
    end
  end

  P.focus_prev = function()
    local linenr = unpack(vim.api.nvim_win_get_cursor(popup.winid))
    if linenr == 1 then
      vim.api.nvim_win_set_cursor(popup.winid, { height, 0 })
    else
      vim.api.nvim_win_set_cursor(popup.winid, { linenr - 1, 0 })
    end
  end

  ---@param name string
  P.toggle_by_name = function(name)
    local item = items:get(name)

    if item == nil then return end

    item.on = not item.on

    if item.name == "Eq" then
      items:get("PartialEq").on = item.on
    elseif item.name == "Ord" then
      items:get("PartialOrd").on = item.on
    end

    tree:render()

    RustTree.replace_derive(rs_tree.bufnr, rs_tree.start_line, rs_tree.end_line, items)
  end

  P.toggle = function()
    local node = tree:get_node()

    if node == nil then return end

    node.on = not node.on

    if node.name == "Eq" then
      items:get("PartialEq").on = node.on
    elseif node.name == "Ord" then
      items:get("PartialOrd").on = node.on
    end

    tree:render()

    RustTree.replace_derive(rs_tree.bufnr, rs_tree.start_line, rs_tree.end_line, items)
  end

  return P
end

M.open = function()
  local derive_popup = build_popup()

  derive_popup.popup:map("n", "h", function()
    derive_popup.collapse()
  end)

  derive_popup.popup:map("n", "l", function()
    derive_popup.expand()
  end)

  derive_popup.popup:map("n", "j", function()
    derive_popup.focus_next()
  end)

  derive_popup.popup:map("n", "k", function()
    derive_popup.focus_prev()
  end)

  derive_popup.popup:map("n", { "<CR>", "<Space>" }, function()
    derive_popup.toggle()
  end, { nowait = true })

  derive_popup.popup:map("n", { "gd", "dg", "<S-v>" }, "<Nop>")

  local toggles = {
    { "db", "Debug" },
    { "df", "Default" },
    { "e",  "Eq" },
    { "o",  "Ord" },
    { "h",  "Hash" },
    { "cl", "Clone" },
    { "cp", "Copy" },
  }

  for _, toggle in pairs(toggles) do
    derive_popup.popup:map("n", toggle[1], function()
      derive_popup.toggle_by_name(toggle[2])
    end, { noremap = true, nowait = true })
  end

  derive_popup.popup:map("n", { "<esc>", "q" }, function()
    derive_popup.popup:unmount()
  end, { noremap = true })

  derive_popup.popup:on(event.BufLeave, function()
    derive_popup.popup:unmount()
  end)

  derive_popup.popup:mount()
  derive_popup.tree:render()
end

M.setup = function()
  vim.keymap.set('n', '<leader>cd', M.open, {})
end

return M
