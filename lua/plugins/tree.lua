local IsNotVsCode = require('vscode').IsNotVsCode()

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  enabled = IsNotVsCode,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    "mrbjarksen/neo-tree-diagnostics.nvim",
  },
  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    vim.fn.sign_define("DiagnosticSignError",
      { text = " ", texthl = "DiagnosticSignError" })
    vim.fn.sign_define("DiagnosticSignWarn",
      { text = " ", texthl = "DiagnosticSignWarn" })
    vim.fn.sign_define("DiagnosticSignInfo",
      { text = " ", texthl = "DiagnosticSignInfo" })
    vim.fn.sign_define("DiagnosticSignHint",
      { text = "󰌵", texthl = "DiagnosticSignHint" })

    require("neo-tree").setup({
      close_if_last_window = true,
      sources = {
        "buffers",
        "document_symbols",
        "filesystem",
        "diagnostics",
        "harpoon",
      },
      -- source_selector = {
      --   winbar = true,
      --   sources = {
      --     { source = "filesystem" },
      --   },
      --   truncation_character = "",
      -- },
      window = {
        mappings = {
          ["<Tab>"] = "next_source",
          ["<S-Tab>"] = "prev_source",
          ["<C-e>"] = "close_window",
        },
      },
      filesystem = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        window = {
          mappings = {
            ["<S-f>"] = function(state)
              local node = state.tree:get_node();
              if node.type == "directory" then
                require('telescope.builtin').live_grep({ cwd = node.path })
              end
            end,
            ["<C-f>"] = function(state)
              local node = state.tree:get_node();
              if node.type == "directory" then
                require('telescope.builtin').find_files({ cwd = node.path })
              end
            end,
          },
        },
      },
      document_symbols = {
        follow_cursor = true,
      },
      event_handlers = {
        {
          event = "neo_tree_buffer_leave",
          handler = function()
            vim.cmd 'Neotree close'
          end
        },
      }
    })

    vim.keymap.set('n', '<C-e>', function()
      require('neo-tree.command').execute({
        action = "focus",
        source = "last",
      })
    end, {})
  end,
}
