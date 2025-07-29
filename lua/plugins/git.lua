return {
  {
    dir = "~/.config/nvim/gitblame",
    opts = {},
  },
  {
    "echasnovski/mini.diff",
    version = "*",
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
