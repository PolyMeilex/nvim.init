local NuiTree = require("nui.tree")
local NuiLine = require("nui.line")
local web_devicons = require("nvim-web-devicons")

-- Utility function to scan a directory and return a table of entries.
local function scandir(directory)
  local results = {}
  local handle = vim.loop.fs_scandir(directory)
  if not handle then
    return results
  end
  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    if name ~= ".git" then
      table.insert(results, { name = name, type = type })
    end
  end

  local sorted = {}

  for index, entry in ipairs(results) do
    if entry.type == "directory" then
      table.insert(sorted, entry)
    end
  end

  for index, entry in ipairs(results) do
    if entry.type ~= "directory" then
      table.insert(sorted, entry)
    end
  end

  return sorted
end

-- Build a simple (non-recursive) file tree from the directory entries.
---@param directory string
---@param tree NuiTree | nil
---@return table
local function build_file_tree(directory, tree)
  local entries = scandir(directory)
  local nodes = {}
  for _, entry in ipairs(entries) do
    local node

    local path = directory .. "/" .. entry.name
    if entry.type == "directory" then
      local text = entry.name
      node = NuiTree.Node({ text = text, is_directory = true, path = path }, build_file_tree(path, tree))
    else
      local icon, highlight = web_devicons.get_icon(entry.name)
      local text = entry.name
      node = NuiTree.Node({ text = text, icon = icon, icon_highlight = highlight, is_directory = false, path = path })
    end

    local old_node = tree:get_node(path)
    if old_node ~= nil then
      if old_node:is_expanded() then
        node:expand()
      end
    end

    table.insert(nodes, node)
  end

  return nodes
end

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
      width = width,
      height = height,
      row = row,
      col = col,
      border = "rounded",
    }

    P.winid = vim.api.nvim_open_win(P.bufnr, true, opts)
    vim.wo[P.winid].cursorline = true
    vim.wo[P.winid].number = true
    vim.wo[P.winid].relativenumber = true
    -- vim.wo[P.winid].winhighlight = "Normal:Pmenu"

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
    -- if vim.api.nvim_buf_is_valid(P.bufnr) then
    --   vim.api.nvim_buf_delete(P.bufnr, { force = true })
    -- end
  end

  P.set_size = function(width, height)
    vim.api.nvim_win_set_config(P.winid, {
      width = width,
      height = height,
    })
  end

  return P
end

local function prepare_node(node, _)
  if not node.text then
    error("missing node.text")
  end

  local texts = node.text

  if type(node.text) ~= "table" or node.text.content then
    texts = { node.text }
  end

  local lines = {}

  for i, text in ipairs(texts) do
    local line = NuiLine()

    line:append(string.rep("  ", node._depth - 1))

    if node.is_directory then
      line:append(" ")
      if node:is_expanded() then
        line:append(" ", "GruvboxGreenBold")
      else
        line:append(" ", "GruvboxGreenBold")
      end
      line:append(text, "GruvboxGreenBold")
    else
      if node.icon then
        line:append(" ")
        line:append(node.icon, node.icon_highlight or "Normal")
        line:append(" ")
      else
        line:append(" ")
        line:append("")
        line:append(" ")
      end

      line:append(text)
    end

    table.insert(lines, line)
  end

  return lines
end

local M = {}

function M.create()
  local bufnr = vim.api.nvim_create_buf(false, true)

  local P = {}
  P.tree = NuiTree({
    bufnr = bufnr,
    nodes = {},
    prepare_node = prepare_node,
    get_node_id = function(node)
      return node.path
    end,
  })
  P.path = nil
  P.bufnr = bufnr
  P.window = init_window(bufnr)

  P.build_tree = function(path)
    P.path = path or vim.fn.getcwd()

    local nodes = build_file_tree(P.path, P.tree)
    P.tree:set_nodes(nodes)
    P.tree:render()
  end

  P.refresh = function()
    P.build_tree(P.path)
  end

  P.render = function()
    if P.tree ~= nil then
      P.tree:render()
    end
  end

  P.new_file = function()
    vim.ui.input({ prompt = "New Name: " }, function(res)
      vim.print(res)
    end)
  end

  local function split_path(path)
    local separator = package.config:sub(1, 1) -- Returns "/" on Unix, "\\" on Windows
    local segments = vim.split(path, separator, { plain = true, trimempty = true })
    return segments
  end

  local function strip_cwd_prefix(path, cwd)
    local cwd = cwd or vim.fn.getcwd()
    if path:sub(1, #cwd) == cwd then
      path = path:sub(#cwd + 2) -- Strip the cwd part and the following "/"
    end
    return path
  end

  P.reveal_path = function(path)
    if P.tree == nil then
      return
    end

    path = strip_cwd_prefix(path)
    local segments = split_path(path)

    local node_id = nil

    local children = P.tree:get_nodes()
    for _, segment in ipairs(segments) do
      for _, child in ipairs(children) do
        if child.text == segment then
          child:expand()
          node_id = child:get_id()
          children = P.tree:get_nodes(node_id)
        end
      end
    end

    P.render()

    local _, linenr = P.tree:get_node(node_id)

    if P.window.winid ~= nil and linenr ~= nil then
      vim.api.nvim_win_set_cursor(P.window.winid, { linenr, 0 })
    end
  end

  P.toggle = function()
    if P.tree == nil then
      return
    end

    local node = P.tree:get_node()

    if node == nil then
      return
    end

    if node:has_children() then
      if node:is_expanded() then
        node:collapse()
      else
        node:expand()
      end
    else
      P.window.close()
      vim.api.nvim_command("edit " .. node.path)
    end

    P.render()
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
    vim.keymap.set(mode, lhs, rhs, { buffer = P.bufnr })
  end

  P.delete = function()
    if P.tree == nil then
      return
    end

    local node = P.tree:get_node()

    if node == nil then
      return
    end

    vim.ui.input({ prompt = "Do you want to delete: " .. strip_cwd_prefix(node.path) .. "?" }, function(res)
      if res == "y" then
        vim.fn.system({ "rm", "-Rf", node.path })
        P.refresh()
      end
    end)
  end

  P.map("n", "<Esc>", P.close)
  P.map("n", "<F5>", P.refresh)
  P.map("n", "l", P.toggle)
  P.map("n", "h", P.toggle)
  P.map("n", "<Enter>", P.toggle)
  P.map("n", "a", P.reveal_path)
  P.map("n", "dd", P.delete)

  return P
end

M.current = nil

function M.setup()
  vim.keymap.set("n", "<C-e>", function()
    local path = vim.fn.expand("%:p")

    if M.current == nil then
      M.current = M.create()
      M.current.build_tree()
    end

    M.current.open()
    M.current.reveal_path(path)
  end)
end

return M
