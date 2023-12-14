function IsNotVsCode()
  return vim.g.vscode == nil
end

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'bkad/CamelCaseMotion'
  use 'tpope/vim-surround'
  use {
    'svermeulen/vim-cutlass',
    config = function()
      require("config.cutlass")
    end,
  }

  use {
    'numToStr/Comment.nvim',
    cond = IsNotVsCode,
    config = function()
      require('Comment').setup()
    end
  }

  use {
    'f-person/git-blame.nvim',
    cond = IsNotVsCode,
    config = function()
      vim.cmd "GitBlameDisable"
    end
  }

  use {
    'lewis6991/gitsigns.nvim',
    cond = IsNotVsCode,
    config = function()
      require('gitsigns').setup()

      vim.keymap.set('n', 'tg', function()
        require('gitsigns').next_hunk()
      end, {})

      vim.keymap.set('n', 'tG', function()
        require('gitsigns').prev_hunk()
      end, {})
    end,
  }

  use {
    'nvim-lualine/lualine.nvim',
    cond = IsNotVsCode,
    requires = {
      'nvim-tree/nvim-web-devicons',
      'SmiteshP/nvim-navic',
    },
    config = function()
      require('config.lualine')
    end,
  }

  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.2',
    requires = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-file-browser.nvim',
      'nvim-telescope/telescope-ui-select.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        run =
        'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
      },
    },
    cond = IsNotVsCode,
    config = function()
      require("config.telescope")
    end,
  }


  use {
    'nvim-tree/nvim-tree.lua',
    requires = 'nvim-tree/nvim-web-devicons',
    cond = IsNotVsCode,
    config = function()
      require("config.tree")
    end,
  }

  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    cond = IsNotVsCode,
    config = function()
      require("config.treesitter")
    end,
  }

  use {
    'kevinhwang91/nvim-ufo',
    requires = 'kevinhwang91/promise-async',
    cond = IsNotVsCode,
    config = function()
      require("config.ufo")
    end,
  }

  use {
    'VonHeikemen/lsp-zero.nvim',
    cond = IsNotVsCode,
    branch = 'v2.x',
    requires = {
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
  }

  use {
    'j-hui/fidget.nvim',
    tag = 'legacy',
    config = function()
      require("fidget").setup({
        window = { blend = 0 },
      })
    end,
  }

  use {
    'morhetz/gruvbox',
    cond = IsNotVsCode,
    config = function()
      require("config.colorscheme")
    end,
  }
end)
