vim.api.nvim_create_user_command("LspToggleInlayHints", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
end, {})

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP attach actions",
  callback = function(event)
    local bufnr = event.buf

    ---@type vim.lsp.Client|nil
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client == nil then
      return
    end

    local telescope = require("telescope.builtin")
    local opts = { buffer = bufnr }

    vim.keymap.set("n", "gd", telescope.lsp_definitions, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gi", telescope.lsp_implementations, opts)
    vim.keymap.set("n", "go", telescope.lsp_type_definitions, opts)
    vim.keymap.set("n", "gr", telescope.lsp_references, opts)

    vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action, opts)
  end,
})

return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {},
    run = function()
      pcall(vim.api.nvim_command, "MasonUpdate")
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- TODO: Try to merge in https://github.com/JohnnyMorganz/StyLua/pull/970 and add this to nvim lspconfig
      vim.lsp.config["stylua-lsp-rs"] = { cmd = { "stylua", "--lsp" }, filetypes = { "lua" } }
      vim.lsp.enable("stylua-lsp-rs")

      vim.lsp.config("typos_lsp", { init_options = { diagnosticSeverity = "Hint" } })
      vim.lsp.enable("typos_lsp")

      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            checkOnSave = true,
            check = { command = "clippy" },
            completion = { snippets = { custom = RustSnippets } },
          },
        },
        capabilities = {
          experimental = {
            commands = {
              commands = {
                "rust-analyzer.runSingle",
                -- "rust-analyzer.debugSingle",
                -- "rust-analyzer.gotoLocation",
                -- "rust-analyzer.showReferences",
              },
            },
          },
        },
      })
      vim.lsp.enable("rust_analyzer")

      vim.lsp.enable("yamlls")
      vim.lsp.enable("pyright")
      vim.lsp.enable("html")
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("clangd")
      vim.lsp.enable("ts_ls")
      vim.lsp.enable("taplo")
      vim.lsp.enable("dartls")
    end,
  },
}
