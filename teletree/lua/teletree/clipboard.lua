local Path = require("plenary.path")
local utils = require("teletree.utils")

local M = {}

local function strip_uri(uri)
  return uri:gsub("^file://", "")
end

function M.copy_to_clipboard(text)
  vim.system({ "wl-copy", "-t", "text/uri-list" }, { stdin = "file://" .. text })
end

function M.paste_from_clipboard(parent, done)
  vim.system({ "wl-paste", "-t", "text/uri-list" }, { text = true }, function(obj)
    if obj.code ~= 0 then
      vim.notify("Failed to paste from clipboard", vim.log.levels.ERROR)
      return
    end

    local file_urls = vim.split(obj.stdout, "\n")
    for _, entry in pairs(file_urls) do
      local file_url = vim.trim(entry)

      local path = strip_uri(file_url)

      --- @type Path
      local file_path = Path:new(path)
      --- @type Path
      local destination = Path:new(parent, utils.path_last_segment(path))

      if #path > 0 then
        file_path:copy({ recursive = true, destination = destination, interactive = true, parents = true })
      end
    end

    vim.schedule(done)
  end)
end

return M
