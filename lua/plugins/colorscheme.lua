local IsNotVsCode = require('vscode').IsNotVsCode()

return {
  'ellisonleao/gruvbox.nvim',
  enabled = IsNotVsCode,
  priority = 1000,
  config = function()
    require("gruvbox").setup({
      -- transparent_mode = true,
      terminal_colors = false,
    })

    vim.cmd.colorscheme("gruvbox")
    -- vim.cmd.colorscheme("retrobox")

    vim.api.nvim_set_hl(0, "Normal", { bg = "#1f1f1f" })

    vim.api.nvim_set_hl(0, "LspInlayHint", { bg = "#36302c", fg = "#878787" })

    vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { link = "GruvboxGreenBold" })
    vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { link = "GruvboxGreenBold" })

    vim.api.nvim_set_hl(0, "IlluminatedWordText", { bold = true })
    vim.api.nvim_set_hl(0, "IlluminatedWordRead", { bold = true })
    vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { bold = true })
  end,
}
