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
end)

lsp.format_on_save({
  format_opts = {
    async = false,
    timeout_ms = 10000,
  },
  servers = {
    ['lua_ls'] = { 'lua' },
    ['rust_analyzer'] = { 'rust' },
    ['taplo'] = { 'toml' },
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

require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())
require('lspconfig').blueprint_ls.setup({})

lsp.setup()
