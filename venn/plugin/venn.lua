vim.cmd([[command! -range VBox lua require"venn".draw_box("s")]])
vim.cmd([[command! -range VBoxD lua require"venn".draw_box("d")]])
vim.cmd([[command! -range VBoxH lua require"venn".draw_box("b")]])

vim.cmd([[command! -range VBoxO lua require"venn".draw_box_over("s")]])
vim.cmd([[command! -range VBoxDO lua require"venn".draw_box_over("d")]])
vim.cmd([[command! -range VBoxHO lua require"venn".draw_box_over("b")]])

vim.cmd([[command! -range VFill lua require"venn".fill_box()]])
