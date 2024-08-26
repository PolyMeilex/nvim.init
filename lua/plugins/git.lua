local IsNotVsCode = require('vscode').IsNotVsCode()

return {
  {
    'f-person/git-blame.nvim',
    enabled = IsNotVsCode,
    config = function()
      require("gitblame").setup({
        message_template = "<author>, <date>: <summary>",
        date_format = "%r",
        set_extmark_options = {
          virt_text_pos = "right_align",
        },
      })

      vim.cmd "GitBlameDisable"
    end
  },
  {
    'echasnovski/mini.diff',
    version = '*',
    enabled = IsNotVsCode,
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
        },
      })
    end
  },
}
