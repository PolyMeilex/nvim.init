vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.undofile = true
vim.o.signcolumn = "yes"

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

require("lazy_init")
require("black-hole").setup()
