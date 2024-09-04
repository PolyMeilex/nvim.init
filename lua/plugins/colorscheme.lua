local IsNotVsCode = require('vscode').IsNotVsCode()

return {
  'ellisonleao/gruvbox.nvim',
  enabled = IsNotVsCode,
  priority = 1000,
  config = function()
    require("gruvbox").setup({
      -- transparent_mode = true,
      terminal_colors = false,
      overrides = {
        PmenuSel = { fg = "NONE", bg = "#4d4d4d" },
        Pmenu = { fg = "NONE", bg = "#2e2e2e" }
      }
    })

    vim.cmd.colorscheme("gruvbox")
    -- vim.cmd.colorscheme("retrobox")

    vim.api.nvim_set_hl(0, "WinBar", { bg = "#303030" })
    vim.api.nvim_set_hl(0, "StatusLine", { bg = "#303030" })
    vim.api.nvim_set_hl(0, "WinBarTerminator", { fg = "#1f1f1f", bg = "#303030" })

    vim.api.nvim_set_hl(0, "Normal", { bg = "#1f1f1f" })

    vim.api.nvim_set_hl(0, "LspInlayHint", { bg = "#36302c", fg = "#878787" })

    vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { link = "GruvboxGreenBold" })
    vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { link = "GruvboxGreenBold" })

    vim.api.nvim_set_hl(0, "IlluminatedWordText", { bold = true })
    vim.api.nvim_set_hl(0, "IlluminatedWordRead", { bold = true })
    vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { bold = true })
  end,
}
