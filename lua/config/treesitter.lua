vim.filetype.add({ extension = { wgsl = "wgsl" } })

require 'nvim-treesitter.configs'.setup {
  ensure_installed = { "lua", "rust" },
  sync_install = false,
  auto_install = true,

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = true,
  },
}
