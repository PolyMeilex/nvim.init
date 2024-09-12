local IsNotVsCode = require('vscode').IsNotVsCode()

return {
  {
    'f-person/git-blame.nvim',
    enabled = IsNotVsCode,
    opts = {
      enabled = false,
      message_template = "<author>, <date>: <summary>",
      date_format = "%r",
      set_extmark_options = {
        virt_text_pos = "right_align",
      },
    }
  },
  {
    'echasnovski/mini.diff',
    version = '*',
    enabled = IsNotVsCode,
    opts = {
      view = {
        style = 'sign',
        priority = 0,
      },
      mappings = {
        goto_next = ']g',
        goto_prev = '[g',
      },
      options = {
        wrap_goto = true,
      },
    }
  },
}
