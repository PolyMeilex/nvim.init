local json_utils = require("json_utils")

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

    function srv.request(method, params, callback)
      pcall(on_request, method, params)
      local handler = handlers[method]
      if handler then
        local response, err = handler(method, params)
        callback(err, response)
      elseif method == 'initialize' then
        callback(nil, {
          capabilities = capabilities
        })
      elseif method == 'shutdown' then
        callback(nil, nil)
      end
      request_id = request_id + 1
      return true, request_id
    end

    function srv.notify(method, params)
      pcall(on_notify, method, params)
      if method == 'exit' then
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

---@param method: string
---@param params lsp.DefinitionParams
local function handle_goto_definition(method, params)
  local uri = params.textDocument.uri
  local lnum = params.position.line
  local col = params.position.character

  local bufnr = vim.uri_to_bufnr(params.textDocument.uri)

  local node_at = json_utils.get_node_at(bufnr, lnum, col)
  if node_at == nil then return nil end

  local node_type = node_at:type()

  if node_type == "string" then
    node_at = node_at:child(1)
  elseif node_type == "pair" then
    node_at = node_at:field("value")[1]
    if node_at == nil then return nil end
    node_at = node_at:child(1)
  elseif node_type == "string_content" then
    -- Bingo!
  else
    return nil
  end

  if node_at == nil then return nil end

  local word = vim.treesitter.get_node_text(node_at, bufnr)
  local res = json_utils.find_key_value(bufnr, "name", word)

  if res == nil then return nil end

  return {
    uri = uri,
    range = {
      start = {
        line = res.line,
        character = res.col,
      },
      ["end"] = {
        line = res.line,
        character = res.col,
      },
    }
  }
end

local M = {}

--- Register lsp server for https://github.com/fudini/bendec definition format
M.register_bendec_lsp_autocmd = function()
  vim.api.nvim_create_augroup("bendec-lsp", { clear = true })
  vim.api.nvim_create_autocmd('BufRead', {
    group = "bendec-lsp",
    pattern = "*.json",
    callback = function()
      vim.lsp.start(
        {
          name = "json-bendec-ls",
          cmd = server({
            capabilities = {
              definitionProvider = true
            },
            handlers = {
              ["textDocument/definition"] = handle_goto_definition,
            }
          })
        },
        {
          bufnr = vim.api.nvim_get_current_buf(),
          reuse_client = function(client, config)
            return client.name == config.name
          end
        }
      )
    end,
  })
end

return M
