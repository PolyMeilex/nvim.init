local IsNotVsCode = require('vscode').IsNotVsCode()

return {
  {
    'f-person/git-blame.nvim',
    enabled = IsNotVsCode,
    config = function()
      vim.cmd "GitBlameDisable"
    end
  },
  {
    'lewis6991/gitsigns.nvim',
    enabled = IsNotVsCode,
    config = function()
      require('gitsigns').setup()

      vim.keymap.set('n', 'tg', function()
        require('gitsigns').next_hunk()
      end, {})

      vim.keymap.set('n', 'tG', function()
        require('gitsigns').prev_hunk()
      end, {})
    end,
  },
}
