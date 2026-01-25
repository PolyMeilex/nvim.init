vim.g.camelcasemotion_key = "<leader>"

return {
  "bkad/CamelCaseMotion",
  {
    dir = "~/.config/nvim/yaml_utils",
    ft = "yaml",
    opts = {},
  },
  {
    dir = "~/.config/nvim/json_utils",
    ft = "json",
    opts = {},
  },
  {
    dir = "~/.config/nvim/rs-derive-menu",
    ft = "rust",
    dependencies = { { dir = "~/.config/nvim/renui" } },
    opts = {},
  },
  {
    dir = "~/.config/nvim/railgun",
    dependencies = { "nvim-lua/plenary.nvim" },
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
    dir = "~/.config/nvim/rust-targets",
    opts = {},
  },
  {
    dir = "~/.config/nvim/venn",
    config = function()
      -- venn.nvim: enable or disable keymappings
      function _G.Toggle_venn()
        local venn_enabled = vim.inspect(vim.b.venn_enabled)
        if venn_enabled == "nil" then
          vim.b.venn_enabled = true
          vim.cmd([[setlocal ve=all]])
          -- draw a line on HJKL keystokes
          vim.api.nvim_buf_set_keymap(0, "n", "J", "<C-v>j:VBox<CR>", { noremap = true })
          vim.api.nvim_buf_set_keymap(0, "n", "K", "<C-v>k:VBox<CR>", { noremap = true })
          vim.api.nvim_buf_set_keymap(0, "n", "L", "<C-v>l:VBox<CR>", { noremap = true })
          vim.api.nvim_buf_set_keymap(0, "n", "H", "<C-v>h:VBox<CR>", { noremap = true })
          -- draw a box by pressing "f" with visual selection
          vim.api.nvim_buf_set_keymap(0, "v", "f", ":VBoxO<CR>", { noremap = true })
        else
          vim.cmd([[setlocal ve=]])
          vim.api.nvim_buf_del_keymap(0, "n", "J")
          vim.api.nvim_buf_del_keymap(0, "n", "K")
          vim.api.nvim_buf_del_keymap(0, "n", "L")
          vim.api.nvim_buf_del_keymap(0, "n", "H")
          vim.api.nvim_buf_del_keymap(0, "v", "f")

          vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
          vim.b.venn_enabled = nil
        end
      end
      -- toggle keymappings for venn using <leader>v
      vim.api.nvim_set_keymap("n", "<leader>v", ":lua Toggle_venn()<CR>", { noremap = true })
    end,
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
    lazy = false,
    build = ":TSUpdate",
    branch = "main",
  },
  {
    "wakatime/vim-wakatime",
    lazy = false,
  },
}
