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

    require('nvim-web-devicons').setup({
      override = {
        rs = {
          icon = "",
          color = "#f46623",
          cterm_color = "216",
          name = "Rs",
        },
      }
    })

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
      },
      source_selector = {
        winbar = true,
        sources = {
          { source = "filesystem" },
          { source = "diagnostics" },
        },
        truncation_character = "",
      },
      window = {
        mappings = {
          ["<Tab>"] = "next_source",
          ["<S-Tab>"] = "prev_source",
          ["<C-e>"] = "close_window",
        },
        width = 60,
      },
      filesystem = {
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        filtered_items = {
          hide_dotfiles = false,
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
          event = "neo_tree_window_after_open",
          handler = function(args)
            local winid = args.winid

            vim.wo[winid].signcolumn = 'no'

            local autocmd_id
            autocmd_id = vim.api.nvim_create_autocmd("WinLeave", {
              callback = function()
                if vim.api.nvim_get_current_win() == winid then
                  vim.api.nvim_del_autocmd(autocmd_id)
                  vim.cmd 'Neotree close'
                end
              end
            })
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
