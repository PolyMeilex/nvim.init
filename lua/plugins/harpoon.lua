return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<leader>a",
      function()
        require("harpoon"):list():add()
      end,
    },
    {
      "<leader>h",
      function()
        local harpoon = require("harpoon")
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
    },
    {
      "<C-h>",
      function()
        require("harpoon"):list():select(1)
      end,
    },
    {
      "<C-j>",
      function()
        require("harpoon"):list():select(2)
      end,
    },
    {
      "<C-k>",
      function()
        require("harpoon"):list():select(3)
      end,
    },
    {
      "<C-l>",
      function()
        require("harpoon"):list():select(4)
      end,
    },
    {
      "<C-;>",
      function()
        require("harpoon"):list():select(5)
      end,
    },
  },
  opts = {},
}
