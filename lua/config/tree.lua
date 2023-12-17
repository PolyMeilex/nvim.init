vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.fn.sign_define("DiagnosticSignError",
  { text = " ", texthl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarn",
  { text = " ", texthl = "DiagnosticSignWarn" })
vim.fn.sign_define("DiagnosticSignInfo",
  { text = " ", texthl = "DiagnosticSignInfo" })
vim.fn.sign_define("DiagnosticSignHint",
  { text = "󰌵", texthl = "DiagnosticSignHint" })

require("neo-tree").setup({
  filesystem = {
    follow_current_file = {
      enabled = true,
      leave_dirs_open = false,
    },
    window = {
      mappings = {
        ["<C-e>"] = "close_window",
        ["<S-f>"] = function(state)
          local node = state.tree:get_node();
          if node.type == "directory" then
            require('telescope.builtin').live_grep({ cwd = node.path })
          end
        end,
        ["<C-f>"] = function(state)
          local node = state.tree:get_node();
          if node.type == "directory" then
            require('telescope.builtin').find_files({ cwd = node.path })
          end
        end,
      },
    },
  },
})

vim.keymap.set('n', '<C-e>', function()
  vim.cmd("Neotree")
end, {})
