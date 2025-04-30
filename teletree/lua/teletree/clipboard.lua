local Path = require("plenary.path")

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

    vim.schedule(function()
      for _, entry in pairs(file_urls) do
        local file_url = vim.trim(entry)

        local path = strip_uri(file_url)

        if #path > 0 then
          --- @type Path
          local file_path = Path:new(path)
          file_path:copy({
            recursive = true,
            destination = vim.fs.joinpath(parent, vim.fs.basename(path)),
            interactive = true,
            parents = true,
          })
        end
      end

      done()
    end)
  end)
end

return M
