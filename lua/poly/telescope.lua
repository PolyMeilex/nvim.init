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

local function symbols_in_selection()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local sorters = require("telescope.sorters")
  local previewers = require("telescope.previewers")
  local make_entry = require("telescope.make_entry")

  local function get_visual_range()
    local _, ls = unpack(vim.fn.getpos("'<"))
    local _, le = unpack(vim.fn.getpos("'>"))
    if ls > le then
      ls, le = le, ls
    end
    return ls - 1, le - 1
  end

  local opts = {}
  local lmin, lmax = get_visual_range()

  vim.lsp.buf.document_symbol({
    on_list = function(result)
      local filtered = vim.tbl_filter(function(s)
        return s.lnum >= lmin and s.lnum <= lmax
      end, result.items)

      pickers
        .new(opts, {
          prompt_title = "Symbols in Selection",
          finder = finders.new_table({
            results = filtered,
            entry_maker = make_entry.gen_from_lsp_symbols({ path_display = "hidden" }),
          }),
          previewer = previewers.vim_buffer_qflist.new(opts),
          sorter = sorters.get_generic_fuzzy_sorter(),
          push_cursor_on_edit = true,
          push_tagstack_on_edit = true,
        })
        :find()
    end,
  })
end

local M = {}

function M.setup()
  local telescope = require("telescope")
  local builtin = require("telescope.builtin")
  local actions = require("telescope.actions")

  vim.keymap.set("n", "tng", builtin.find_files, {})
  vim.keymap.set("n", "tg", project_files, {})
  vim.keymap.set("n", "tc", builtin.commands, {})
  vim.keymap.set("n", "tf", builtin.current_buffer_fuzzy_find, {})
  vim.keymap.set("n", "tF", builtin.live_grep, {})
  vim.keymap.set("n", "to", function()
    builtin.oldfiles({ only_cwd = true })
  end, {})
  vim.keymap.set("n", "tb", builtin.buffers, {})

  function _G._symbols_in_selection()
    symbols_in_selection()
  end

  vim.keymap.set("v", "tt", ":<C-u>lua _symbols_in_selection()<CR>", { silent = true })
  vim.keymap.set("n", "tt", builtin.lsp_document_symbols, {})

  vim.keymap.set("n", "tl", function()
    builtin.builtin({ default_text = "lsp_", use_default_opts = true })
  end, {})
  vim.keymap.set("n", "td", function()
    builtin.diagnostics({ severity_limit = "WARN", severity_bound = "ERROR" })
  end, {})
  vim.keymap.set("n", "tD", function()
    builtin.diagnostics({ severity_limit = "ERROR", severity_bound = "ERROR" })
  end, {})
  vim.keymap.set("n", "<C-p>", telescope.extensions.omni_picker.omni_picker, {})
  vim.keymap.set("n", "tp", telescope.extensions.lsp_code_context.list, {})
  vim.keymap.set("n", "tj", builtin.jumplist, {})
  vim.keymap.set("n", "tw", builtin.lsp_dynamic_workspace_symbols, {})
  vim.keymap.set("n", "th", function()
    require("poly.git-hunks-picker").pick()
  end, {})
  vim.keymap.set("n", "tm", function()
    require("telescope").extensions.railgun.list()
  end, {})

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
        on_input_filter_cb = function(prompt)
          if vim.startswith(prompt, "./") then
            return { prompt = string.sub(prompt, 3) }
          end
          return prompt
        end,
      },
      jumplist = {
        sort_lastused = true,
        mappings = {
          n = {
            ["<c-c>"] = function(prompt_bufnr)
              actions.close(prompt_bufnr)
              vim.cmd("clearjumps")
            end,
          },
          i = {
            ["<c-c>"] = function(prompt_bufnr)
              actions.close(prompt_bufnr)
              vim.cmd("clearjumps")
            end,
          },
        },
      },
    },

    defaults = {
      mappings = {
        i = {
          ["<C-Down>"] = actions.cycle_history_next,
          ["<C-Up>"] = actions.cycle_history_prev,
        },
      },
    },

    extensions = {
      ["ui-select"] = {
        require("telescope.themes").get_dropdown(),
      },
    },
  })
  telescope.load_extension("ui-select")
  telescope.load_extension("fzf")
  telescope.load_extension("railgun")
  telescope.load_extension("omni_picker")
end

return M
