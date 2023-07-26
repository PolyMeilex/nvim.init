vim.o.guifont = "Source Code Pro:h14"
vim.opt.termguicolors = true
vim.g.mapleader = " "
vim.g.camelcasemotion_key = '<leader>'
vim.opt.number = true;
vim.opt.rnu = true;
vim.opt.tabstop = 4;
vim.opt.clipboard = vim.opt.clipboard + "unnamedplus";

require("plugins")
