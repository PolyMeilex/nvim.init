local NuiTree = require("nui.tree")
local NuiLine = require("nui.line")
local window = require("teletree.window")

local M = {}

local icons = {
  [1] = "󰈙 ", -- File
  [2] = " ", -- Module
  [3] = "󰌗 ", -- Namespace
  [4] = " ", -- Package
  [5] = "󰌗 ", -- Class
  [6] = "󰊕 ", -- Method
  [7] = " ", -- Property
  [8] = " ", -- Field
  [9] = " ", -- Constructor
  [10] = "󰕘 ", -- Enum
  [11] = "󰕘 ", -- Interface
  [12] = "󰊕 ", -- Function
  [13] = "󰆧 ", -- Variable
  [14] = "󰏿 ", -- Constant
  [15] = "󰀬 ", -- String
  [16] = "󰎠 ", -- Number
  [17] = "◩ ", -- Boolean
  [18] = "󰅪 ", -- Array
  [19] = "󰅩 ", -- Object
  [20] = "󰌋 ", -- Key
  [21] = "󰟢 ", -- Null
  [22] = " ", -- EnumMember
  [23] = "󰌗 ", -- Struct
  [24] = " ", -- Event
  [25] = "󰆕 ", -- Operator
  [26] = "󰊄 ", -- TypeParameter
  [255] = "󰉨 ", -- Macro
}

local lsp_num_to_str = {
  [1] = "File",
  [2] = "Module",
  [3] = "Namespace",
  [4] = "Package",
  [5] = "Class",
  [6] = "Method",
  [7] = "Property",
  [8] = "Field",
  [9] = "Constructor",
  [10] = "Enum",
  [11] = "Interface",
  [12] = "Function",
  [13] = "Variable",
  [14] = "Constant",
  [15] = "String",
  [16] = "Number",
  [17] = "Boolean",
  [18] = "Array",
  [19] = "Object",
  [20] = "Key",
  [21] = "Null",
  [22] = "EnumMember",
  [23] = "Struct",
  [24] = "Event",
  [25] = "Operator",
  [26] = "TypeParameter",
}

local i = 0
local function build_node(res)
  local name = res.name
  local children = {}

  for _, ch in pairs(res.children or {}) do
    table.insert(children, build_node(ch))
  end

  local detail = res.detail or ""
  -- Probably a bug in rust_analyzer, extra space after `fn(` in multiline signatures
  if vim.startswith(detail, "fn( ") then
    detail = detail:sub(1, 3) .. detail:sub(5)
  end

  i = i + 1

  local node = NuiTree.Node({
    id = i,
    name = name,
    kind = res.kind,
    text = icons[res.kind] .. name,
    detail = detail,
    range = res.range,
  }, children)

  if res.kind ~= 6 and res.kind ~= 12 then
    node:expand()
  end
  return node
end

function M.get(bufnr)
  bufnr = bufnr or 0
  i = 0

  local res, err = vim.lsp.buf_request_sync(
    bufnr,
    "textDocument/documentSymbol",
    { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  )

  if err then
    vim.notify(err)
    return {}
  end

  if res == nil then
    return {}
  end

  local out = {}

  for _, client in pairs(res) do
    if client.result then
      for _, n in pairs(client.result) do
        table.insert(out, build_node(n))
      end

      break
    end
  end

  return out
end

function M.create()
  local bufnr = vim.api.nvim_create_buf(false, true)

  local P = {}
  P.tree = NuiTree({
    bufnr = bufnr,
    nodes = {},
    get_node_id = function(node)
      return node.id
    end,
    prepare_node = function(node)
      local line = NuiLine()

      line:append(string.rep("│ ", node:get_depth() - 1), "GruvboxBg2")

      if node:has_children() then
        line:append(node:is_expanded() and " " or " ")
      else
        line:append("│ ", "GruvboxBg2")
      end

      line:append(node.text, "NavicIcons" .. lsp_num_to_str[node.kind])
      line:append(" " .. node.detail, "Comment")

      return line
    end,
  })
  P.path = nil
  P.bufnr = bufnr
  P.window = window.init_window(bufnr)
  P.source_buf = 0

  P.build_tree = function(source_buf)
    P.source_buf = source_buf
    P.tree:set_nodes(M.get(source_buf))
    P.tree:render()
  end

  P.refresh = function()
    P.build_tree(P.source_buf)
  end

  P.render = function()
    P.tree:render()
  end

  ---@param node_id_or_linenr? string | integer
  ---@return TeletreeNode|nil node
  ---@return nil|integer linenr
  ---@return nil|integer linenr
  P.get_node = function(node_id_or_linenr)
    return P.tree:get_node(node_id_or_linenr)
  end

  P.expand = function()
    local node = P.get_node()
    if node == nil then
      return
    end

    node:expand()
    P.render()
  end

  P.collapse = function()
    local node = P.get_node()
    if node == nil then
      return
    end

    if node:is_expanded() then
      node:collapse()
    else
      P.jump_to_parent()
    end

    P.render()
  end

  P.close = function()
    P.window.close()
  end

  P.jump_to_parent = function()
    local node = P.get_node()
    if node == nil then
      return
    end

    local parent_id = node:get_parent_id()
    if parent_id ~= nil then
      local _, linenr = P.get_node(parent_id)
      if linenr ~= nil and P.window.winid ~= nil then
        vim.api.nvim_win_set_cursor(P.window.winid, { linenr, 0 })
      end
    end
  end

  P.jump_to_symbol = function()
    local node = P.get_node()

    if not node or not node.range then
      return
    end

    P.close()

    -- Find the window ID of the original source buffer
    local source_winid = vim.fn.bufwinid(P.source_buf)
    if source_winid == -1 then
      vim.notify("Original buffer window not found", vim.log.levels.WARN)
      return
    end

    vim.api.nvim_set_current_win(source_winid)

    local pos = node.range.start
    vim.api.nvim_win_set_cursor(source_winid, { pos.line + 1, pos.character })
  end

  P.open = function()
    if P.window.winid ~= nil then
      return
    end

    local editor_width = vim.o.columns
    local editor_height = vim.o.lines

    local win_width = editor_width / 2
    local win_height = editor_height - 5

    -- Calculate centered position.
    local row = math.floor((editor_height - win_height) / 2 - 1)
    local col = math.floor((editor_width - win_width) / 2)

    P.window.open(row, col, win_width, win_height)
  end

  P.map = function(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, { buffer = P.bufnr, nowait = true })
  end

  P.map("n", "<Esc>", P.close)
  P.map("n", "<F5>", P.refresh)

  P.map("n", "<Right>", P.expand)
  P.map("n", "l", P.expand)

  P.map("n", "<Left>", P.collapse)
  P.map("n", "h", P.collapse)
  P.map("n", "<CR>", P.jump_to_symbol)

  return P
end

function M.open(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local current = M.create()
  current.build_tree(bufnr)
  current.open()
end

return M
