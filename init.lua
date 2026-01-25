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

vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.termguicolors = true
vim.o.number = true
vim.o.rnu = true
vim.o.tabstop = 4

vim.g.mapleader = " "
vim.g.camelcasemotion_key = "<leader>"

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
  vim.diagnostic.config({
    virtual_text = {
      severity = vim.diagnostic.severity.ERROR,
    },
    signs = { text = require("poly.icons").diagnostic_signs },
  })

  --- @param opts vim.diagnostic.JumpOpts
  local function jump_cb(opts)
    return function()
      vim.diagnostic.jump(opts)
    end
  end

  vim.keymap.set("n", "gl", vim.diagnostic.open_float)
  vim.keymap.set("n", "[d", jump_cb({ count = -1, severity = { min = vim.diagnostic.severity.WARN } }))
  vim.keymap.set("n", "]d", jump_cb({ count = 1, severity = { min = vim.diagnostic.severity.WARN } }))
  vim.keymap.set("n", "[D", jump_cb({ count = -1, severity = { min = vim.diagnostic.severity.ERROR } }))
  vim.keymap.set("n", "]D", jump_cb({ count = 1, severity = { min = vim.diagnostic.severity.ERROR } }))
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

-- harpoon
do
  local function select_cb(index)
    return function()
      require("harpoon"):list():select(index)
    end
  end

  vim.keymap.set("n", "<leader>a", function()
    require("harpoon"):list():add()
  end)
  vim.keymap.set("n", "<leader>h", function()
    local harpoon = require("harpoon")
    harpoon.ui:toggle_quick_menu(harpoon:list())
  end)
  vim.keymap.set("n", "<C-h>", select_cb(1))
  vim.keymap.set("n", "<C-j>", select_cb(2))
  vim.keymap.set("n", "<C-k>", select_cb(3))
  vim.keymap.set("n", "<C-l>", select_cb(4))
  vim.keymap.set("n", "<C-;>", select_cb(5))
end

vim.api.nvim_create_user_command("MiniDiffToggleOverlay", function()
  require("mini.diff").toggle_overlay(0)
end, {})

vim.api.nvim_create_user_command("LspToggleInlayHints", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
end, {})

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP attach actions",
  callback = function(event)
    local bufnr = event.buf

    ---@type vim.lsp.Client|nil
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client == nil then
      return
    end

    local telescope = require("telescope.builtin")
    local opts = { buffer = bufnr }

    vim.keymap.set("n", "gd", telescope.lsp_definitions, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gi", telescope.lsp_incoming_calls, opts)
    vim.keymap.set("n", "gI", telescope.lsp_implementations, opts)
    vim.keymap.set("n", "go", telescope.lsp_type_definitions, opts)
    vim.keymap.set("n", "gr", telescope.lsp_references, opts)

    vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action, opts)
  end,
})

require("poly.lazy_init")
require("poly.bracketed").setup()
require("poly.black-hole").setup()
require("poly.inside").setup()
require("poly.ui_input")
require("poly.completion").setup()
require("poly.statusline").setup()
require("poly.telescope").setup()
require("poly.lsp")
