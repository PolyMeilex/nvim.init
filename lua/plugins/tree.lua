local IsNotVsCode = require("vscode").IsNotVsCode()

return {
  {
    dir = "~/.config/nvim/teletree",
    enabled = IsNotVsCode,
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    opts = {},
    keys = {
      {
        "<C-e>",
        function()
          require("teletree").open()
        end,
        desc = "TeleTree",
      },
      {
        "<C-s>",
        function()
          require("teletree.symbols").open()
        end,
        desc = "TeleTree",
      },
    },
  },
}
