local M = {}

---Returns the Rust-Analyzer client of the given buffer.
---@param bufnr integer? # The buffer number or nil for current
---@return vim.lsp.Client?
function M.ra_client(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr or 0, name = "rust_analyzer" })
  return clients and clients[1] or nil
end

function M.setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("ferris_commands", { clear = true }),
    desc = "Add Ferris user commands to rust_analyzer buffers",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      ---@cast client -nil

      if client.name == "rust_analyzer" then
        M.create_commands(args.buf)
      end
    end,
  })
end

---Create user commands for the methods provided by Ferris
---@param bufnr? integer Optional buffer number to only add the commands to a given buffer. Default behavior is to create global user commands
function M.create_commands(bufnr)
  local function cmd(name, module, opts)
    if bufnr then
      vim.api.nvim_buf_create_user_command(bufnr, name, require(module), opts or {})
    else
      vim.api.nvim_create_user_command(name, require(module), opts or {})
    end
  end

  cmd("FerrisExpandMacro", "ferris.methods.expand_macro")
  cmd("FerrisViewMemoryLayout", "ferris.methods.view_memory_layout")
  cmd("FerrisOpenDocumentation", "ferris.methods.open_documentation")
end

return M
