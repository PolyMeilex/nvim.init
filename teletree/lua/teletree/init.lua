local NuiTree = require("nui.tree")
local async = require("plenary.async")
local Path = require("plenary.path")

local render = require("teletree.render")
local window = require("teletree.window")
local clipboard = require("teletree.clipboard")
local io = require("teletree.io")
local utils = require("teletree.utils")
local diagnostics = require("teletree.diagnostics")

---@class TeletreeNodeData
---@field text string
---@field type string
---@field path string
---@field is_directory boolean
---@field is_loaded boolean
---
---@alias TeletreeNode TeletreeNodeData | NuiTree.Node

---@param directory string
---@param tree NuiTree
---@return TeletreeNode[]
local function scandir_co(directory, tree)
  local res = io.readdir_co(directory)

  local out = {}

  ---@return TeletreeNode
  local function load_item(path, entry, expanded)
    ---@type TeletreeNodeData
    local node = {
      text = entry.name,
      type = entry.type,
      path = path,
      is_directory = entry.type == "directory",
      is_loaded = entry.type == "file",
      diagnostics = diagnostics.get(path),
    }

    local n
    if node.is_directory then
      local children = {}
      if expanded then
        children = scandir_co(node.path, tree)
      end

      n = NuiTree.Node(node, children)
      if expanded then
        n:expand()
      end
    else
      n = NuiTree.Node(node)
    end

    return n
  end

  for _, entry in pairs(res) do
    if entry.name ~= ".git" then
      local path = Path:new(directory, entry.name).filename

      ---@type TeletreeNode | nil
      local old_node = tree:get_node(path)
      local expanded = old_node ~= nil and old_node:is_expanded()

      local node = load_item(path, entry, expanded)
      table.insert(out, node)
    end
  end

  return out
end

---@param directory string
---@param tree NuiTree
---@return TeletreeNode[]
local function scandir_sync(directory, tree)
  local nodes = {}
  async.util.block_on(function()
    nodes = scandir_co(directory, tree)
  end, 5000)
  return nodes
end

local function strip_cwd_prefix(path, cwd)
  return Path:new(path):make_relative(cwd or vim.fn.getcwd())
end

---@param node TeletreeNode
---@param tree NuiTree
local function expand(node, tree)
  if not node.is_loaded then
    local nodes = scandir_sync(node.path, tree)
    tree:set_nodes(nodes, node:get_id())
    node.is_loaded = true
  end
  node:expand()
end

local M = {}

local function create()
  local bufnr = vim.api.nvim_create_buf(false, true)

  local P = {}
  P.tree = NuiTree({
    bufnr = bufnr,
    nodes = {},
    prepare_node = render.prepare_node,
    ---@param node TeletreeNode
    get_node_id = function(node)
      return node.path
    end,
  })
  P.path = nil
  P.bufnr = bufnr
  P.window = window.init_window(bufnr)

  P.build_tree = function(path, cb)
    diagnostics.load()

    P.path = path or vim.fn.getcwd()

    local nodes = scandir_sync(P.path, P.tree)
    P.tree:set_nodes(nodes)
    P.tree:render()

    cb()
  end

  P.refresh = function()
    P.build_tree(P.path, function() end)
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

  P.rename = function()
    local node = P.get_node()
    if node == nil then
      return
    end

    vim.ui.input({ prompt = "New Name: ", default = vim.fs.basename(node.path) }, function(res)
      if res == nil then
        return
      end

      res = vim.trim(res)
      if #res == 0 then
        return
      end

      ---@type Path
      local path = Path:new(node.path)
      ---@type Path
      local parent = path:parent()

      path:rename({ new_name = vim.fs.joinpath(parent.filename, res) })
      P.refresh()
    end)
  end

  P.new_file = function()
    local node = P.get_node()
    if node == nil then
      return
    end

    if not node.is_directory then
      node = P.get_node(node:get_parent_id())
    end

    if node == nil then
      return
    end

    vim.ui.input({ prompt = "New Name: " }, function(res)
      if res == nil then
        return
      end

      res = vim.trim(res)
      if #res == 0 then
        return
      end

      local is_dir = vim.endswith(res, "/")

      ---@type Path
      local parent = Path:new(node.path)
      if not parent:is_dir() then
        parent = parent:parent()
      end

      ---@type Path
      local destination = Path:new(parent, res)

      if is_dir then
        destination:mkdir({ parents = true })
      else
        destination:touch({ parents = true })
      end

      node:expand()
      P.refresh()
    end)
  end

  P.reveal_path = function(path)
    path = strip_cwd_prefix(path)
    local segments = utils.split_path(path)

    local node_id = nil

    local children = P.tree:get_nodes()
    for _, segment in ipairs(segments) do
      for _, child in ipairs(children) do
        if child.text == segment then
          P.expand(child)
          node_id = child:get_id()
          children = P.tree:get_nodes(node_id)
        end
      end
    end

    P.render()

    local _, linenr = P.get_node(node_id)

    if P.window.winid ~= nil and linenr ~= nil then
      vim.api.nvim_win_set_cursor(P.window.winid, { linenr, 0 })
    end
  end

  ---@param node TeletreeNode
  P.expand = function(node)
    expand(node, P.tree)
  end

  P.enter = function()
    local node = P.get_node()
    if node == nil then
      return
    end

    if node.is_directory then
      P.expand(node)
    else
      P.window.close()
      vim.api.nvim_command("edit " .. node.path)
    end

    P.render()
  end

  P.exit = function()
    local node = P.get_node()
    if node == nil then
      return
    end

    if node.is_directory and node:is_expanded() then
      node:collapse()
    else
      P.jump_to_parent()
    end

    P.render()
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

  P.delete = function()
    local node = P.get_node()
    if node == nil then
      return
    end

    vim.ui.input({ prompt = "Do you want to delete: " .. strip_cwd_prefix(node.path) .. "?" }, function(res)
      if res == "y" then
        local path = Path:new(node.path)
        path:rm({ recursive = path:is_dir() })
        P.refresh()
      end
    end)
  end

  P.copy = function()
    local node = P.get_node()
    if node == nil then
      return
    end

    clipboard.copy_to_clipboard(node.path)
  end

  P.paste = function()
    local node = P.get_node()
    if node == nil then
      return
    end

    if not node.is_directory then
      node = P.get_node(node:get_parent_id())
    end

    if node == nil then
      return
    end

    clipboard.paste_from_clipboard(node.path, function()
      P.refresh()
    end)
  end

  P.live_grep = function()
    local node = P.get_node()
    if node == nil then
      return
    end

    if node.is_directory then
      P.close()
      require("telescope.builtin").live_grep({ cwd = node.path })
    end
  end

  P.find_files = function()
    local node = P.get_node()
    if node == nil then
      return
    end

    if node.is_directory then
      P.close()
      require("telescope").extensions.omni_picker.omni_picker({ cwd = node.path })
    end
  end

  P.map("n", "<Esc>", P.close)
  P.map("n", "<F5>", P.refresh)

  P.map("n", "<Right>", P.enter)
  P.map("n", "l", P.enter)

  P.map("n", "<Left>", P.exit)
  P.map("n", "h", P.exit)

  P.map("n", "<S-h>", P.jump_to_parent)
  P.map("n", "<Enter>", P.enter)
  P.map("n", "r", P.rename)
  P.map("n", "a", P.new_file)
  P.map("n", "d", P.delete)
  P.map("n", "y", P.copy)
  P.map("n", "p", P.paste)
  P.map("n", "<S-f>", P.live_grep)
  P.map("n", "<c-f>", P.find_files)

  return P
end

M.current = nil

function M.open()
  local path = vim.fn.expand("%:p")

  if M.current == nil then
    M.current = create()
    M.current.build_tree(nil, function()
      M.current.open()
      M.current.reveal_path(path)
    end)
    return
  end

  M.current.open()
  M.current.reveal_path(path)
end

function M.setup()
  require("teletree.call_hierarchy").setup()
end

return M
