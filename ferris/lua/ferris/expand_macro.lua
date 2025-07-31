local ferris = require("ferris")
local view = require("ferris.view")

---Expands the macro under the current cursor position.
local function expand_macro()
  local client = ferris.ra_client()
  if not client then
    return
  end

  client:request(
    "rust-analyzer/expandMacro",
    vim.lsp.util.make_position_params(0, client.offset_encoding),
    function(err, response)
      if err then
        vim.notify("error opening external documentation: " .. err, vim.log.levels.ERROR)
        return
      end

      ---@type string
      local name = response.name
      ---@type string
      local expansion = response.expansion

      view.open("macro", expansion, "Recursive expansion of the " .. name .. " macro")
    end
  )
end

return expand_macro
