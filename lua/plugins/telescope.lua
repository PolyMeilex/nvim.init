local IsNotVsCode = require("vscode").IsNotVsCode()

-- We cache the results of "git rev-parse"
local is_inside_work_tree = {}

local function project_files()
  local opts = {}

  local cwd = vim.fn.getcwd()
  if is_inside_work_tree[cwd] == nil then
    vim.fn.system("git rev-parse --is-inside-work-tree")
    is_inside_work_tree[cwd] = vim.v.shell_error == 0
  end

  if is_inside_work_tree[cwd] then
    require("telescope.builtin").git_files(opts)
  else
    require("telescope.builtin").find_files(opts)
  end
end

return {
  "nvim-telescope/telescope.nvim",
  commit = "85922dde3767e01d42a08e750a773effbffaea3e",
  -- tag = '0.1.6',
  enabled = IsNotVsCode,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    "nvim-telescope/telescope-ui-select.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
    },
  },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local select_dir_for_search = function()
      telescope.extensions.file_browser.file_browser({
        files = false,
        depth = false,
        attach_mappings = function()
          actions.select_default:replace(function()
            local entry_path = action_state.get_selected_entry().Path
            local dir = entry_path:is_dir() and entry_path or entry_path:parent()
            local relative = dir:make_relative(vim.fn.getcwd())
            local absolute = dir:absolute()

            builtin.find_files({
              prompt_title = relative .. "/",
              search_dirs = { absolute },
            })
          end)

          return true
        end,
      })
    end

    vim.keymap.set("n", "tpf", builtin.find_files, {})
    vim.keymap.set("n", "<C-p>", project_files, {})
    vim.keymap.set("n", "tc", builtin.commands, {})
    vim.keymap.set("n", "tf", builtin.current_buffer_fuzzy_find, {})
    vim.keymap.set("n", "tF", builtin.live_grep, {})
    vim.keymap.set("n", "to", function()
      builtin.oldfiles({ only_cwd = true })
    end, {})
    vim.keymap.set("n", "tb", builtin.buffers, {})

    vim.keymap.set("n", "tt", builtin.lsp_document_symbols, {})
    vim.keymap.set("n", "tl", function()
      builtin.builtin({ default_text = "lsp_", use_default_opts = true })
    end, {})
    vim.keymap.set("n", "td", function()
      builtin.diagnostics({ severity_bound = "ERROR" })
    end, {})
    vim.keymap.set("n", "tD", function()
      builtin.diagnostics({ severity_limit = "ERROR", severity_bound = "ERROR" })
    end, {})
    vim.keymap.set("n", "ts", select_dir_for_search, {})

    telescope.setup({
      pickers = {
        buffers = {
          sort_lastused = true,
          mappings = {
            n = {
              ["<c-d>"] = actions.delete_buffer,
            },
            i = {
              ["<c-d>"] = actions.delete_buffer,
            },
          },
        },
        git_files = {
          show_untracked = true,
        },
      },

      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
      },
    })
    telescope.load_extension("file_browser")
    telescope.load_extension("ui-select")
    telescope.load_extension("fzf")
    telescope.load_extension("railgun")

    -- open file_browser with the path of the current buffer
    vim.api.nvim_set_keymap(
      "n",
      "<leader>fb",
      ":Telescope file_browser path=%:p:h select_buffer=true<CR>",
      { noremap = true }
    )
  end,
}
