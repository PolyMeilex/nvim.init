local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.keymap.set("n", "<C-e>", function()
  require("teletree").open()
end)
vim.keymap.set("n", "<C-s>", function()
  require("teletree.symbols").open()
end)

require("lazy").setup({
  -- Deps
  { dir = "~/.config/nvim/renui" },
  "nvim-lua/plenary.nvim",

  -- Plugins
  "bkad/CamelCaseMotion",
  { dir = "~/.config/nvim/yaml_utils", ft = "yaml", opts = {} },
  { dir = "~/.config/nvim/json_utils", ft = "json", opts = {} },
  { dir = "~/.config/nvim/lsp-code-context", opts = {} },
  { dir = "~/.config/nvim/rs-derive-menu", ft = "rust", opts = {} },
  { dir = "~/.config/nvim/railgun", opts = {} },
  { dir = "~/.config/nvim/rust-targets", opts = {} },
  { dir = "~/.config/nvim/path-lsp", opts = {} },
  { dir = "~/.config/nvim/gitblame", opts = {} },
  { dir = "~/.config/nvim/ferris", ft = "rust", opts = { create_commands = true } },
  { dir = "~/.config/nvim/omni_picker" },
  { dir = "~/.config/nvim/teletree", opts = {} },
  {
    dir = "~/.config/nvim/fmt",
    --- @type fmt.setup.Opts
    opts = {
      formatters = {
        rust = { on_save = true },
        lua = { lsp_name = "stylua", on_save = true },
      },
      on_attach = function(buffer, format)
        vim.keymap.set("n", "<F3>", function()
          format({ async = true })
        end)
        vim.keymap.set("x", "<F3>", function()
          format({ async = true })
        end)
      end,
    },
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
  { "wakatime/vim-wakatime", lazy = false },
  { "ThePrimeagen/harpoon", branch = "harpoon2", lazy = true },
  { "williamboman/mason.nvim", opts = {} },
  { "nvim-treesitter/nvim-treesitter", lazy = false, build = ":TSUpdate", branch = "main" },
  { "echasnovski/mini.surround", opts = { n_lines = 1000 } },
  {
    "echasnovski/mini.diff",
    opts = {
      view = { style = "sign", priority = 0 },
      options = { wrap_goto = true },
    },
  },
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    opts = {
      override = {
        rs = {
          icon = "",
          color = "#f46623",
          cterm_color = "216",
          name = "Rs",
        },
      },
    },
  },
  "neovim/nvim-lspconfig",
  "nvim-telescope/telescope.nvim",
  "nvim-telescope/telescope-ui-select.nvim",
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
    },
  },
  {
    "saecki/crates.nvim",
    ft = "toml",
    config = function()
      local crates = require("crates")
      crates.setup({
        lsp = {
          enabled = true,
          completion = true,
          hover = true,
          actions = true,
        },
      })

      vim.keymap.set("n", "<leader>cv", function()
        crates.show_versions_popup()
        crates.focus_popup()
      end, {})
      vim.keymap.set("n", "<leader>cf", function()
        crates.show_features_popup()
        crates.focus_popup()
      end, {})
    end,
  },
  {
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
  },
})
