local IsNotVsCode = require("vscode").IsNotVsCode()

return {
  {
    dir = "~/.config/nvim/gitblame",
    enabled = IsNotVsCode,
    opts = {},
  },
  {
    "echasnovski/mini.diff",
    version = "*",
    enabled = IsNotVsCode,
    opts = {
      view = {
        style = "sign",
        priority = 0,
      },
      mappings = {
        -- goto_next = ']h',
        -- goto_prev = '[h',
      },
      options = {
        wrap_goto = true,
      },
    },
  },
}
