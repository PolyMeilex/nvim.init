local IsNotVsCode = require("vscode").IsNotVsCode()

return {
  {
    "nvim-tree/nvim-web-devicons",
    enabled = IsNotVsCode,
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
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    enabled = IsNotVsCode,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {},
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
