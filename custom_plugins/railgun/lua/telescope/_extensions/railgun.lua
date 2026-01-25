local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error("This plugins requires nvim-telescope/telescope.nvim")
end
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local railgun = require("railgun")
local action_state = require("telescope.actions.state")

local function new_finder()
  local marklist = {}

  local project = railgun.db:get_project() or {}
  local bookmarks = project.bookmarks or {}

  for path, marks in pairs(bookmarks) do
    for _, entry in pairs(marks) do
      table.insert(marklist, {
        filename = path,
        line = entry.line,
        col = entry.col,
        text = entry.annotation or path,
      })
    end
  end

  return finders.new_table({
    results = marklist,
    entry_maker = function(entry)
      return {
        valid = true,
        value = entry,
        display = function(entry)
          return entry.text
        end,
        ordinal = entry.text,
        filename = entry.filename,
        lnum = entry.line,
        col = entry.col,
        text = entry.text,
      }
    end,
  })
end

local delete_mark = function(buf)
  local selection = action_state.get_selected_entry()

  railgun.remove(selection.value.filename, selection.value.line, selection.value.col)

  action_state.get_current_picker(buf):refresh(new_finder(), {})
end

local function railgun_list(opts)
  opts = opts or {}

  pickers
    .new(opts, {
      prompt_title = "railgun",
      finder = new_finder(),
      sorter = conf.generic_sorter(opts),
      previewer = conf.qflist_previewer(opts),
      attach_mappings = function(_, map)
        map("i", "<c-d>", delete_mark)
        map("n", "<c-d>", delete_mark)
        return true
      end,
    })
    :find()
end

return telescope.register_extension({ exports = { list = railgun_list } })
