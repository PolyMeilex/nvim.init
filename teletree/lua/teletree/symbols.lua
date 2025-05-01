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
  [6] = "󰆧 ", -- Method
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

  i = i + 1
  local node = NuiTree.Node({ id = i, name = name, kind = res.kind, text = icons[res.kind] .. name }, children)
  node:expand()
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

  for client_id, client in pairs(res) do
    if vim.lsp.get_client_by_id(client_id).name ~= "rust_analyzer" and client.error and client.result then
    else
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

      return line
    end,
  })
  P.path = nil
  P.bufnr = bufnr
  P.window = window.init_window(bufnr)

  P.build_tree = function(bufnr)
    P.tree:set_nodes(M.get(bufnr))
    P.tree:render()
  end

  P.refresh = function()
    P.build_tree(0)
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

  P.close = function()
    P.window.close()
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

  return P
end

function M.open(bufnr)
  local current = M.create()
  current.build_tree(bufnr or 0)
  current.open()
end

return M
