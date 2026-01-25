---Main configuration for rust-targets.nvim
---@class RustTargetsConfig
---@field rustup boolean
---@field targets string[]

---@type RustTargetsConfig
local default_config = {
  rustup = true,
  targets = {
    "system",
    "x86_64-pc-windows-gnu",
    "x86_64-apple-darwin",
    "wasm32-unknown-unknown",
    "x86_64-unknown-linux-gnu",
  },
}

local M = {}

M.config = default_config

---@type string[]|nil
M.targets = nil

---@param config RustTargetsConfig | nil
function M.setup(config)
  M.config = vim.deepcopy(default_config)
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  vim.api.nvim_create_user_command("SelectRustTarget", M.select, {})

  if M.config.rustup then
    M.targets = nil
  else
    M.targets = M.config.targets
  end
end

function M.rustup_targets()
  local list = vim.fn.systemlist("rustup target list --installed") or {}
  table.insert(list, 1, "system")
  return list
end

---@param target string|nil
function M.configure_target(target)
  vim.lsp.config("rust_analyzer", {
    settings = {
      ["rust-analyzer"] = {
        cargo = {
          target = target or vim.NIL,
        },
      },
    },
  })
end

---@param target string|nil
function M.live_configure_target(target)
  vim.lsp.enable("rust_analyzer", false)
  M.configure_target(target)
  vim.lsp.enable("rust_analyzer", true)
end

function M.select()
  if M.config.rustup and M.targets == nil then
    M.targets = M.rustup_targets()
  end

  vim.ui.select(M.targets, { prompt = "Select Rust Target" }, function(item)
    if item then
      if item == "system" then
        M.live_configure_target(nil)
      else
        M.live_configure_target(item)
      end
    end
  end)
end

return M
