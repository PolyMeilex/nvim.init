vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.undofile = true
vim.o.signcolumn = "yes"

vim.o.foldcolumn = "0"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldtext = ""
vim.o.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.rnu = true
vim.opt.tabstop = 4
vim.opt.clipboard = vim.opt.clipboard + "unnamedplus"

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.cmd(":tnoremap <C-q> <C-\\><C-n>")

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank({ higroup = "YankIncSearch" })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  desc = "Treesitter init",
  pattern = { "*" },
  callback = function()
    local treesitter = require("nvim-treesitter")

    local installed = treesitter.get_installed("parsers")
    local parser_name = vim.treesitter.language.get_lang(vim.bo.filetype)

    if vim.list_contains(installed, parser_name) then
      vim.treesitter.start(nil, parser_name)
      return
    end

    local available = treesitter.get_available()

    if not vim.list_contains(available, parser_name) then
      return
    end

    treesitter.install(parser_name):await(function()
      pcall(vim.treesitter.start, nil, parser_name)
    end)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  desc = "Force commentstring to include spaces",
  callback = function()
    local cs = vim.bo.commentstring

    if not cs or not cs:match("%%s") then
      if vim.bo.filetype == "dart" or vim.bo.filetype == "wgsl" then
        vim.bo.commentstring = "// %s"
      elseif vim.bo.filetype == "plantuml" then
        vim.bo.commentstring = "' %s"
      end

      return
    end

    vim.bo.commentstring = cs:gsub("%s*%%s%s*", " %%s "):gsub("%s*$", "")
  end,
})

vim.api.nvim_create_user_command("CodeLensRun", function()
  local old = vim.lsp.codelens.on_codelens
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.codelens.on_codelens = function(err, result, ctx)
    local res = old(err, result, ctx)
    vim.lsp.codelens.run()
    vim.lsp.codelens.clear()
    return res
  end
  vim.lsp.codelens.refresh()
  vim.lsp.codelens.on_codelens = old
end, {})

do
  local icons = require("poly.icons")

  vim.diagnostic.config({
    virtual_text = {
      severity = vim.diagnostic.severity.ERROR,
    },
    signs = { text = icons.diagnostic_signs },
  })

  vim.keymap.set("n", "gl", vim.diagnostic.open_float)

  vim.keymap.set("n", "[d", function()
    vim.diagnostic.jump({ count = -1, severity = { min = vim.diagnostic.severity.WARN } })
  end)
  vim.keymap.set("n", "]d", function()
    vim.diagnostic.jump({ count = 1, severity = { min = vim.diagnostic.severity.WARN } })
  end)

  vim.keymap.set("n", "[D", function()
    vim.diagnostic.jump({ count = -1, severity = { min = vim.diagnostic.severity.ERROR } })
  end)
  vim.keymap.set("n", "]D", function()
    vim.diagnostic.jump({ count = 1, severity = { min = vim.diagnostic.severity.ERROR } })
  end)
end

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "textDocument/document_highlight on CursorMoved",
  callback = function(event)
    ---@type vim.lsp.Client|nil
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client == nil then
      return
    end

    if not client:supports_method("textDocument/documentHighlight") then
      return
    end

    local bufnr = event.buf
    local timer = vim.loop.new_timer()
    local last_word = nil
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      buffer = bufnr,
      callback = function()
        local word = vim.fn.expand("<cword>")
        if last_word ~= word then
          last_word = word

          timer:stop()
          timer:start(
            200,
            0,
            vim.schedule_wrap(function()
              vim.lsp.buf.clear_references()
              vim.lsp.buf.document_highlight()
            end)
          )
        end
      end,
    })
  end,
})

require("poly.lazy_init")
require("poly.bracketed").setup()
require("poly.black-hole").setup()
require("poly.inside").setup()
require("poly.ui_input")
