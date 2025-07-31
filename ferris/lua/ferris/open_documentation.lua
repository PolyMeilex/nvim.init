local ferris = require("ferris")

local function open_documentation()
  local client = ferris.ra_client()
  if not client then
    return
  end

  client:request(
    "experimental/externalDocs",
    vim.lsp.util.make_position_params(0, client.offset_encoding),
    function(err, response)
      if err then
        vim.notify("error opening external documentation: " .. err, vim.log.levels.ERROR)
        return
      end

      -- TODO: https://github.com/rust-lang/rust-analyzer/blob/master/docs/book/src/contributing/lsp-extensions.md#local-documentation
      -- local url = response.result["local"] or response.result.web or response.result

      vim.system({ "xdg-open", response })
    end
  )
end

return open_documentation
