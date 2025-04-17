local IsNotVsCode = require("vscode").IsNotVsCode()

return {
  dir = "~/.config/nvim/fmt",
  enabled = IsNotVsCode,
  --- @type fmt.setup.Opts
  opts = {
    formatters = {
      rust = {
        on_save = true,
      },
      lua = {
        -- TODO: Try to merge in https://github.com/JohnnyMorganz/StyLua/pull/970 and add this to nvim lspconfig
        lsp_name = "stylua-lsp-rs", -- Prefer stylua over lua_ls
        on_save = true,
      },
      -- lua = {
      --   lsp_name = "stylua-lsp", -- Prefer stylua over lua_ls
      --   on_save = true,
      --   startup = function(buffer)
      --     require("fmt.stylua").start(buffer)
      --   end,
      -- },
    },
    on_attach = function(buffer, format)
      local opts = { buffer = buffer }

      vim.keymap.set("n", "<F3>", function()
        format({ async = true })
      end, opts)
      vim.keymap.set("x", "<F3>", function()
        format({ async = true })
      end, opts)
    end,
  },
}
