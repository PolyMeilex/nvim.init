return {
  "ellisonleao/gruvbox.nvim",
  priority = 1000,
  config = function()
    require("gruvbox").setup({
      -- transparent_mode = true,
      terminal_colors = false,
      overrides = {
        PmenuSel = { fg = "NONE", bg = "#4d4d4d" },
        Pmenu = { fg = "NONE", bg = "#2e2e2e" },
        LspReferenceText = { bold = true },
        LspReferenceRead = { bold = true },
        LspReferenceWrite = { bold = true },
        TelescopeResultsBorder = { link = "FloatBorder" },
        TelescopePromptBorder = { link = "FloatBorder" },
        TelescopePreviewBorder = { link = "FloatBorder" },
        FloatBorder = { bg = "#1f1f1f", fg = "#4e433a" },
        NormalFloat = { link = "Normal" },
        WinSeparator = { bg = "#1f1f1f", fg = "#322d29" },
        YankIncSearch = { bg = "#544C45", fg = "NONE", reverse = false, bold = true },
        SignColumn = { link = "Normal" },

        WinBar = { link = "Normal" },
        WinBarNC = { link = "NormalNC" },

        StatusLine = { link = "Normal" },
        StatusLineNC = { link = "NormalNC" },

        Normal = { bg = "#1f1f1f" },
        NormalNC = { bg = "#1c1c1c" },

        LspInlayHint = { bg = "#36302c", fg = "#878787" },
        NeoTreeDirectoryIcon = { link = "GruvboxGreenBold" },
        NeoTreeDirectoryName = { link = "GruvboxGreenBold" },
      },
    })

    vim.cmd.colorscheme("gruvbox")
  end,
}
