function IsNotVsCode()
  return vim.g.vscode == nil
end

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

require("lazy").setup {
  'bkad/CamelCaseMotion',
  'tpope/vim-surround',
  {
    'svermeulen/vim-cutlass',
    config = function()
      require("config.cutlass")
    end,
  },
  {
    'saecki/crates.nvim',
    enabled = IsNotVsCode,
    -- tag = 'stable',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local crates = require('crates')
      crates.setup({
        src = {
          cmp = {
            enabled = true,
          }
        }
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
    'numToStr/Comment.nvim',
    enabled = IsNotVsCode,
    config = function()
      require('Comment').setup()
      local ft = require('Comment.ft')
      ft.vala = { '//%s', '/*%s*/' }
      ft.wgsl = { '//%s', '/*%s*/' }
    end
  },
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
  {
    'nvim-lualine/lualine.nvim',
    enabled = IsNotVsCode,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'SmiteshP/nvim-navic',
    },
    config = function()
      require('config.lualine')
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.2',
    enabled = IsNotVsCode,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-file-browser.nvim',
      'nvim-telescope/telescope-ui-select.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build =
        'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
      },
    },
    config = function()
      require("config.telescope")
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    enabled = IsNotVsCode,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("config.tree")
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    enabled = IsNotVsCode,
    run = ':TSUpdate',
    config = function()
      require("config.treesitter")
    end,
  },
  {
    'kevinhwang91/nvim-ufo',
    enabled = IsNotVsCode,
    dependencies = 'kevinhwang91/promise-async',
    config = function()
      require("config.ufo")
    end,
  },
  {
    'VonHeikemen/lsp-zero.nvim',
    enabled = IsNotVsCode,
    branch = 'v3.x',
    dependencies = {
      { 'neovim/nvim-lspconfig' },
      {
        'williamboman/mason.nvim',
        run = function()
          pcall(vim.api.nvim_command, 'MasonUpdate')
        end,
      },
      { 'williamboman/mason-lspconfig.nvim' },

      { 'FelipeLema/cmp-async-path' },
      { 'hrsh7th/nvim-cmp' },
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'L3MON4D3/LuaSnip' },
      { 'SmiteshP/nvim-navic' },
      {
        "folke/neodev.nvim",
        config = function()
          require("neodev").setup()
        end
      },
      "ray-x/lsp_signature.nvim",
      "RRethy/vim-illuminate",
    },
    config = function()
      require("config.lsp")
    end,
  },
  {
    'j-hui/fidget.nvim',
    enabled = IsNotVsCode,
    tag = 'legacy',
    config = function()
      require("fidget").setup({
        window = { blend = 0 },
      })
    end,
  },
  {
    'morhetz/gruvbox',
    enabled = IsNotVsCode,
    config = function()
      require("config.colorscheme")
    end,
  },
}
