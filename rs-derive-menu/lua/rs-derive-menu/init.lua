local Menu = require("rs-derive-menu.menu")
local event = require("nui.utils.autocmd").event

local popup_options = {
  relative = "cursor",
  position = {
    row = 2,
    col = 0,
  },
  border = {
    style = "single",
    text = {
      top = "Derive",
      top_align = "center",
    },
  },
  win_options = {
    winhighlight = "Normal:Normal",
  }
}

local function new_menu_options(derive_list, on_submit)
  local items = {}
  for k, v in pairs(derive_list.list) do
    table.insert(items, v:to_menu_item())
  end

  return {
    lines = items,
    min_width = 30,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>" },
      submit = { "<CR>", "<Space>" },
    },
    on_close = function()
      print("CLOSED")
    end,
    on_submit = function(item)
      on_submit(item)
    end,
  }
end

local function new_menu(derive_list, on_submit)
  return Menu(popup_options, new_menu_options(derive_list, on_submit))
end

local parsers = require "nvim-treesitter.parsers"

local function node_contains(node, range)
  local start_row, start_col, end_row, end_col = node:range()
  local start_fits = start_row < range[1] or (start_row == range[1] and start_col <= range[2])
  local end_fits = end_row > range[3] or (end_row == range[3] and end_col >= range[4])

  return start_fits and end_fits
end

local function get_node_at_cursor(options)
  options = options or {}

  local include_anonymous = options.include_anonymous
  local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
  local root_lang_tree = parsers.get_parser()

  -- This can happen in some scenarios... best not assume.
  if not root_lang_tree then
    return
  end

  local owning_lang_tree = root_lang_tree:language_for_range { lnum - 1, col, lnum - 1, col }
  local result

  for _, tree in ipairs(owning_lang_tree:trees()) do
    local range = { lnum - 1, col, lnum - 1, col }

    if node_contains(tree:root(), range) then
      if include_anonymous then
        result = tree:root():descendant_for_range(unpack(range))
      else
        result = tree:root():named_descendant_for_range(unpack(range))
      end

      if result then
        return result
      end
    end
  end
end

local function search_for_struct(node)
  while node:type() ~= "struct_item" do
    node = node:parent()
    if not node then return nil end
  end

  return node
end

local function attribute_ident(bufnr, attribute)
  local ident = attribute:child(0)
  if not ident then return nil end
  return vim.treesitter.get_node_text(ident, bufnr)
end

local function attribute_item_ident(bufnr, attribute_item)
  local attribute = attribute_item:child(2)
  if not attribute then return nil end
  return attribute_ident(bufnr, attribute)
end

local function search_for_attribute_item(bufnr, node)
  while node:type() ~= "attribute_item" do
    node = node:parent()
    if not node then return nil end
  end

  if attribute_item_ident(bufnr, node) ~= "derive" then return nil end

  return node
end

local DeriveItem = {}
DeriveItem.__index = DeriveItem

function DeriveItem.new(name, on)
  local self = {}
  setmetatable(self, DeriveItem)
  self.name = name
  self.on = on
  return self
end

function DeriveItem:to_menu_item()
  local checkbox = "   "
  if self.on then
    checkbox = "  "
  end
  return Menu.item(checkbox .. self.name, { name = self.name })
end

local DeriveList = {}
DeriveList.__index = DeriveList

function DeriveList.new()
  local self = {}
  setmetatable(self, DeriveList)
  self.list = {}
  return self
end

function DeriveList:get(name)
  for k, v in pairs(self.list) do
    if v.name == name then
      return v
    end
  end

  return nil
end

function DeriveList:insert(name, on)
  for _k, v in pairs(self.list) do
    if v.name == name then
      if on ~= nil then
        v.on = on
      end
      return
    end
  end

  if on == nil then
    on = false
  end

  table.insert(self.list, DeriveItem.new(name, on))
end

local function replace_derive(bufnr, start_line, start_col, end_line, end_col, derive_list)
  local derives = {}

  for _k, v in pairs(derive_list.list) do
    if v.on == true then
      table.insert(derives, v.name)
    end
  end

  local out = "#[derive(" .. table.concat(derives, ", ") .. ")]"
  vim.api.nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, { out })
end

local function open()
  local bufnr = vim.api.nvim_get_current_buf()

  local cursor_node = get_node_at_cursor();
  if not cursor_node then return end

  local node = search_for_attribute_item(bufnr, cursor_node)

  if not node then
    node = search_for_struct(cursor_node)
    local sibling = node:prev_sibling()
    -- node =
    vim.print(sibling:type())
    node = sibling
  end

  local attribute = node:child(2)

  local body_node = attribute:child(1)
  local body_start_line, body_start_col = body_node:start()
  local body_end_line, body_end_col = body_node:end_()


  local body = vim.treesitter.get_node_text(body_node, bufnr)

  body = string.sub(body, 2, string.len(body) - 1)

  local derives = {}
  for i in string.gmatch(body, "([^,]+)") do
    table.insert(derives, i:match("^%s*(.-)%s*$"))
  end

  local items = DeriveList.new()

  for _k, v in pairs(derives) do
    items:insert(v, true)
  end

  items:insert("Default")
  items:insert("Debug")
  items:insert("Clone")
  items:insert("Copy")
  items:insert("PartialEq")
  items:insert("Eq")
  items:insert("PartialOrd")
  items:insert("Ord")
  items:insert("Hash")

  local menu
  local function on_submit(item)
    vim.print(menu.winid)
    local lnum, col = unpack(vim.api.nvim_win_get_cursor(menu.winid))

    print("SUBMITTED", item.text)
    local derive_item = items:get(item.name)
    derive_item.on = not derive_item.on
    replace_derive(bufnr, body_start_line, body_start_col, body_end_line, body_end_col, items)

    menu:unmount()
    menu:init(popup_options, new_menu_options(items, on_submit))
    menu:mount()

    vim.api.nvim_win_set_cursor(menu.winid, { lnum, 0 })
  end

  menu = new_menu(items, on_submit)

  -- local raw_items = {}
  -- for k, v in pairs(items.list) do
  --   table.insert(raw_items, v:to_menu_item())
  -- end
  -- table.insert(raw_items, DeriveItem.new("thiserror::Error", false):to_menu_item())
  -- table.insert(raw_items, DeriveItem.new("serde::Serialize", false):to_menu_item())
  -- table.insert(raw_items, DeriveItem.new("serde::Deserialize", false):to_menu_item())

  -- local menu = Menu(popup_options, {
  --   lines = raw_items,
  --   min_width = 30,
  --   keymap = {
  --     focus_next = { "j", "<Down>", "<Tab>" },
  --     focus_prev = { "k", "<Up>", "<S-Tab>" },
  --     close = { "<Esc>", "<C-c>" },
  --     submit = { "<CR>", "<Space>" },
  --   },
  --   on_close = function()
  --     print("CLOSED")
  --   end,
  --   on_submit = function(item)
  --     -- print("SUBMITTED", vim.inspect(item.text))
  --     print("SUBMITTED", item.text)
  --     local derive_item = items:get(item.name)
  --     derive_item.on = not derive_item.on
  --     replace_derive(bufnr, body_start_line, body_start_col, body_end_line, body_end_col, items)
  --     -- menu:unmount()
  --   end,
  -- })

  menu:mount()

  menu:on(event.BufLeave, function()
    menu:unmount()
  end)
end

local M = {}
M.setup = function()
  vim.keymap.set('n', '<leader>cd', open, {})
end
return M
