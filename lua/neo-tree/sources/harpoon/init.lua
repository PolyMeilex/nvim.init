local vim = vim
local renderer = require("neo-tree.ui.renderer")
local manager = require("neo-tree.sources.manager")
local events = require("neo-tree.events")
local utils = require("neo-tree.utils")

local M = {
  name = "harpoon",
  display_name = "Harpoon"
}

local get_state = function()
  return manager.get_state(M.name)
end

local follow_internal = function()
  if vim.bo.filetype == "neo-tree" or vim.bo.filetype == "neo-tree-popup" then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local path_to_reveal = manager.get_path_to_reveal(true) or tostring(bufnr)

  local state = get_state()
  if state.current_position == "float" then
    return false
  end
  if not state.path then
    return false
  end
  local window_exists = renderer.window_exists(state)
  if window_exists then
    local node = state.tree and state.tree:get_node()
    if node then
      if node:get_id() == path_to_reveal then
        -- already focused
        return false
      end
    end
    renderer.focus_node(state, path_to_reveal, true)
  end
end

M.follow = function()
  if vim.fn.bufname(0) == "COMMIT_EDITMSG" then
    return false
  end
  utils.debounce("neo-tree-harpoon-follow", function()
    return follow_internal()
  end, 100, utils.debounce_strategy.CALL_LAST_ONLY)
end

local buffers_changed_internal = function()
  for _, tabid in ipairs(vim.api.nvim_list_tabpages()) do
    local state = manager.get_state(M.name, tabid)
    if state.path and renderer.window_exists(state) then
      items.get_opened_buffers(state)
      if state.follow_current_file.enabled then
        follow_internal()
      end
    end
  end
end

---Navigate to the given path.
---@param path string Path to navigate to. If empty, will navigate to the cwd.
M.navigate = function(state, path)
  if path == nil then
    path = vim.fn.getcwd()
  end
  state.path = path

  local list = require("harpoon"):list().items

  local items = {}

  for idx = 1, #list do
    if list[idx].value ~= "" then
      local n = list[idx];
      local item = {
        id = vim.fn.getcwd() .. "/" .. n.value,
        name = n.value,
        type = "file",
        extra = { mark = idx },
      }
      table.insert(items, item)
    end
  end

  renderer.show_nodes(items, state)
end

M.default_config = {
  follow_current_file = {
    enabled = true,
  },
  renderers = {
    file = {
      { "mark" },
      { "name" },
    }
  }
}

---Configures the plugin, should be called before the plugin is used.
---@param config table Configuration table containing any keys that the user
--wants to change from the defaults. May be empty to accept default values.
M.setup = function(config, global_config)
  if config.follow_current_file.enabled then
    manager.subscribe(M.name, {
      event = events.VIM_BUFFER_ENTER,
      handler = function(args)
        if utils.is_real_file(args.afile) then
          M.follow()
        end
      end,
    })
  end
end

return M
