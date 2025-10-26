local SymbolKind = vim.lsp.protocol.SymbolKind

local M = {}
M.icons = {
  [SymbolKind.File] = "󰈙 ",
  [SymbolKind.Module] = " ",
  [SymbolKind.Namespace] = "󰌗 ",
  [SymbolKind.Package] = " ",
  [SymbolKind.Class] = "󰌗 ",
  [SymbolKind.Method] = "󰆧 ",
  [SymbolKind.Property] = " ",
  [SymbolKind.Field] = " ",
  [SymbolKind.Constructor] = " ",
  [SymbolKind.Enum] = "󰕘 ",
  [SymbolKind.Interface] = "󰕘 ",
  [SymbolKind.Function] = "󰊕 ",
  [SymbolKind.Variable] = "󰆧 ",
  [SymbolKind.Constant] = "󰏿 ",
  [SymbolKind.String] = "󰀬 ",
  [SymbolKind.Number] = "󰎠 ",
  [SymbolKind.Boolean] = "◩ ",
  [SymbolKind.Array] = "󰅪 ",
  [SymbolKind.Object] = "󰅩 ",
  [SymbolKind.Key] = "󰌋 ",
  [SymbolKind.Null] = "󰟢 ",
  [SymbolKind.EnumMember] = " ",
  [SymbolKind.Struct] = "󰌗 ",
  [SymbolKind.Event] = " ",
  [SymbolKind.Operator] = "󰆕 ",
  [SymbolKind.TypeParameter] = "󰊄 ",
  [255] = "󰉨 ", -- Macro
}

setmetatable(M.icons, {
  __index = function()
    return "? "
  end,
})

function M.adapt_lsp_num_to_str(n)
  for name, value in pairs(vim.lsp.protocol.SymbolKind) do
    if n == value then
      return name
    end
  end

  return "Text"
end

local function range_contains_pos(range, line, char)
    local start = range.start
    local stop = range['end']

    if line < start.line or line > stop.line then
        return false
    end

    if line == start.line and char < start.character then
        return false
    end

    if line == stop.line and char > stop.character then
        return false
    end

    return true
end

local function find_symbol_path(symbol_list, line, char, path)
    if not symbol_list or #symbol_list == 0 then
        return false
    end

    for _, symbol in ipairs(symbol_list) do
        if range_contains_pos(symbol.range, line, char) then
            table.insert(path, symbol)
            find_symbol_path(symbol.children, line, char, path)
            return true
        end
    end
    return false
end

function M.get_context_data(bufnr)
  return vim.b[bufnr].lsp_code_context_path or {}
end

function M.get_label()
  return vim.b.lsp_code_context_label or ""
end

function M.update_label(event)
    local pos = vim.api.nvim_win_get_cursor(0)
    local cursor_line = pos[1] - 1
    local cursor_char = pos[2]

    local path = { }

    local symbols = vim.b[event.buf].lsp_code_context_symbols or {}
    find_symbol_path(symbols, cursor_line, cursor_char, path)

    local function add_hl(kind, name)
      return "%#NavicIcons"
        .. M.adapt_lsp_num_to_str(kind)
        .. "#"
        .. M.icons[kind]
        .. "%*%#NavicText#"
        .. name
        .. "%*"
    end

    local sections = {}
    for _, symbol in ipairs(path) do
        table.insert(sections, add_hl(symbol.kind, symbol.name))
    end

    local breadcrumb_string = table.concat(sections, " > ")
    vim.b[event.buf].lsp_code_context_path = path
    vim.b[event.buf].lsp_code_context_label = breadcrumb_string
end

local function lsp_callback(err, symbols, ctx)
    if err or not symbols then
      vim.b[ctx.bufnr].lsp_code_context_symbols = {}
    else
      vim.b[ctx.bufnr].lsp_code_context_symbols = symbols
    end
end

function M.request_symbols()
    local bufnr = vim.api.nvim_get_current_buf()
    local uri = vim.lsp.util.make_text_document_params(bufnr)["uri"]
    if not uri then
        vim.print("Error: Could not get URI for buffer. Is it saved?")
        return
    end

    local params = {
        textDocument = {
            uri = uri
        }
    }
    vim.lsp.buf_request(
        bufnr,
        'textDocument/documentSymbol',
        params,
        lsp_callback
    )
end

return M
