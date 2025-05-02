local IsNotVsCode = require("vscode").IsNotVsCode()

local function lsp_capabilities()
  return vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    require("mini.completion").get_lsp_capabilities(),
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
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "echasnovski/mini.completion",
    dependencies = { "echasnovski/mini.icons" },
    opts = {
      delay = { completion = 150, info = 100, signature = 50 },
      window = {
        info = { border = "single" },
        signature = { border = "none" },
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
    enabled = IsNotVsCode,
    config = function()
      local lspconfig = require("lspconfig")

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

          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gd", telescope.lsp_definitions, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gi", telescope.lsp_implementations, opts)
          vim.keymap.set("n", "go", telescope.lsp_type_definitions, opts)
          vim.keymap.set("n", "gr", telescope.lsp_references, opts)

          vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action, opts)

          vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)
          vim.keymap.set("n", "[d", function()
            vim.diagnostic.jump({ count = -1, severity = { min = vim.diagnostic.severity.WARN } })
          end, opts)
          vim.keymap.set("n", "]d", function()
            vim.diagnostic.jump({ count = 1, severity = { min = vim.diagnostic.severity.WARN } })
          end, opts)
          vim.keymap.set("n", "[D", function()
            vim.diagnostic.jump({ count = -1, severity = { min = vim.diagnostic.severity.ERROR } })
          end, opts)
          vim.keymap.set("n", "]D", function()
            vim.diagnostic.jump({ count = 1, severity = { min = vim.diagnostic.severity.ERROR } })
          end, opts)
        end,
      })

      -- TODO: Try to merge in https://github.com/JohnnyMorganz/StyLua/pull/970 and add this to nvim lspconfig
      vim.lsp.config["stylua-lsp-rs"] = {
        cmd = { "stylua", "--lsp" },
        filetypes = { "lua" },
      }
      vim.lsp.enable("stylua-lsp-rs")

      for _, server_name in pairs({ "yamlls", "pyright", "html", "lua_ls", "clangd", "ts_ls", "taplo", "dartls" }) do
        lspconfig[server_name].setup({ capabilities = lsp_capabilities() })
      end

      lspconfig.typos_lsp.setup({
        capabilities = lsp_capabilities(),
        init_options = {
          diagnosticSeverity = "Hint",
        },
      })
      lspconfig.rust_analyzer.setup({
        capabilities = lsp_capabilities(),
        settings = {
          ["rust-analyzer"] = {
            checkOnSave = true,
            check = {
              command = "clippy",
            },
            completion = {
              snippets = {
                custom = {
                  rccell = {
                    postfix = "rccell",
                    body = "Rc::new(RefCell::new(${receiver}))",
                    requires = { "std::rc::Rc", "std::cell::RefCell" },
                    description = "Put the expression into an `Rc`",
                    scope = "expr",
                  },
                  ["RefCell::new"] = {
                    postfix = "refcell",
                    body = "RefCell::new(${receiver})",
                    requires = "std::cell::RefCell",
                    description = "Put the expression into an `RefCell`",
                    scope = "expr",
                  },
                  -- Defaults (not sure why I can't add my snippets without overriding defaults)
                  ["Ok"] = {
                    postfix = "ok",
                    body = "Ok(${receiver})",
                    description = "Wrap the expression in a `Result::Ok`",
                    scope = "expr",
                  },
                  ["Box::pin"] = {
                    postfix = "pinbox",
                    body = "Box::pin(${receiver})",
                    requires = "std::boxed::Box",
                    description = "Put the expression into a pinned `Box`",
                    scope = "expr",
                  },
                  ["Arc::new"] = {
                    postfix = "arc",
                    body = "Arc::new(${receiver})",
                    requires = "std::sync::Arc",
                    description = "Put the expression into an `Arc`",
                    scope = "expr",
                  },
                  ["Some"] = {
                    postfix = "some",
                    body = "Some(${receiver})",
                    description = "Wrap the expression in an `Option::Some`",
                    scope = "expr",
                  },
                  ["Err"] = {
                    postfix = "err",
                    body = "Err(${receiver})",
                    description = "Wrap the expression in a `Result::Err`",
                    scope = "expr",
                  },
                  ["Rc::new"] = {
                    postfix = "rc",
                    body = "Rc::new(${receiver})",
                    requires = "std::rc::Rc",
                    description = "Put the expression into an `Rc`",
                    scope = "expr",
                  },
                },
              },
            },
            -- lens = {
            --   enable = true,
            --   implementations = { enable = true },
            --   references = {
            --     adt = { enable = true },
            --     trait = { enable = true },
            --   },
            --   run = { enable = true },
            -- },
          },
        },
      })
    end,
  },
}
