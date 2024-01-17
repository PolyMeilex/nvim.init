local telescope = require("telescope")
local builtin = require('telescope.builtin')
local actions = require('telescope.actions')

vim.keymap.set('n', 'tpf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', 'tc', builtin.commands, {})
vim.keymap.set('n', 'tf', builtin.current_buffer_fuzzy_find, {})
vim.keymap.set('n', 'tF', builtin.live_grep, {})
vim.keymap.set('n', 'tu', function()
  builtin.oldfiles({ only_cwd = true })
end, {})
vim.keymap.set('n', 'tb', builtin.buffers, {})

vim.keymap.set('n', 'tt', builtin.lsp_document_symbols, {})
vim.keymap.set('n', 'td', function()
  builtin.diagnostics({ severity_bound = "ERROR" })
end, {})

telescope.setup({
  pickers = {
    buffers = {
      sort_lastused = true,
      mappings = {
        n = {
          ['<c-d>'] = actions.delete_buffer
        },
        i = {
          ['<c-d>'] = actions.delete_buffer
        },
      },
    },
  },

  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_dropdown()
    },
  }
})
telescope.load_extension("file_browser")
telescope.load_extension("ui-select")
telescope.load_extension('fzf')

-- open file_browser with the path of the current buffer
vim.api.nvim_set_keymap(
  "n",
  "<leader>fb",
  ":Telescope file_browser path=%:p:h select_buffer=true<CR>",
  { noremap = true }
)
