vim.api.nvim_create_autocmd("FileType", {
  desc = "Treesitter init",
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
