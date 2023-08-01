vim.o.guifont = "Source Code Pro:h11"
vim.g.neovide_cursor_animation_length = 0.1
vim.g.neovide_cursor_trail_size = 0.1

vim.opt.termguicolors = true
vim.g.mapleader = " "
vim.g.camelcasemotion_key = '<leader>'
vim.opt.number = true;
vim.opt.rnu = true;
vim.opt.tabstop = 4;
vim.opt.clipboard = vim.opt.clipboard + "unnamedplus";

require("plugins")
