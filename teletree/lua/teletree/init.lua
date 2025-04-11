local NuiTree = require("nui.tree")
local NuiLine = require("nui.line")
local web_devicons = require("nvim-web-devicons")
local uv = vim.uv
local async = require("plenary.async")

local function copy_to_clipboard(text)
  vim.system({ "wl-copy", "-t", "text/uri-list" }, { stdin = text })
end

local function paste_from_clipboard(parent, done)
  vim.system({ "wl-paste", "-t", "text/uri-list" }, { text = true }, function(obj)
    if obj.code ~= 0 then
      print("Failed to paste from clipboard")
      return
    end

    local file_urls = vim.split(obj.stdout, "\n")
    for _, entry in pairs(file_urls) do
      local file_url = vim.trim(entry)

      if #file_url > 0 then
        vim.system({ "gio", "copy", "-b", file_url, parent }, {}, function(out)
          vim.schedule(done)
        end)
      end
    end
  end)
end

---@param list uv.fs_readdir.entry[]
local function sort_readdir_entries(list)
  table.sort(list, function(a, b)
    if a.type == b.type then
      return a.name < b.name
    else
      return a.type == "directory"
    end
  end)
end

---@param directory string
---@param cb fun(out: uv.fs_readdir.entry[])
local function readdir_async(directory, cb)
  local MAX = 1000

  uv.fs_opendir(directory, function(err, luv_dir)
    if err then
      return
    end

    local out = {}

    ---@param _err string?
    ---@param res uv.fs_readdir.entry[]
    local function handle_readdir(_err, res)
      if res then
        vim.list_extend(out, res)

        if #res >= MAX then
          uv.fs_readdir(luv_dir, handle_readdir)
          return
        end
      end

      uv.fs_closedir(luv_dir)
      sort_readdir_entries(out)
      cb(out)
    end

    uv.fs_readdir(luv_dir, handle_readdir)
  end, MAX)
end
local readdir_co = async.wrap(readdir_async, 2)

local function scandir_async(directory, tree)
  local res = readdir_co(directory)

  local out = {}

  local function load_item(entry)
    local icon, highlight = web_devicons.get_icon(entry.name)
    local path = directory .. "/" .. entry.name

    local node = {
      text = entry.name,
      type = entry.type,
      path = path,
      icon = icon,
      icon_highlight = highlight,
      is_directory = entry.type == "directory",
    }

    local n
    if node.is_directory then
      n = NuiTree.Node(node, scandir_async(node.path, tree))
    else
      n = NuiTree.Node(node)
    end

    return n
  end

  for _key, entry in pairs(res) do
    if entry.name ~= ".git" then
      local node = load_item(entry)

      local old_node = tree:get_node(node.path)
      if old_node ~= nil then
        if old_node:is_expanded() then
          node:expand()
        end
      end

      table.insert(out, node)
    end
  end

  return out
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

  P.build_tree = function(path, cb)
    P.path = path or vim.fn.getcwd()

    async.run(
      function()
        return scandir_async(P.path, P.tree)
      end,
      vim.schedule_wrap(function(nodes)
        P.tree:set_nodes(nodes)
        P.tree:render()
        cb()
      end)
    )
  end

  P.refresh = function()
    P.build_tree(P.path, function() end)
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
    vim.keymap.set(mode, lhs, rhs, { buffer = P.bufnr, nowait = true })
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

  P.copy = function()
    if P.tree == nil then
      return
    end

    local node = P.tree:get_node()

    if node == nil then
      return
    end

    copy_to_clipboard("file://" .. node.path)
  end

  P.paste = function()
    if P.tree == nil then
      return
    end

    local node = P.tree:get_node()

    if node == nil then
      return
    end

    if not node.is_directory then
      node = P.tree:get_node(node:get_parent_id())
    end

    if node == nil then
      return
    end

    paste_from_clipboard("file://" .. node.path, function()
      P.refresh()
    end)
  end

  P.live_grep = function()
    if P.tree == nil then
      return
    end

    local node = P.tree:get_node()

    if node == nil then
      return
    end

    if node.is_directory then
      P.close()
      require("telescope.builtin").live_grep({ cwd = node.path })
    end
  end

  P.find_files = function()
    if P.tree == nil then
      return
    end

    local node = P.tree:get_node()

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
  P.map("n", "l", P.toggle)
  P.map("n", "h", P.toggle)
  P.map("n", "<Enter>", P.toggle)
  P.map("n", "a", P.reveal_path)
  P.map("n", "d", P.delete)
  P.map("n", "y", P.copy)
  P.map("n", "p", P.paste)
  P.map("n", "<S-f>", P.live_grep)
  P.map("n", "<c-f>", P.find_files)

  return P
end

M.current = nil

function M.setup()
  vim.keymap.set("n", "<C-e>", function()
    local path = vim.fn.expand("%:p")

    if M.current == nil then
      M.current = M.create()
      M.current.build_tree(nil, function()
        M.current.open()
        M.current.reveal_path(path)
      end)
      return
    end

    M.current.open()
    M.current.reveal_path(path)
  end)
end

return M
