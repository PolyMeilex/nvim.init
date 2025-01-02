local typos_cli = require("typos.process")
local lsp = require("typos.lsp")

local M = {}

local namespace = vim.api.nvim_create_namespace("typos")

function M.setup()
  local group = vim.api.nvim_create_augroup("typos", { clear = true })

  vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "InsertLeave" }, {
    group = group,
    callback = M.run,
  })

  vim.api.nvim_create_autocmd("BufRead", {
    group = group,
    callback = lsp.start,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(opts)
      local filetype = vim.api.nvim_get_option_value("filetype", { buf = opts.buf })

      if filetype ~= "my.ui.input" then
        return
      end

      lsp.start()
    end,
  })
end

local function json_to_diagnostic(json)
  -- TODO: Does this work with UTF-8?
  local column = json.byte_offset
  local end_column = column + string.len(json.typo)

  local got = "`" .. json.typo .. "`"
  local expected = "`" .. json.corrections[1] .. "`"
  local message = "typo: " .. got .. " should be " .. expected

  return {
    lnum = json.line_num - 1,
    col = column,
    end_col = end_column,
    severity = vim.diagnostic.severity.HINT,
    message = message,
  }
end

function M.run()
  local buffer = vim.api.nvim_get_current_buf()

  typos_cli.run_for_buffer(buffer, function(results)
    local diagnostics = vim.tbl_map(json_to_diagnostic, results)

    if vim.api.nvim_buf_is_valid(buffer) then
      vim.diagnostic.set(namespace, buffer, diagnostics)
    end
  end)
end

return M
