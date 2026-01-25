local M = {}

-- Run `git diff` and return quickfix-format list of hunks across all files.
function M.get_git_diff()
  local git_cmd = "git diff --no-color -U0"
  local lines = vim.fn.systemlist(git_cmd)

  if #lines == 0 then
    return {}
  end

  local qflist = {}
  local curfile = nil

  for i, line in ipairs(lines) do
    -- Detect the new-file path line: "+++ <path>"
    if vim.startswith(line, "+++ ") then
      local path = line:sub(5) -- strip leading "+++ "
      -- strip "b/" prefix that git diff prints by default
      path = path:gsub("^b/", "")

      if path == "/dev/null" then
        -- The file was deleted
        curfile = nil
      else
        curfile = path
      end
    end

    -- Detect hunk header, e.g. "@@ -12,3 +15,4 @@ optional-heading"
    local _oldStart, _oldCount, newStart, newCount = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")

    if newStart and curfile then
      local lnum = tonumber(newStart) or 1

      local snippet = nil
      for j = i + 1, math.min(#lines, i + 10) do
        local first = lines[j]:sub(1, 1)
        if first == "+" or first == "-" then
          snippet = lines[j]
          break
        else
          break
        end
      end

      local text = snippet and snippet or line

      table.insert(qflist, {
        filename = curfile,
        lnum = lnum,
        col = 1,
        text = vim.trim(text),
      })
    end
  end

  return qflist
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

function M.pick(opts)
  opts = opts or {}

  pickers
    .new(opts, {
      prompt_title = "git-hunks",
      finder = finders.new_table({
        results = M.get_git_diff(),
        entry_maker = function(value)
          return {
            display = function(entry)
              return entry.filename .. ":" .. entry.lnum
            end,
            ordinal = value.filename,
            filename = value.filename,
            lnum = value.lnum,
            col = value.col,
            text = value.text,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      previewer = conf.qflist_previewer(opts),
    })
    :find()
end

return M
