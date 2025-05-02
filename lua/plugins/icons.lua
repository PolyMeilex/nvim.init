return {
  {
    "echasnovski/mini.icons",
    config = function()
      require("mini.icons").setup({
        lsp = {
          ["function"] = { glyph = "󰊕", hl = "MiniIconsAzure" },
        },
      })

      require("mini.icons").tweak_lsp_kind()
      -- require("mini.icons").mock_nvim_web_devicons()
    end,
  },
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
