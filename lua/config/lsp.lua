local lsp_zero = require('lsp-zero')

vim.api.nvim_create_user_command(
  "LspToggleInlayHints",
  function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
  end,
  {}
)

lsp_zero.on_attach(function(client, bufnr)
  if client.server_capabilities.documentSymbolProvider then
    require('nvim-navic').attach(client, bufnr)
  end

  require('lsp_signature').on_attach({}, bufnr)
  lsp_zero.default_keymaps({ buffer = bufnr })

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
end)

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
}

require('illuminate').configure({
  min_count_to_highlight = 2,
})
