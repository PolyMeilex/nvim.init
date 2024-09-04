local IsNotVsCode = require('vscode').IsNotVsCode()

local function config()
  local lsp_zero = require('lsp-zero')

  vim.api.nvim_create_user_command(
    "LspToggleInlayHints",
    function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
    end,
    {}
  )

  local lsp_attach = function(client, bufnr)
    if client.server_capabilities.documentSymbolProvider then
      require('nvim-navic').attach(client, bufnr)
    end

    require('lsp_signature').on_attach({}, bufnr)
    lsp_zero.default_keymaps({ buffer = bufnr })

    vim.keymap.set('n', 'gl', function()
      vim.diagnostic.open_float()
    end, { buffer = bufnr })
    vim.keymap.set('n', '[D', function()
      vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
    end, { buffer = bufnr })
    vim.keymap.set('n', ']D', function()
      vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
    end, { buffer = bufnr })
    vim.keymap.set('n', '[d', function()
      vim.diagnostic.goto_prev()
    end, { buffer = bufnr })
    vim.keymap.set('n', ']d', function()
      vim.diagnostic.goto_next()
    end, { buffer = bufnr })
  end

  lsp_zero.extend_lspconfig({
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
    lsp_attach = lsp_attach,
    float_border = 'rounded',
    sign_text = true,
  })

  lsp_zero.format_on_save({
    format_opts = {
      async = false,
      timeout_ms = 10000,
    },
    servers = {
      ['lua_ls'] = { 'lua' },
      ['rust_analyzer'] = { 'rust' },
      -- ['taplo'] = { 'toml' },
      ['blueprint_ls'] = { 'blueprint' },
      -- ['html'] = { 'html' },
      -- ['lemminx'] = { 'xml' },
    }
  })

  lsp_zero.set_server_config({
    capabilities = {
      textDocument = {
        foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true
        },
        inlayHints = true,
      }
    }
  })

  require('mason').setup({})
  require('mason-lspconfig').setup({
    ensure_installed = { 'rust_analyzer', 'taplo', 'lua_ls' },
    handlers = {
      lsp_zero.default_setup,
      lua_ls = function()
        local lua_opts = lsp_zero.nvim_lua_ls()
        require('lspconfig').lua_ls.setup(lua_opts)
      end,
      rust_analyzer = function()
        require('lspconfig').rust_analyzer.setup({
          settings = {
            ['rust-analyzer'] = {
              checkOnSave = {
                command = "clippy",
              },
            },
          },

        })
      end,
      -- Looks like it is unsupported?
      -- blueprint_ls = function()
      --   require('lspconfig').blueprint_ls.setup({})
      -- end,
    }
  })

  require('lspconfig').blueprint_ls.setup({})
  require('lspconfig').dartls.setup({})

  lsp_zero.setup()

  local cmp = require('cmp')

  cmp.setup {
    completion = {
      completeopt = "menu,menuone",
    },
    sources = {
      { name = 'nvim_lsp' },
      { name = 'buffer' },
      { name = 'async_path' },
      { name = 'crates' },
    },
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({}),
  }
end

return {
  {
    'VonHeikemen/lsp-zero.nvim',
    enabled = IsNotVsCode,
    branch = 'v4.x',
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
        opts = {}
      },
      "ray-x/lsp_signature.nvim",
    },
    config = config,
  },
  {
    "RRethy/vim-illuminate",
    config = function()
      local illuminate = require('illuminate')

      vim.keymap.set('n', 'gn', function()
        illuminate.goto_next_reference(true)
      end, {})
      vim.keymap.set('n', 'gN', function()
        illuminate.goto_prev_reference(true)
      end, {})

      illuminate.configure({
        min_count_to_highlight = 2,
      })
    end,
  },
  {
    'j-hui/fidget.nvim',
    enabled = IsNotVsCode,
    tag = 'v1.4.5',
    opts = {}
  },
}
