local _ = require("renui.utils")._
local tree_util = require("renui.tree.util")

-- returns id of the first window that contains the buffer
---@param bufnr number
---@return number winid
local function get_winid(bufnr)
  return vim.fn.win_findbuf(bufnr)[1]
end

---@param nodes RenuiTree.Node[]
---@param parent_node? RenuiTree.Node
---@param get_node_id nui_tree_get_node_id
---@return { by_id: table<string, RenuiTree.Node>, root_ids: string[] }
local function initialize_nodes(nodes, parent_node, get_node_id)
  local start_depth = parent_node and parent_node:get_depth() + 1 or 1

  ---@type table<string, RenuiTree.Node>
  local by_id = {}
  ---@type string[]
  local root_ids = {}

  ---@param node RenuiTree.Node
  ---@param depth number
  local function initialize(node, depth)
    node._depth = depth
    node._id = get_node_id(node)
    node._initialized = true

    local node_id = node:get_id()

    if by_id[node_id] then
      error("duplicate node id " .. node_id)
    end

    by_id[node_id] = node

    if depth == start_depth then
      table.insert(root_ids, node_id)
    end

    if not node.__children or #node.__children == 0 then
      return
    end

    if not node._child_ids then
      node._child_ids = {}
    end

    for _, child_node in ipairs(node.__children) do
      child_node._parent_id = node_id
      initialize(child_node, depth + 1)
      table.insert(node._child_ids, child_node:get_id())
    end

    node.__children = nil
  end

  for _, node in ipairs(nodes) do
    node._parent_id = parent_node and parent_node:get_id() or nil
    initialize(node, start_depth)
  end

  return {
    by_id = by_id,
    root_ids = root_ids,
  }
end

---@class RenuiTree.Node
---@field _id string
---@field _depth integer
---@field _parent_id? string
---@field _child_ids? string[]
---@field __children? RenuiTree.Node[]
---@field [string] any
local TreeNode = {
  super = nil,
}

---@alias NuiTreeNode RenuiTree.Node

---@return string
function TreeNode:get_id()
  return self._id
end

---@return number
function TreeNode:get_depth()
  return self._depth
end

---@return string|nil
function TreeNode:get_parent_id()
  return self._parent_id
end

---@return boolean
function TreeNode:has_children()
  local items = self._child_ids or self.__children
  return items and #items > 0 or false
end

---@return string[]
function TreeNode:get_child_ids()
  return self._child_ids or {}
end

---@return boolean
function TreeNode:is_expanded()
  return self._is_expanded
end

---@return boolean is_updated
function TreeNode:expand()
  if (self._child_ids or self.__children) and not self:is_expanded() then
    self._is_expanded = true
    return true
  end
  return false
end

---@return boolean is_updated
function TreeNode:collapse()
  if self:is_expanded() then
    self._is_expanded = false
    return true
  end
  return false
end

--luacheck: push no max line length

---@alias nui_tree_get_node_id fun(node: RenuiTree.Node): string
---@alias nui_tree_prepare_node fun(node: RenuiTree.Node, parent_node?: RenuiTree.Node): nil | string | string[] | RenuiLine | RenuiLine[]

--luacheck: pop

---@class nui_tree_internal
---@field buf_options table<string, any>
---@field get_node_id nui_tree_get_node_id
---@field linenr { [1]?: integer, [2]?: integer }
---@field linenr_by_node_id table<string, { [1]: integer, [2]: integer }>
---@field node_id_by_linenr table<integer, string>
---@field prepare_node nui_tree_prepare_node

---@class nui_tree_options
---@field bufnr integer
---@field ns_id? string|integer
---@field nodes? RenuiTree.Node[]
---@field get_node_id? fun(node: RenuiTree.Node): string
---@field prepare_node? fun(node: RenuiTree.Node, parent_node?: RenuiTree.Node): nil|string|string[]|RenuiLine|RenuiLine[]

---@class NuiTree
---@field bufnr integer
---@field nodes { by_id: table<string,RenuiTree.Node>, root_ids: string[] }
---@field ns_id integer
---@field private _ nui_tree_internal
local Tree = {}
Tree.__index = Tree

---@param options nui_tree_options
function Tree:new(options)
  local this = setmetatable({}, self)

  if options.bufnr then
    if not vim.api.nvim_buf_is_valid(options.bufnr) then
      error("invalid bufnr " .. options.bufnr)
    end

    this.bufnr = options.bufnr
  end

  if not this.bufnr then
    error("missing bufnr")
  end

  this.ns_id = vim.api.nvim_create_namespace("renui")

  this._ = {
    buf_options = vim.tbl_extend("force", {
      bufhidden = "hide",
      buflisted = false,
      buftype = "nofile",
      modifiable = false,
      readonly = true,
      swapfile = false,
      undolevels = 0,
    }, options.buf_options or {}),
    get_node_id = options.get_node_id or tree_util.default_get_node_id,
    prepare_node = options.prepare_node or tree_util.default_prepare_node,
    linenr = {},
  }

  _.set_buf_options(this.bufnr, this._.buf_options)

  this:set_nodes(options.nodes or {})

  return this
end

---@generic D : table
---@param data D data table
---@param children? RenuiTree.Node[]
---@return RenuiTree.Node|D
function Tree.Node(data, children)
  ---@type RenuiTree.Node
  local self = {
    __children = children,
    _initialized = false,
    _is_expanded = false,
    _child_ids = nil,
    _parent_id = nil,
    ---@diagnostic disable-next-line: assign-type-mismatch
    _depth = nil,
    ---@diagnostic disable-next-line: assign-type-mismatch
    _id = nil,
  }

  self = setmetatable(vim.tbl_extend("keep", self, data), {
    __index = TreeNode,
    __name = "NuiTree.Node",
  })

  return self
end

---@param node_id_or_linenr? string | integer
---@return RenuiTree.Node|nil node
---@return nil|integer linenr
---@return nil|integer linenr
function Tree:get_node(node_id_or_linenr)
  if type(node_id_or_linenr) == "string" then
    return self.nodes.by_id[node_id_or_linenr], unpack(self._.linenr_by_node_id[node_id_or_linenr] or {})
  end

  local winid = get_winid(self.bufnr)
  local linenr = node_id_or_linenr or vim.api.nvim_win_get_cursor(winid)[1]
  local node_id = self._.node_id_by_linenr[linenr]
  return self.nodes.by_id[node_id], unpack(self._.linenr_by_node_id[node_id] or {})
end

---@param parent_id? string parent node's id
---@return RenuiTree.Node[] nodes
function Tree:get_nodes(parent_id)
  local node_ids = {}

  if parent_id then
    local parent_node = self.nodes.by_id[parent_id]
    if parent_node then
      node_ids = parent_node._child_ids
    end
  else
    node_ids = self.nodes.root_ids
  end

  return vim.tbl_map(function(id)
    return self.nodes.by_id[id]
  end, node_ids or {})
end

---@param nodes RenuiTree.Node[]
---@param parent_node? RenuiTree.Node
function Tree:_add_nodes(nodes, parent_node)
  local new_nodes = initialize_nodes(nodes, parent_node, self._.get_node_id)

  self.nodes.by_id = vim.tbl_extend("force", self.nodes.by_id, new_nodes.by_id)

  if parent_node then
    if not parent_node._child_ids then
      parent_node._child_ids = {}
    end

    for _, id in ipairs(new_nodes.root_ids) do
      table.insert(parent_node._child_ids, id)
    end
  else
    for _, id in ipairs(new_nodes.root_ids) do
      table.insert(self.nodes.root_ids, id)
    end
  end
end

---@param nodes RenuiTree.Node[]
---@param parent_id? string parent node's id
function Tree:set_nodes(nodes, parent_id)
  self._.node_id_by_linenr = {}
  self._.linenr_by_node_id = {}

  if not parent_id then
    self.nodes = { by_id = {}, root_ids = {} }
    self:_add_nodes(nodes)
    return
  end

  local parent_node = self.nodes.by_id[parent_id]
  if not parent_node then
    error("invalid parent_id " .. parent_id)
  end

  if parent_node._child_ids then
    for _, node_id in ipairs(parent_node._child_ids) do
      self.nodes.by_id[node_id] = nil
    end

    parent_node._child_ids = nil
  end

  self:_add_nodes(nodes, parent_node)
end

---@param node RenuiTree.Node
---@param parent_id? string parent node's id
function Tree:add_node(node, parent_id)
  local parent_node = self.nodes.by_id[parent_id]
  if parent_id and not parent_node then
    error("invalid parent_id " .. parent_id)
  end

  self:_add_nodes({ node }, parent_node)
end

local function remove_node(tree, node_id)
  local node = tree.nodes.by_id[node_id]
  if node:has_children() then
    for _, child_id in ipairs(node._child_ids) do
      -- We might want to store the nodes and return them with the node itself?
      -- We should _really_ not be doing this recursively, but it will work for now
      remove_node(tree, child_id)
    end
  end
  tree.nodes.by_id[node_id] = nil
  return node
end

---@param node_id string
---@return RenuiTree.Node
function Tree:remove_node(node_id)
  local node = remove_node(self, node_id)
  local parent_id = node._parent_id
  if parent_id then
    local parent_node = self.nodes.by_id[parent_id]
    parent_node._child_ids = vim.tbl_filter(function(id)
      return id ~= node_id
    end, parent_node._child_ids)
  else
    self.nodes.root_ids = vim.tbl_filter(function(id)
      return id ~= node_id
    end, self.nodes.root_ids)
  end
  return node
end

---@param linenr_start number start line number (1-indexed)
---@return (string|RenuiLine)[]|{ len: integer } lines
function Tree:_prepare_content(linenr_start)
  local internal = self._

  local by_id = self.nodes.by_id

  ---@type { [1]: string|RenuiLine }
  local list_wrapper = {}

  local tree_linenr = 0
  local lines = { len = tree_linenr }

  local node_id_by_linenr = {}
  internal.node_id_by_linenr = node_id_by_linenr

  local linenr_by_node_id = {}
  internal.linenr_by_node_id = linenr_by_node_id

  local function prepare(node_id, parent_node)
    local node = by_id[node_id]
    if not node then
      return
    end

    local node_lines = internal.prepare_node(node, parent_node)
    if node_lines then
      if type(node_lines) ~= "table" or node_lines.content then
        list_wrapper[1] = node_lines
        node_lines = list_wrapper
      end
      ---@cast node_lines -string, -RenuiLine

      local node_linenr = linenr_by_node_id[node_id] or {}
      for node_line_idx = 1, #node_lines do
        local node_line = node_lines[node_line_idx]

        tree_linenr = tree_linenr + 1
        local buffer_linenr = tree_linenr + linenr_start - 1

        lines[tree_linenr] = node_line

        node_id_by_linenr[buffer_linenr] = node_id

        if node_line_idx == 1 then
          node_linenr[1] = buffer_linenr
        end
        node_linenr[2] = buffer_linenr
      end
      linenr_by_node_id[node_id] = node_linenr
    end

    local child_ids = node._child_ids
    if child_ids and node._is_expanded then
      for child_id_idx = 1, #child_ids do
        prepare(child_ids[child_id_idx], node)
      end
    end
  end

  local root_ids = self.nodes.root_ids
  for node_id_idx = 1, #root_ids do
    prepare(root_ids[node_id_idx])
  end

  lines.len = tree_linenr

  return lines
end

---@param linenr_start? number start line number (1-indexed)
function Tree:render(linenr_start)
  linenr_start = math.max(1, linenr_start or self._.linenr[1] or 1)

  local prev_linenr = { self._.linenr[1], self._.linenr[2] }

  local lines = self:_prepare_content(linenr_start)
  local line_idx = lines.len
  lines.len = nil

  _.set_buf_options(self.bufnr, { modifiable = true, readonly = false })

  vim.api.nvim_buf_clear_namespace(self.bufnr, self.ns_id, (prev_linenr[1] or 1) - 1, prev_linenr[2] or 0)

  -- if linenr_start was shifted downwards,
  -- clear the previously rendered lines above.
  _.clear_lines(
    self.bufnr,
    math.min(linenr_start, prev_linenr[1] or linenr_start),
    prev_linenr[1] and linenr_start - 1 or 0
  )

  -- for initial render, start inserting in a single line.
  -- for subsequent renders, replace the lines from previous render.
  _.render_lines(lines, self.bufnr, self.ns_id, linenr_start, prev_linenr[1] and prev_linenr[2] or linenr_start)

  _.set_buf_options(self.bufnr, { modifiable = false, readonly = true })

  self._.linenr[1], self._.linenr[2] = linenr_start, line_idx + linenr_start - 1
end

---@alias NuiTree.constructor fun(options: nui_tree_options): NuiTree
---@type NuiTree|NuiTree.constructor
local NuiTree = Tree

return NuiTree
