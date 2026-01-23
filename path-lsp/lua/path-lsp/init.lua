local LRUCache = require("path-lsp.lru")

local M = {}

---Configuration for file system scanning
---@class ScannerConfig
---@field scan_batch_size number Number of items to process in each scan batch. Higher values improve speed but may cause stuttering
---@field cache_duration_ms number How long to cache scan results (milliseconds). Higher values improve performance but may show stale results
---@field throttle_delay_ms number Delay between processing updates (milliseconds). Prevents excessive CPU usage during rapid changes

---Main configuration for path-lsp
---@class PathLspConfig
---@field filetypes string[] List of filetypes to enable path-lsp for. Use {'*'} for all filetypes
---@field scanner ScannerConfig Settings controlling file system scanning behavior
---@field enabled boolean
---@field autostart boolean
---@field relative_to_curr_file boolean

---@type PathLspConfig
local default_config = {
  filetypes = { "*" },
  scanner = {
    scan_batch_size = 1000,
    cache_duration_ms = 5000,
    throttle_delay_ms = 1000,
  },
  enabled = false,
  autostart = false,
  relative_to_curr_file = true,
}

---@type PathLspConfig
M.config = default_config

local scan_cache = LRUCache:new(100)

local function schedule_result(callback, items)
  vim.schedule(function()
    callback(nil, { isIncomplete = false, items = items or {} })
  end)
end

local function scan_dir_async(path, callback)
  local cached = scan_cache:get(path)
  if cached and (vim.uv.now() - cached.timestamp) < M.config.scanner.cache_duration_ms then
    callback(cached.results)
    return
  end

  local co = coroutine.create(function(resolve)
    local handle = vim.uv.fs_scandir(path)
    if not handle then
      resolve({})
      return
    end

    local results = {}
    local batch_size = M.config.scanner.scan_batch_size
    local current_batch = {}

    while true do
      local name, type = vim.uv.fs_scandir_next(handle)
      if not name then
        if #current_batch > 0 then
          vim.list_extend(results, current_batch)
        end
        break
      end

      local is_hidden = name:match("^%.")
      if type == "directory" and not name:match("/$") then
        name = name .. "/"
      end

      table.insert(current_batch, {
        name = name,
        type = type,
        is_hidden = is_hidden,
      })

      if #current_batch >= batch_size then
        vim.list_extend(results, current_batch)
        current_batch = {}
        coroutine.yield()
      end
    end

    scan_cache:put(path, {
      timestamp = vim.uv.now(),
      results = results,
    })
    resolve(results)
  end)

  local ok, err = coroutine.resume(co, callback)
  if not ok then
    vim.schedule(function()
      vim.notify(string.format("Error in scan_dir_async: %s", err), vim.log.levels.ERROR)
      callback({})
    end)
  end
end

local function find_last_occurrence(str, patterns)
  local reversed_str = string.reverse(str)
  for _, pattern in ipairs(patterns) do
    local start_pos, end_pos = string.find(reversed_str, pattern)
    if start_pos then
      return #str - end_pos + 1
    end
  end
  return nil
end

local function server_create()
  return function()
    local srv = {}

    function srv.initialize(params, callback)
      callback(nil, {
        capabilities = {
          completionProvider = {
            triggerCharacters = { "/" },
            resolveProvider = false,
          },
        },
      })
    end

    function srv.completion(params, callback)
      local position = params.position
      local line = vim.api.nvim_get_current_line()
      if #line == 0 then
        schedule_result(callback)
        return
      end

      local prefix = line:sub(1, position.character)
      local has_literal = find_last_occurrence(prefix, { '"', "'" })
      if has_literal then
        prefix = prefix:sub(has_literal + 1, position.character)
      end
      local has_space = find_last_occurrence(prefix, { "%s" })
      if has_space then
        prefix = prefix:sub(has_space + 1, position.character)
      end
      local dir_part = prefix:match("^(.*/)[^/]*$")

      if not dir_part then
        schedule_result(callback)
        return
      end

      if M.config.relative_to_curr_file then
        dir_part = M.get_curr_file_dir() .. "/" .. dir_part
      end
      local expanded_path = vim.fs.normalize(vim.fs.abspath(dir_part))
      scan_dir_async(expanded_path, function(results)
        local items = {}
        local current_input = prefix:match("[^/]*$") or ""

        for _, entry in ipairs(results) do
          local name = entry.name

          if vim.startswith(name:lower(), current_input:lower()) then
            local kind = entry.type == "directory" and vim.lsp.protocol.CompletionItemKind.Folder
              or vim.lsp.protocol.CompletionItemKind.File
            local label = name

            table.insert(items, {
              label = label,
              kind = kind,
              insertText = label,
              filterText = label,
              detail = nil,
              sortText = label:lower(),
            })
          end
        end

        schedule_result(callback, items)
      end)
    end

    srv["textDocument/completion"] = srv.completion

    function srv.shutdown(params, callback)
      callback(nil, nil)
    end

    return {
      request = function(method, params, callback)
        if srv[method] then
          srv[method](params, callback)
        else
          callback({ message = "Method not found: " .. method })
        end
      end,
      notify = function(method, params)
        if srv[method] then
          srv[method](params)
        end
      end,
      is_closing = function()
        return false
      end,
      terminate = function() end,
    }
  end
end

function M.get_curr_file_dir()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  local dir = vim.fs.dirname(path)
  return dir
end

function M.start()
  M.config.enabled = true

  vim.lsp.start({
    name = "path-lsp",
    cmd = server_create(),
    root_dir = vim.uv.cwd(),
    reuse_client = function()
      return true
    end,
  })
end

function M.stop()
  M.config.enabled = false

  local client = vim.lsp.get_clients({ name = "path-lsp" })
  for _, value in pairs(client) do
    vim.lsp.stop_client(value.id)
  end
end

function M.toggle()
  if M.config.enabled then
    M.stop()
  else
    M.start()
  end
end

function M.relative_to_curr_file_toggle()
  M.config.relative_to_curr_file = not M.config.relative_to_curr_file
end

function M.set_relative_to_curr_file()
  M.config.relative_to_curr_file = true
end

function M.set_relative_to_curr_cwd()
  M.config.relative_to_curr_file = false
end

---@param config PathLspConfig
function M.setup(config)
  M.config = vim.deepcopy(default_config)
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  vim.api.nvim_create_user_command("PathLspToggle", M.toggle, { desc = "Toggle path lsp" })
  vim.api.nvim_create_user_command(
    "PathLspRelativeToggle",
    M.relative_to_curr_file_toggle,
    { desc = "Relative to curr file toggle" }
  )
  vim.api.nvim_create_user_command(
    "PathLspRelativeToCwd",
    M.set_relative_to_curr_cwd,
    { desc = "Relative to current cwd" }
  )
  vim.api.nvim_create_user_command(
    "PathLspRelativeToFile",
    M.set_relative_to_curr_file,
    { desc = "Relative to current file" }
  )

  if not config.autostart then
    return
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("path-lsp", { clear = true }),
    pattern = M.config.filetypes,
    callback = function(args)
      local buf = args.buf
      if
        not vim.bo[buf].modifiable
        or vim.list_contains({ "terminal", "nofile", "quickfix", "prompt" }, vim.bo[buf].buftype)
      then
        return
      end

      M.start()
    end,
    desc = "path-lsp autostart",
  })
end

return M
