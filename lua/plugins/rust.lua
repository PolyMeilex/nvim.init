local IsNotVsCode = require('vscode').IsNotVsCode()

return {
  {
    'saecki/crates.nvim',
    enabled = IsNotVsCode,
    -- tag = 'stable',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local crates = require('crates')
      crates.setup({
        lsp = {
          enabled = true,
          completion = true,
          hover = true,
          actions = true,
        },
      })

      vim.keymap.set('n', '<leader>cv', function()
        crates.show_versions_popup()
        crates.focus_popup()
      end, {})
      vim.keymap.set('n', '<leader>cf', function()
        crates.show_features_popup()
        crates.focus_popup()
      end, {})
    end
  },
  {
    'vxpm/ferris.nvim',
    enabled = IsNotVsCode,
    opts = {
      create_commands = true,
    },
  },
}
