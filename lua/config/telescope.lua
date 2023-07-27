local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<C-f>', builtin.current_buffer_fuzzy_find, {})
vim.keymap.set('n', '<S-f>', builtin.live_grep, {})
vim.keymap.set('n', '<C-b>', builtin.oldfiles, {})
vim.keymap.set('n', '<C-.', vim.lsp.buf.code_action, {})

vim.keymap.set('n', '<leader>t', builtin.lsp_document_symbols, {})
vim.keymap.set('n', '<leader>d', builtin.diagnostics, {})

require("telescope").setup()
require("telescope").load_extension("file_browser")

-- open file_browser with the path of the current buffer
vim.api.nvim_set_keymap(
	"n",
	"<space>fb",
	":Telescope file_browser path=%:p:h select_buffer=true<CR>",
	{ noremap = true }
)
