local lsp = require('lsp-zero').preset('recommended')

lsp.ensure_installed({
  'rust_analyzer',
})

lsp.on_attach(function(client, bufnr)
  if client.server_capabilities.inlayHintProvider then
    vim.lsp.inlay_hint(bufnr, true)
  end

  if client.server_capabilities.documentSymbolProvider then
    require('nvim-navic').attach(client, bufnr)
  end

  require('lsp_signature').on_attach({}, bufnr)
  lsp.default_keymaps({ buffer = bufnr })

  vim.keymap.set('n', '[d', function()
    vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
  end, { buffer = bufnr })
  vim.keymap.set('n', ']d', function()
    vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
  end, { buffer = bufnr })
end)

lsp.format_on_save({
  format_opts = {
    async = false,
    timeout_ms = 10000,
  },
  servers = {
    ['lua_ls'] = { 'lua' },
    ['rust_analyzer'] = { 'rust' },
    -- ['taplo'] = { 'toml' },
    ['blueprint_ls'] = { 'blueprint' },
    -- ['lemminx'] = { 'xml' },
  }
})

lsp.set_server_config({
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

require('lspconfig').rust_analyzer.setup({
  settings = {
    ['rust-analyzer'] = {
      checkOnSave = {
        command = "clippy",
      },
    },
  },

})
require('lspconfig').blueprint_ls.setup({})

lsp.setup()

local cmp = require('cmp')
cmp.setup {
  completion = {
    completeopt = "menu,menuone",
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'async_path' },
  },
}

require('illuminate').configure({
  min_count_to_highlight = 2,
})
