-- Copy-paste from https://github.com/neovim/neovim/pull/24338 (with added async support)
local function server(opts)
  opts = opts or {}
  local capabilities = opts.capabilities or {}
  local on_request = opts.on_request or function(_, _) end
  local on_notify = opts.on_notify or function(_, _) end
  local handlers = opts.handlers or {}

  --- @return vim.lsp.rpc.PublicClient
  return function(dispatchers)
    local closing = false
    --- @type vim.lsp.rpc.PublicClient
    local srv = {}
    local request_id = 0

    function srv.request(method, params, callback)
      pcall(on_request, method, params)
      local handler = handlers[method]
      if handler then
        handler(method, params, function(response, err)
          callback(err, response)
        end)
      elseif method == "initialize" then
        callback(nil, {
          capabilities = capabilities,
        })
      elseif method == "shutdown" then
        callback(nil, nil)
      end
      request_id = request_id + 1
      return true, request_id
    end

    function srv.notify(method, params)
      pcall(on_notify, method, params)
      if method == "exit" then
        dispatchers.on_exit(0, 15)
      end
    end

    function srv.is_closing()
      return closing
    end

    function srv.terminate()
      closing = true
    end

    return srv
  end
end

local typos_cli = require("typos.process")

---@param method: string
---@param params lsp.CodeActionParams
---@return lsp.CodeAction[]
local function handle_code_action(method, params, callback)
  local uri = params.textDocument.uri
  local range_start = params.range["start"]
  local range_end = params.range["end"]

  local buffer = vim.uri_to_bufnr(params.textDocument.uri)

  typos_cli.run_for_buffer(buffer, function(results)
    local filtered = vim.tbl_filter(function(json)
      -- TODO: Does this work with UTF-8?
      local column = json.byte_offset
      local end_column = column + string.len(json.typo)
      local line = json.line_num - 1

      local is_line = line >= range_start.line and line <= range_end.line
      local is_column = range_start.character >= column and range_end.character < end_column

      return is_line and is_column
    end, results)

    local diagnostics = vim.tbl_map(function(json)
      local start_column = json.byte_offset
      local end_column = start_column + string.len(json.typo)

      return {
        title = "`" .. json.typo .. "`" .. " to " .. "`" .. json.corrections[1] .. "`",
        kind = "quickfix",
        edit = {
          changes = {
            [uri] = {
              {
                range = {
                  start = {
                    line = json.line_num - 1,
                    character = start_column,
                  },
                  ["end"] = {
                    line = json.line_num - 1,
                    character = end_column,
                  },
                },
                newText = json.corrections[1],
              },
            },
          },
        },
      }
    end, filtered)

    callback(diagnostics)
  end)
end

local M = {}

function M.start()
  vim.lsp.start({
    name = "typos-lsp",
    cmd = server({
      capabilities = {
        codeActionProvider = {
          codeActionKinds = { "quickfix" },
        },
      },
      handlers = {
        ["textDocument/codeAction"] = handle_code_action,
      },
    }),
  }, {
    bufnr = vim.api.nvim_get_current_buf(),
    reuse_client = function(client, config)
      return client.name == config.name
    end,
  })
end

return M
