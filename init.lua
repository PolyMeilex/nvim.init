vim.o.guifont = "Source Code Pro:h11"
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.undofile = true
vim.o.signcolumn = "yes"

vim.g.neovide_cursor_animation_length = 0.1
vim.g.neovide_cursor_trail_size = 0.1

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.g.mapleader = " "
vim.g.camelcasemotion_key = "<leader>"
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

require("lazy_init")
