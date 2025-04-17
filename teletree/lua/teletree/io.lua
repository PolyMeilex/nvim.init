local async = require("plenary.async")
local uv = vim.uv

local M = {}

---@param list uv.fs_readdir.entry[]
local function sort_readdir_entries(list)
  table.sort(list, function(a, b)
    if a.type == b.type then
      return a.name < b.name
    else
      return a.type == "directory"
    end
  end)
end

---@param directory string
---@param cb fun(out: uv.fs_readdir.entry[])
function M.readdir_async(directory, cb)
  local MAX = 1000

  uv.fs_opendir(directory, function(err, luv_dir)
    if err then
      return
    end

    local out = {}

    ---@param _err string?
    ---@param res uv.fs_readdir.entry[]
    local function handle_readdir(_err, res)
      if res then
        vim.list_extend(out, res)

        if #res >= MAX then
          uv.fs_readdir(luv_dir, handle_readdir)
          return
        end
      end

      uv.fs_closedir(luv_dir)
      sort_readdir_entries(out)
      cb(out)
    end

    uv.fs_readdir(luv_dir, handle_readdir)
  end, MAX)
end

M.readdir_co = async.wrap(M.readdir_async, 2)

return M
