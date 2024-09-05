local IsNotVsCode = require('vscode').IsNotVsCode()

return {
  'bkad/CamelCaseMotion',
  {
    dir = '~/.config/nvim/yaml_utils',
    enabled = IsNotVsCode,
    opts = {},
  },
  {
    dir = '~/.config/nvim/json_utils',
    enabled = IsNotVsCode,
    opts = {},
  },
  {
    'echasnovski/mini.surround',
    version = '*',
    opts = {
      n_lines = 1000
    },
  },
  {
    'svermeulen/vim-cutlass',
    config = function()
      vim.keymap.set('n', 'm', 'd')
      vim.keymap.set('x', 'm', 'd')

      vim.keymap.set('n', 'mm', 'dd')
      vim.keymap.set('n', 'M', 'D')
      vim.keymap.set('v', 'P', 'p')
      vim.keymap.set('v', 'p', 'P')
    end,
  },
  {
    'tomasky/bookmarks.nvim',
    enabled = IsNotVsCode,
    config = function()
      local bm = require("bookmarks")
      bm.setup()

      vim.api.nvim_create_user_command("BookmarkToggle", bm.bookmark_toggle,
        { desc = "Add or remove bookmark at current line" })
      vim.api.nvim_create_user_command("BookmarkAnnotate", bm.bookmark_ann,
        { desc = "Add or edit mark annotation at current line" })

      vim.keymap.set('n', 'tm', function()
        require('telescope').extensions.bookmarks.list()
      end, {})
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    enabled = IsNotVsCode,
    run = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = { "lua", "rust" },
      ignore_install = {},
      modules = {},
      sync_install = false,
      auto_install = true,

      highlight = {
        enable = true,
        disable = function(lang, buf)
          return lang == "rust" and vim.api.nvim_buf_line_count(buf) >= 10000
        end,
        additional_vim_regex_highlighting = { "yaml" },
      },
    }
  },
  {
    'poljar/typos.nvim',
    enabled = IsNotVsCode,
    opts = {}
  },
  {
    'wakatime/vim-wakatime',
    enabled = IsNotVsCode,
    lazy = false,
  }
}
