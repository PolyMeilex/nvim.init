vim.cmd "set clipboard+=unnamedplus"
vim.cmd 'set tabstop=4'
vim.cmd 'set number'
vim.cmd 'set rnu'
vim.o.guifont = "Source Code Pro:h14"
vim.opt.termguicolors = true
vim.g.mapleader = " "
vim.g.camelcasemotion_key = '<leader>'

require("plugins")
