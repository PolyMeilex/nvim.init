local IsNotVsCode = require("vscode").IsNotVsCode()

local function lsp_capabilities()
  return vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    require("cmp_nvim_lsp").default_capabilities(),
    {
      textDocument = {
        foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true,
        },
        codeLens = {
          dynamicRegistration = true,
        },
      },
      experimental = {
        commands = {
          commands = {
            "rust-analyzer.runSingle",
            -- "rust-analyzer.debugSingle",
            -- "rust-analyzer.gotoLocation",
            "rust-analyzer.showReferences",
          },
        },
      },
    }
  )
end

return {
  {
    "folke/lazydev.nvim",
    enabled = IsNotVsCode,
    ft = "lua",
    opts = {},
  },
  {
    "neovim/nvim-lspconfig",
    enabled = IsNotVsCode,
    config = function()
      vim.diagnostic.config({
        virtual_text = {
          severity = vim.diagnostic.severity.ERROR,
        },
        -- virtual_lines = {
        --   current_line = true,
        -- },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = "󰌵",
          },
        },
      })

      vim.api.nvim_create_user_command("LspToggleInlayHints", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
      end, {})

      require("lspconfig").dartls.setup({ capabilities = lsp_capabilities() })

      -- TODO: Try to merge in https://github.com/JohnnyMorganz/StyLua/pull/970 and add this to nvim lspconfig
      vim.lsp.config["stylua-lsp-rs"] = {
        cmd = { "stylua", "--lsp" },
        filetypes = { "lua" },
      }
      vim.lsp.enable("stylua-lsp-rs")

      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "LSP attach actions",
        callback = function(event)
          local bufnr = event.buf
          local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

          ---@type vim.lsp.Client|nil
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client == nil then
            return
          end

          local telescope = require("telescope.builtin")
          local opts = { buffer = bufnr }

          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gd", telescope.lsp_definitions, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gi", telescope.lsp_implementations, opts)
          vim.keymap.set("n", "go", telescope.lsp_type_definitions, opts)
          vim.keymap.set("n", "gr", telescope.lsp_references, opts)

          vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action, opts)

          vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
          vim.keymap.set("n", "[D", function()
            vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
          end, opts)
          vim.keymap.set("n", "]D", function()
            vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
          end, opts)
        end,
      })
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      { "hrsh7th/cmp-path" },
      { "hrsh7th/cmp-nvim-lsp-signature-help" },
      { "hrsh7th/cmp-nvim-lsp" },
    },
    config = function()
      local cmp = require("cmp")

      local kind_icons = {
        Text = "",
        Method = "󰆧",
        Function = "󰊕",
        Constructor = "",
        Field = "󰇽",
        Variable = "󰂡",
        Class = "󰠱",
        Interface = "",
        Module = "",
        Property = "󰜢",
        Unit = "",
        Value = "󰎠",
        Enum = "",
        Keyword = "󰌋",
        Snippet = "",
        Color = "󰏘",
        File = "󰈙",
        Reference = "",
        Folder = "󰉋",
        EnumMember = "",
        Constant = "󰏿",
        Struct = "",
        Event = "",
        Operator = "󰆕",
        TypeParameter = "󰅲",
      }

      cmp.setup({
        formatting = {
          expandable_indicator = true,
          fields = { "abbr", "kind", "menu" },
          format = function(entry, vim_item)
            vim_item.kind = string.format("%s %s", kind_icons[vim_item.kind], vim_item.kind) -- This concatenates the icons with the name of the item kind

            if entry.source.name == "async_path" then
              vim_item.menu = "path"
            elseif entry.source.name == "nvim_lsp" then
              vim_item.menu = ""
            else
              vim_item.menu = entry.source.name
            end

            return vim_item
          end,
        },
        completion = {
          completeopt = "menu,menuone",
        },
        sources = {
          { name = "nvim_lsp_signature_help" },
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        },
        mapping = cmp.mapping.preset.insert({}),
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = {},
        run = function()
          pcall(vim.api.nvim_command, "MasonUpdate")
        end,
      },
    },
    opts = {
      ensure_installed = { "rust_analyzer", "taplo", "lua_ls" },
      handlers = {
        function(server_name)
          -- TODO: Remove once mason is updated
          if server_name == "tsserver" then
            server_name = "ts_ls"
          end

          require("lspconfig")[server_name].setup({ capabilities = lsp_capabilities() })
        end,
        jsonls = function()
          require("lspconfig").jsonls.setup({
            capabilities = lsp_capabilities(),
            on_attach = function(client)
              -- Disable symbol provider, so bendec-lsp can take over
              client.server_capabilities.documentSymbolProvider = false
            end,
          })
        end,
        rust_analyzer = function()
          require("lspconfig").rust_analyzer.setup({
            capabilities = lsp_capabilities(),
            on_attach = function(client, bufnr)
              -- Remove once https://github.com/neovim/neovim/pull/32999 is merged
              client.server_capabilities.inlayHintProvider = false
            end,
            settings = {
              ["rust-analyzer"] = {
                checkOnSave = {
                  command = "clippy",
                },
                lens = {
                  enable = true,
                  implementations = { enable = true },
                  references = {
                    adt = { enable = true },
                    trait = { enable = true },
                  },
                  run = { enable = true },
                },
              },
            },
          })
        end,
        typos_lsp = function()
          require("lspconfig").typos_lsp.setup({
            init_options = {
              diagnosticSeverity = "Hint",
            },
          })
        end,
      },
    },
  },
}
