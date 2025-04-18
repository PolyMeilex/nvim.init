local IsNotVsCode = require("vscode").IsNotVsCode()

return {
  {
    "bkad/CamelCaseMotion",
    keys = { "<leader>" },
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
    "echasnovski/mini.surround",
    version = "*",
    opts = {
      n_lines = 1000,
    },
  },
  {
    "svermeulen/vim-cutlass",
    config = function()
      vim.keymap.set("n", "m", "d")
      vim.keymap.set("x", "m", "d")

      vim.keymap.set("n", "mm", "dd")
      vim.keymap.set("n", "M", "D")
      vim.keymap.set("v", "P", "p")
      vim.keymap.set("v", "p", "P")
    end,
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
        disable = function(lang, buf)
          return lang == "rust" and vim.api.nvim_buf_line_count(buf) >= 10000
        end,
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
