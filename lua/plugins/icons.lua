return {
  -- {
  --   "echasnovski/mini.icons",
  --   config = function()
  --     require("mini.icons").setup({
  --       lsp = {
  --         ["function"] = "F",
  --       },
  --     })
  --     -- require("mini.icons").mock_nvim_web_devicons()
  --     require("mini.icons").tweak_lsp_kind()
  --   end,
  -- },
  {
    "nvim-tree/nvim-web-devicons",
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
}
