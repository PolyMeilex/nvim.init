local Line = require("renui.line")
local Text = require("renui.text")
local NuiTree = require("renui.tree")
local DeriveList = require("rs-derive-menu.derive_list")
local RustTree = require("rs-derive-menu.treesitter")

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

local function init_window()
  local P = {
    bufnr = vim.api.nvim_create_buf(false, true),
  }

  ---@param height intager
  P.open = function(height)
    local opts = {
      relative = "cursor",
      row = 1, -- 1 line below the cursor
      col = 0, -- Same column as the cursor
      width = 30,
      height = height,
      style = "minimal", -- no line numbers, etc.
    }

    P.winid = vim.api.nvim_open_win(P.bufnr, true, opts)
    vim.api.nvim_set_option_value("cursorline", true, { win = P.winid })
    vim.api.nvim_set_option_value("scrolloff", 1, { win = P.winid })
    vim.api.nvim_set_option_value("sidescrolloff", 0, { win = P.winid })
    vim.api.nvim_set_option_value("winhighlight", "Normal:Pmenu", { win = P.winid })

    vim.api.nvim_create_autocmd("BufLeave", {
      buffer = P.bufnr,
      callback = function()
        P.close()
      end,
    })
  end

  P.close = function()
    if vim.api.nvim_win_is_valid(P.winid) then
      vim.api.nvim_win_close(P.winid, true)
    end
    if vim.api.nvim_buf_is_valid(P.bufnr) then
      vim.api.nvim_buf_delete(P.bufnr, { force = true })
    end
  end

  P.set_size = function(width, height)
    vim.api.nvim_win_set_config(P.winid, {
      width = width,
      height = height,
    })
  end

  return P
end

local function build_popup()
  local items = DeriveList:new({
    NuiTree.Node({ name = "Default", on = false, keybind = "df" }),
    NuiTree.Node({ name = "Debug", on = false, keybind = "db" }),
    NuiTree.Node({ name = "Clone", on = false, keybind = "cl" }),
    NuiTree.Node({ name = "Copy", on = false, keybind = "cp" }),
    NuiTree.Node({ name = "Eq", on = false, keybind = "e", link = "PartialEq" }),
    NuiTree.Node({ name = "Ord", on = false, keybind = "o", link = "PartialOrd" }),
    NuiTree.Node({ name = "Hash", on = false, keybind = "h" }),
    NuiTree.Node({ name = "PartialEq", on = false }),
    NuiTree.Node({ name = "PartialOrd", on = false }),
  })

  local rs_tree = RustTree.get_derives_at_cursor()
  if not rs_tree then
    return
  end

  for _, v in pairs(rs_tree.derives or {}) do
    items:insert(NuiTree.Node({ name = v, on = true }))
  end

  local P = {
    popup = init_window(),
  }

  P.bufnr = function()
    return P.popup.bufnr
  end

  P.winid = function()
    if P.popup.winid == nil then
      return error("Window not oppened yet")
    end
    return P.popup.winid
  end

  P.open = function()
    P.popup.open(P.height)
  end

  P.close = function()
    P.popup.close()
  end

  P.tree = NuiTree:new({
    bufnr = P.bufnr(),
    nodes = items.list,
    prepare_node = function(node, _)
      if not node.name then
        error("missing node.name")
      end

      local line = Line:new()

      local indent = string.rep("  ", node._depth - 1)
      line:append(indent)

      if node.on then
        local checkbox = Text:new(" ")
        line:append(checkbox)
      else
        local checkbox = Text:new(" ", "GruvboxGray")
        line:append(checkbox)
      end

      line:append(node.name)

      if node:has_children() then
        line:append(node:is_expanded() and " " or " ")
      end

      if node.keybind ~= nil then
        local len = #line:content() + #node.keybind

        local pad = string.rep(" ", 30 - len)

        line:append(pad)
        line:append(Text:new("[" .. node.keybind .. "]", "Comment"))
      end

      return { line }
    end,
  })

  P.calculate_height = function()
    return calculate_height(P.tree)
  end

  P.height = P.calculate_height()

  P.collapse = function()
    local node = P.tree:get_node()
    if node ~= nil then
      node:collapse()

      P.height = P.calculate_height()
      P.popup.set_size(30, P.height)
      P.tree:render()

      vim.cmd("normal! zb")
    end
  end

  P.expand = function()
    local node = P.tree:get_node()
    if node ~= nil then
      node:expand()

      P.height = P.calculate_height()
      P.popup.set_size(30, P.height)
      P.tree:render()
    end
  end

  P.focus_next = function()
    local linenr = unpack(vim.api.nvim_win_get_cursor(P.winid()))
    if linenr == P.height then
      vim.api.nvim_win_set_cursor(P.winid(), { 1, 0 })
    else
      vim.api.nvim_win_set_cursor(P.winid(), { linenr + 1, 0 })
    end
  end

  P.focus_prev = function()
    local linenr = unpack(vim.api.nvim_win_get_cursor(P.winid()))
    if linenr == 1 then
      vim.api.nvim_win_set_cursor(P.winid(), { P.height, 0 })
    else
      vim.api.nvim_win_set_cursor(P.winid(), { linenr - 1, 0 })
    end
  end

  ---@param name string
  P.toggle_by_name = function(name)
    local item = items:get(name)

    if item == nil then
      return
    end

    item.on = not item.on

    if item.link ~= nil then
      items:get(item.link).on = item.on
    end

    P.tree:render()

    RustTree.replace_derive(rs_tree, items)
    rs_tree.replace = true
  end

  P.toggle = function()
    local node = P.tree:get_node()

    if node == nil then
      return
    end

    node.on = not node.on

    if node.link ~= nil then
      items:get(node.link).on = node.on
    end

    P.tree:render()

    RustTree.replace_derive(rs_tree, items)
    rs_tree.replace = true
  end

  return P
end

M.open = function()
  local derive_popup = build_popup()
  if not derive_popup then
    return
  end
  local ops = { buffer = derive_popup.bufnr(), nowait = true }

  vim.keymap.set("n", "h", derive_popup.collapse, ops)
  vim.keymap.set("n", "l", derive_popup.expand, ops)
  vim.keymap.set("n", "j", derive_popup.focus_next, ops)
  vim.keymap.set("n", "k", derive_popup.focus_prev, ops)

  for _, lhs in pairs({ "<CR>", "<Space>" }) do
    vim.keymap.set("n", lhs, derive_popup.toggle, ops)
  end

  for _, lhs in pairs({ "gd", "dg", "<S-v>" }) do
    vim.keymap.set("n", lhs, "<Nop>", ops)
  end

  -- TODO: Nested nodes
  for _, node in pairs(derive_popup.tree:get_nodes()) do
    if node.keybind ~= nil then
      vim.keymap.set("n", node.keybind, function()
        derive_popup.toggle_by_name(node.name)
      end, ops)
    end
  end

  for _, lhs in pairs({ "<esc>", "q" }) do
    vim.keymap.set("n", lhs, derive_popup.close, ops)
  end

  derive_popup.tree:render()
  derive_popup.open()
end

M.setup = function()
  vim.keymap.set("n", "<leader>cd", M.open, {})
end

return M
