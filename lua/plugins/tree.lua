local IsNotVsCode = require("vscode").IsNotVsCode()

return {
  {
    "nvim-tree/nvim-web-devicons",
    enabled = IsNotVsCode,
    lazy = true,
    opts = {
      override = {
        rs = {
          icon = "",
          color = "#f46623",
          cterm_color = "216",
          name = "Rs",
        },
      },
    },
  },
  {
    dir = "~/.config/nvim/teletree",
    enabled = IsNotVsCode,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
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
    },
  },
}
