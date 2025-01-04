local M = {}

--- @class fmt.formatter.Opts
--- @field lsp_name? string
--- @field startup? fun(bufnr: integer)
--- @field on_save? boolean
---
--- @alias fmt.FormattersMap table<string, fmt.formatter.Opts>
--- @alias vim.lsp.buf.format fun(opts: vim.lsp.buf.format.Opts)
--- @alias fmt.on_attach fun(buffer: integer, format: vim.lsp.buf.format)

--- @param formatters fmt.FormattersMap
--- @return vim.lsp.buf.format
local function create_format_function(formatters)
  return function(opts)
    if opts.bufnr == nil then
      opts.bufnr = vim.api.nvim_get_current_buf()
    end

    if opts.name == nil then
      local filetype = vim.bo[opts.bufnr].filetype
      local fmt_opts = formatters[filetype]

      if fmt_opts ~= nil then
        local lsp_name = formatters[filetype].lsp_name

        if lsp_name ~= nil then
          opts.name = lsp_name
        end
      end
    end

    vim.lsp.buf.format(opts)
  end
end

--- @param buffer integer
--- @param format vim.lsp.buf.format
local function register_format_on_save(buffer, format)
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = buffer,
    callback = function()
      format({ bufnr = buffer })
    end,
  })
end

--- @class fmt.setup.Opts
--- @field formatters fmt.FormattersMap
--- @field on_attach fmt.on_attach
---
--- @param opts fmt.setup.Opts
--- @return vim.lsp.buf.format
function M.setup(opts)
  local formatters = opts.formatters

  --- @type vim.lsp.buf.format
  local format = create_format_function(formatters)

  for file_type, formatter_opts in pairs(formatters) do
    vim.api.nvim_create_autocmd("FileType", {
      pattern = file_type,
      callback = function(event)
        --- @type integer
        local buffer = event.buf

        if formatter_opts.startup ~= nil then
          formatter_opts.startup(buffer)
        end

        if formatter_opts.on_save then
          register_format_on_save(buffer, format)
        end
      end,
    })
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    desc = "LSP fmt attach actions",
    callback = function(event)
      opts.on_attach(event.buf, format)
    end,
  })

  return format
end

return M
