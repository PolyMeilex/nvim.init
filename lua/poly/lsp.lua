vim.lsp.config["plantuml-lsp"] = { cmd = { "plantuml-lsp" }, filetypes = { "plantuml" } }

vim.lsp.config("typos_lsp", { init_options = { diagnosticSeverity = "Hint" } })

vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = true,
      check = { command = "clippy" },
    },
  },
  capabilities = {
    experimental = { commands = { commands = { "rust-analyzer.runSingle" } } },
  },
})

--- @type vim.lsp.Config
local jsonls_config = {
  on_attach = function(client, _buf)
    client.server_capabilities.hoverProvider = nil
    client.server_capabilities.definitionProvider = nil
    client.server_capabilities.declarationProvider = nil
    client.server_capabilities.typeDefinitionProvider = nil
    client.server_capabilities.implementationProvider = nil
    client.server_capabilities.referencesProvider = nil
    client.server_capabilities.documentSymbolProvider = nil
    client.server_capabilities.workspaceSymbolProvider = nil
    -- client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = nil
    client.server_capabilities.renameProvider = nil
    client.server_capabilities.codeActionProvider = nil
    client.server_capabilities.signatureHelpProvider = nil
    client.server_capabilities.documentHighlightProvider = nil
    client.server_capabilities.inlayHintProvider = nil
    client.server_capabilities.semanticTokensProvider = nil
    client.server_capabilities.foldingRangeProvider = nil
    -- Leave completionProvider enabled  end,
  end,
}
vim.lsp.config("jsonls", jsonls_config)

vim.lsp.enable({
  "plantuml-lsp",
  "stylua",
  "typos_lsp",
  "rust_analyzer",
  "yamlls",
  "pyright",
  "html",
  "lua_ls",
  "clangd",
  "ts_ls",
  "taplo",
  "dartls",
  "kotlin_lsp",
  "gdscript",
  "jsonls",
})
