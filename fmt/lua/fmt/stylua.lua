local lsp = require("fmt.lsp")

local M = {}

local function run_stylua(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local buffer_as_string = table.concat(lines, "\n")

  local out = vim
    .system(
      { "stylua", "--search-parent-directories", "--stdin-filepath", file, "-" },
      { stdin = buffer_as_string, text = true }
    )
    :wait()

  if out.code == 0 then
    local new_lines = vim.split(out.stdout, "\n")
    table.remove(new_lines)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
  end
end

function M.start(bufnr)
  lsp.fmt_lsp_start({
    name = "stylua-lsp",
    handle_format = function(method, params)
      local buffer = vim.uri_to_bufnr(params.textDocument.uri)
      run_stylua(buffer)
      -- TODO: Return TextEdit instead
      return {}
    end,
    bufnr = bufnr,
  })
end

return M
