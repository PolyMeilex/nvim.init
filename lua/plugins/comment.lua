local IsNotVsCode = require('vscode').IsNotVsCode()

return {
  'numToStr/Comment.nvim',
  enabled = IsNotVsCode,
  config = function()
    require('Comment').setup()
    local ft = require('Comment.ft')
    ft.vala = { '//%s', '/*%s*/' }
    ft.wgsl = { '//%s', '/*%s*/' }
  end
}
