vim.lsp.config["plantuml-lsp"] = { cmd = { "plantuml-lsp" }, filetypes = { "plantuml" } }

vim.lsp.config("typos_lsp", { init_options = { diagnosticSeverity = "Hint" } })

vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      checkOnSave = true,
      check = { command = "clippy" },
      completion = { snippets = { custom = require("poly.rust").rust_snippets } },
    },
  },
  capabilities = {
    experimental = { commands = { commands = { "rust-analyzer.runSingle" } } },
  },
})

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
})
