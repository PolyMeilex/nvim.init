local M = {}

function M.copy_to_clipboard(text)
  vim.system({ "wl-copy", "-t", "text/uri-list" }, { stdin = text })
end

function M.paste_from_clipboard(parent, done)
  vim.system({ "wl-paste", "-t", "text/uri-list" }, { text = true }, function(obj)
    if obj.code ~= 0 then
      print("Failed to paste from clipboard")
      return
    end

    local file_urls = vim.split(obj.stdout, "\n")
    for _, entry in pairs(file_urls) do
      local file_url = vim.trim(entry)

      if #file_url > 0 then
        vim.system({ "gio", "copy", "-b", file_url, parent }, {}, function(out)
          vim.schedule(done)
        end)
      end
    end
  end)
end

return M
