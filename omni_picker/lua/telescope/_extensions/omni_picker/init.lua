local telescope = require("telescope")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local utils = require("telescope.utils")
local conf = require("telescope.config").values
local Path = require("plenary.path")

local M = {}

local function new_finder(cwd)
  local display = function(entry)
    local hl_group, icon
    local display, path_style = utils.transform_path({ cwd = cwd }, entry.path)

    if entry.is_dir then
      icon = " "
      local text = display

      local text_hl = { { #icon, #icon + #text }, "TelescopePreviewDirectory" }

      return icon .. text, { text_hl }
    end

    display, hl_group, icon = utils.transform_devicons(entry.path, display, false)

    if hl_group then
      local style = { { { 0, #icon + 1 }, hl_group } }
      style = utils.merge_styles(style, path_style, #icon + 1)
      return display, style
    else
      return display, path_style
    end
  end

  -- local cmd = { "fd", "--type", "directory" }
  local cmd = { "fd" }
  return finders.new_oneshot_job(cmd, {
    entry_maker = function(line)
      local absolute = cwd .. line

      local basename = utils.path_tail(absolute)
      local is_dir = #basename == 0

      return {
        display = display,
        path = absolute,
        ordinal = line,
        is_dir = is_dir,
      }
    end,
    cwd = cwd,
  })
end

function M.omni_picker(opts)
  opts = opts or {}

  opts.cwd = opts.cwd or vim.fn.getcwd()
  opts.cwd = opts.cwd .. "/"

  opts.prompt_title = opts.prompt_title or "./"

  local finder = new_finder(opts.cwd)

  pickers
    .new(opts, {
      finder = finder,
      sorter = conf.generic_sorter({}),
      previewer = conf.qflist_previewer({}),
      attach_mappings = function()
        actions.select_default:replace(function(prompt_bufnr)
          local action_set = require("telescope.actions.set")

          local entry = action_state.get_selected_entry()

          if entry.is_dir then
            M.omni_picker({
              prompt_title = Path:new(entry.path):make_relative(vim.fn.getcwd()),
              cwd = entry.path,
            })
          else
            action_set.select(prompt_bufnr, "default")
          end
        end)

        return true
      end,
    })
    :find()
end

return telescope.register_extension({
  setup = function(ext_config, config)
    -- access extension config and user config
  end,
  exports = {
    omni_picker = M.omni_picker,
  },
})
