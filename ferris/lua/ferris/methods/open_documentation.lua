local lsp = require("ferris.private.ra_lsp")
local error = require("ferris.private.error")

local function open_documentation()
  if not error.ensure_ra() then
    return
  end

  lsp.experimental_request(
    "externalDocs",
    vim.lsp.util.make_position_params(0, lsp.offset_encoding()),
    function(response)
      if response.result == nil then
        if response.error == nil then
          error.raise("no answer from rust-analyzer for external documentation")
          return
        end

        error.raise_lsp_error("error opening external documentation", response.error)
        return
      end

      local url = response.result["local"] or response.result.web or response.result
      vim.system({ "xdg-open", url })
    end
  )
end

return open_documentation
