local M = {}

function M.setup(opts)
  local config = require("ferris.private.config")
  config.update(opts)

  if config.opts.create_commands then
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("ferris_commands", { clear = true }),
      desc = "Add Ferris user commands to rust_analyzer buffers",
      callback = function(args)
        local lsp = require("ferris.private.ra_lsp")

        local client = vim.lsp.get_client_by_id(args.data.client_id)
        ---@cast client -nil

        if lsp.client_is_ra(client) then
          M.create_commands(args.buf)
        end
      end,
    })
  end
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
  cmd("FerrisOpenCargoToml", "ferris.methods.open_cargo_toml")
  cmd("FerrisOpenParentModule", "ferris.methods.open_parent_module")
  cmd("FerrisOpenDocumentation", "ferris.methods.open_documentation")
  cmd("FerrisReloadWorkspace", "ferris.methods.reload_workspace")
  cmd("FerrisRebuildMacros", "ferris.methods.rebuild_macros")
end

return M
