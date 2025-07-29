local M = {}

-- Copy-paste from https://github.com/neovim/neovim/pull/24338
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

    function srv.request(method, params, callback, notify_reply_callback)
      pcall(on_request, method, params)
      local handler = handlers[method]
      if handler then
        local response, err = handler(method, params)
        callback(err, response)
      elseif method == "initialize" then
        callback(nil, {
          capabilities = capabilities,
        })
      elseif method == "shutdown" then
        callback(nil, nil)
      end
      request_id = request_id + 1
      if notify_reply_callback then
        notify_reply_callback(request_id)
      end
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

--- @class fmt_lsp_start.Opts
--- @field name string
--- @field bufnr integer
--- @field handle_format fun(method: string, params: lsp.DocumentFormattingParams): lsp.TextEdit[]
---
--- @param opts fmt_lsp_start.Opts
function M.fmt_lsp_start(opts)
  vim.lsp.start({
    name = opts.name,
    cmd = server({
      capabilities = {
        documentFormattingProvider = true,
      },
      handlers = {
        ["textDocument/formatting"] = opts.handle_format,
      },
    }),
  }, {
    bufnr = opts.bufnr,
    reuse_client = function(client, config)
      return client.name == config.name
    end,
  })
end

return M
