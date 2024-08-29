local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local values_for_key = require("json_utils").values_for_key

local M = {}

M.list_values_for_key = function(key, opts)
  opts = opts or {}
  local marklist = {}

  local filename = vim.api.nvim_buf_get_name(0)
  for _, entry in pairs(values_for_key(key)) do
    table.insert(marklist, {
      filename = filename,
      lnum = entry.line,
      text = entry.name,
    })
  end
  pickers.new(opts, {
    prompt_title = "json items",
    finder = finders.new_table {
      results = marklist,
      entry_maker = function(entry)
        return {
          valid = true,
          value = entry,
          display = function(entry) return entry.text end,
          ordinal = entry.text,
          filename = entry.filename,
          lnum = entry.lnum,
          col = 1,
          text = entry.text,
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    previewer = conf.qflist_previewer(opts),
  }):find()
end

return M
