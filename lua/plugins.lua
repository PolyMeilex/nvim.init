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
    'ThePrimeagen/harpoon',
    enabled = IsNotVsCode,
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      vim.keymap.set("n", "<leader>a", function() harpoon:list():append() end)
      vim.keymap.set("n", "<leader>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

      vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
      vim.keymap.set("n", "<C-j>", function() harpoon:list():select(2) end)
      vim.keymap.set("n", "<C-k>", function() harpoon:list():select(3) end)
      vim.keymap.set("n", "<C-l>", function() harpoon:list():select(4) end)
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
    'tomasky/bookmarks.nvim',
    enabled = IsNotVsCode,
    config = function()
      local bm = require("bookmarks")
      bm.setup()

      vim.api.nvim_create_user_command("BookmarkToogle", bm.bookmark_toggle,
        { desc = "Add or remove bookmark at current line" })
      vim.api.nvim_create_user_command("BookmarkAnnotate", bm.bookmark_ann,
        { desc = "Add or edit mark annotation at current line" })

      vim.keymap.set('n', 'tm', function()
        require('telescope').extensions.bookmarks.list()
      end, {})
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    commit = 'b744cf59752aaa01561afb4223006de26f3836fd',
    -- tag = '0.1.5',
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
      "mrbjarksen/neo-tree-diagnostics.nvim",
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
    'poljar/typos.nvim',
    enabled = IsNotVsCode,
  },
  {
    'vxpm/ferris.nvim',
    enabled = IsNotVsCode,
    opts = {
      create_commands = true,
    },
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
