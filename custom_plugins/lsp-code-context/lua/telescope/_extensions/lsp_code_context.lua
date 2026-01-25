local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  error("This plugins requires nvim-telescope/telescope.nvim")
end
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

local function new_finder(data, path)
  local marklist = {}

  for i, entry in ipairs(data) do
    table.insert(marklist, 1, {
      filename = path,
      line = entry.scope.start.line,
      col = entry.scope.start.character,
      text = entry.name,
      icon = entry.icon,
      kind = entry.kind,
      type = entry.type,
      indent = i - 1,
    })
  end

  return finders.new_table({
    results = marklist,
    entry_maker = function(value)
      return {
        valid = true,
        value = value,
        display = function(entry)
          local v = entry.value
          local style = { { { 0, #v.icon }, "NavicIcons" .. v.type } }

          local indent = string.rep(" ", v.indent)

          return v.icon .. indent .. v.text, style
        end,
        ordinal = value.text,
        filename = value.filename,
        lnum = value.line,
        col = value.col,
        text = value.text,
      }
    end,
  })
end

local function lsp_context_list(opts)
  opts = opts or {}

  local path = vim.api.nvim_buf_get_name(0)
  local data = require("lsp-code-context").get_data() or {}

  if #data == 0 then
    return
  end

  pickers
    .new(opts, {
      prompt_title = "lsp-code-context",
      finder = new_finder(data, path),
      sorter = conf.generic_sorter(opts),
      previewer = conf.qflist_previewer(opts),
    })
    :find()
end

return telescope.register_extension({ exports = { list = lsp_context_list } })
