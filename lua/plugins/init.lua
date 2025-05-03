local IsNotVsCode = require("vscode").IsNotVsCode()

return {
  {
    "bkad/CamelCaseMotion",
    config = function()
      vim.g.camelcasemotion_key = "<leader>"
    end,
  },
  {
    dir = "~/.config/nvim/yaml_utils",
    ft = "yaml",
    enabled = IsNotVsCode,
    opts = {},
  },
  {
    dir = "~/.config/nvim/json_utils",
    ft = "json",
    enabled = IsNotVsCode,
    opts = {},
  },
  {
    dir = "~/.config/nvim/rs-derive-menu",
    enabled = IsNotVsCode,
    ft = "rust",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {},
  },
  {
    dir = "~/.config/nvim/railgun",
    dependencies = { "nvim-lua/plenary.nvim" },
    enabled = IsNotVsCode,
    keys = {
      {
        "tm",
        function()
          require("telescope").extensions.railgun.list()
        end,
      },
    },
    opts = {},
  },
  {
    dir = "~/.config/nvim/black-hole",
    opts = {},
  },
  {
    "echasnovski/mini.surround",
    version = "*",
    opts = {
      n_lines = 1000,
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    enabled = IsNotVsCode,
    run = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = { "lua", "rust" },
      ignore_install = {},
      modules = {},
      sync_install = false,
      auto_install = true,

      highlight = {
        enable = true,
        -- disable = function(lang, buf)
        --   return lang == "rust" and vim.api.nvim_buf_line_count(buf) >= 10000
        -- end,
        additional_vim_regex_highlighting = { "yaml" },
      },
    },
  },
  {
    "wakatime/vim-wakatime",
    enabled = IsNotVsCode,
    lazy = false,
  },
}
