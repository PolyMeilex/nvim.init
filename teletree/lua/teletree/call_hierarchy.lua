local NuiTree = require("renui.tree")

local function init_window(bufnr)
  local P = {
    bufnr = bufnr,
  }

  ---@param width number
  ---@param height number
  P.open = function(row, col, width, height)
    local opts = {
      style = "minimal",
      relative = "editor",
      width = math.floor(width),
      height = math.floor(height),
      row = row,
      col = col,
      border = "rounded",
    }

    P.winid = vim.api.nvim_open_win(P.bufnr, true, opts)
    vim.wo[P.winid].cursorline = true
    vim.wo[P.winid].number = true
    vim.wo[P.winid].relativenumber = true
    vim.wo[P.winid].wrap = false

    if false then
      vim.api.nvim_create_autocmd("BufLeave", {
        buffer = P.bufnr,
        callback = function()
          P.close()
        end,
      })
    end
  end

  P.close = function()
    if P.winid ~= nil and vim.api.nvim_win_is_valid(P.winid) then
      vim.api.nvim_win_close(P.winid, true)
      P.winid = nil
    end
  end

  return P
end

local M = {}

--- @param client vim.lsp.Client
--- @param bufnr integer
--- @param params lsp.TextDocumentPositionParams
local function prepare_call_hierarchy(client, bufnr, params)
  local result, err = client:request_sync("textDocument/prepareCallHierarchy", params, nil, bufnr)

  if err or not result or result.err then
    return nil
  end

  return result
end

--- @param client vim.lsp.Client
--- @param bufnr integer
--- @param item table LSP request params.
local function incoming_calls(client, bufnr, item)
  local result, err = client:request_sync("callHierarchy/incomingCalls", { item = item }, nil, bufnr)

  if err or not result or result.err then
    return nil
  end

  return result
end

--- @param client vim.lsp.Client
--- @param bufnr integer
--- @param params lsp.TextDocumentPositionParams
--- @return lsp.CallHierarchyIncomingCall[] | nil
local function prepare_and_get_incoming_calls(client, bufnr, params)
  local items = prepare_call_hierarchy(client, bufnr, params)
  if not items then
    return nil
  end

  local calls = incoming_calls(client, bufnr, items.result[1])
  if not calls then
    return nil
  end

  return calls.result
end

---@param bufnr integer
---@return vim.lsp.Client | nil
local function find_client(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, client in ipairs(clients) do
    if client:supports_method("textDocument/prepareCallHierarchy", bufnr) then
      return client
    end
  end
  return nil
end

--- @param client vim.lsp.Client
--- @param bufnr integer
--- @param params lsp.TextDocumentPositionParams
function M.request_tree(client, bufnr, params)
  local calls = prepare_and_get_incoming_calls(client, bufnr, params)
  if not calls then
    return
  end

  local nodes = {}

  for _, value in pairs(calls) do
    local from = value.from

    local children = M.request_tree(client, bufnr, {
      textDocument = { uri = from.uri },
      position = from.selectionRange.start,
    })

    local node = NuiTree.Node({
      id = from.name .. from.detail .. from.uri .. tostring(from),
      text = from.name,
      range = value.fromRanges[1],
      uri = from.uri,
    }, children)
    node:expand()
    table.insert(nodes, node)
  end

  return nodes
end

function M.call()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  local client = find_client(bufnr)
  if not client then
    return
  end

  local nodes = M.request_tree(client, bufnr, vim.lsp.util.make_position_params(win, client.offset_encoding))

  local source_win = win

  bufnr = vim.api.nvim_create_buf(false, true)

  local window = init_window(bufnr)

  local tree = NuiTree:new({
    bufnr = bufnr,
    nodes = nodes,
    get_node_id = function(node)
      return node.id
    end,
  })

  tree:render()

  local namespace = vim.api.nvim_create_namespace("call_hierarchy.hlyank")

  local function jump_to_symbol()
    local node = tree:get_node()

    if not node or not node.range then
      return
    end

    vim.api.nvim_set_current_win(source_win)

    vim.cmd("edit " .. node.uri)

    local pos = node.range.start
    vim.api.nvim_win_set_cursor(source_win, { pos.line + 1, pos.character })
    vim.cmd([[normal! zz']])

    vim.hl.range(vim.api.nvim_win_get_buf(source_win), namespace, "YankIncSearch", { pos.line, 0 }, { pos.line, -1 }, {
      inclusive = true,
      timeout = 500,
    })

    vim.api.nvim_set_current_win(window.winid)
  end

  vim.keymap.set("n", "<CR>", jump_to_symbol, { buffer = bufnr, nowait = true })
  vim.keymap.set("n", "<Esc>", window.close, { buffer = bufnr, nowait = true })

  local editor_width = vim.o.columns
  local editor_height = vim.o.lines

  local win_width = editor_width / 5
  local win_height = editor_height - 5

  -- Calculate centered position.
  local row = math.floor((editor_height - win_height) / 2 - 1)
  local col = editor_width - win_width

  window.open(row, col, win_width, win_height)
end

function M.setup()
  vim.api.nvim_create_user_command("CallHierarchy", M.call, {})
end

return M
