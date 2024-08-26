local IsNotVsCode = require('vscode').IsNotVsCode()

return {
  {
    'f-person/git-blame.nvim',
    enabled = IsNotVsCode,
    config = function()
      vim.cmd "GitBlameDisable"
    end
  },
  {
    'echasnovski/mini.diff',
    version = '*',
    config = function()
      require('mini.diff').setup({
        view = {
          style = 'sign',
          priority = 0,
        },
        mappings = {
          goto_next = 'tg',
          goto_prev = 'tG',
        },
        options = {
          wrap_goto = true,
        }
      })
    end
  },
}
