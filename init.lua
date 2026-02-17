vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.undofile = true
vim.o.signcolumn = "yes"

vim.o.foldcolumn = "0"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldtext = ""
vim.o.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.termguicolors = true
vim.o.number = true
vim.o.rnu = true
vim.o.tabstop = 4
vim.o.gdefault = true

vim.g.mapleader = " "
vim.g.camelcasemotion_key = "<leader>"

vim.opt.clipboard = vim.opt.clipboard + "unnamedplus"

require("poly.lazy_init")
require("poly.black-hole").setup()
require("poly.inside").setup()
require("poly.ui_input")
require("poly.completion").setup()
require("poly.statusline").setup()
require("poly.telescope").setup()
require("poly.treesitter")
require("poly.lsp")
require("poly.code_lens")
require("poly.word_highlight")

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.cmd(":tnoremap <C-q> <C-\\><C-n>")

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank({ higroup = "YankIncSearch" })
  end,
})

vim.keymap.set("n", "<leader>cv", function()
  local crates = require("crates")
  crates.show_versions_popup()
  crates.focus_popup()
end)
vim.keymap.set("n", "<leader>cf", function()
  local crates = require("crates")
  crates.show_features_popup()
  crates.focus_popup()
end)

vim.keymap.set("n", "<C-e>", function()
  require("teletree").open()
end)
vim.keymap.set("n", "<C-s>", function()
  require("teletree.symbols").open()
end)

do
  local telescope = require("telescope")
  local builtin = require("telescope.builtin")
  local my = require("poly.telescope")

  vim.keymap.set("n", "gd", builtin.lsp_definitions)
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration)
  vim.keymap.set("n", "gi", builtin.lsp_incoming_calls)
  vim.keymap.set("n", "gI", builtin.lsp_implementations)
  vim.keymap.set("n", "go", builtin.lsp_type_definitions)
  vim.keymap.set("n", "gr", builtin.lsp_references)

  vim.keymap.set("n", "<F2>", vim.lsp.buf.rename)
  vim.keymap.set("n", "<F4>", vim.lsp.buf.code_action)

  vim.keymap.set("n", "tng", builtin.find_files)
  vim.keymap.set("n", "tg", my.project_files)
  vim.keymap.set("n", "tc", builtin.commands)
  vim.keymap.set("n", "tf", builtin.current_buffer_fuzzy_find)
  vim.keymap.set("n", "tF", builtin.live_grep)
  vim.keymap.set("n", "to", function()
    builtin.oldfiles({ only_cwd = true })
  end)
  vim.keymap.set("n", "tb", builtin.buffers)

  vim.keymap.set("v", "tt", my.lsp_document_symbols_in_selection, { silent = true })
  vim.keymap.set("n", "tt", builtin.lsp_document_symbols)

  vim.keymap.set("n", "tl", function()
    builtin.builtin({ default_text = "lsp_", use_default_opts = true })
  end)
  vim.keymap.set("n", "td", function()
    builtin.diagnostics({ severity_limit = "WARN", severity_bound = "ERROR" })
  end)
  vim.keymap.set("n", "tD", function()
    builtin.diagnostics({ severity_limit = "ERROR", severity_bound = "ERROR" })
  end)
  vim.keymap.set("n", "<C-p>", telescope.extensions.omni_picker.omni_picker)
  vim.keymap.set("n", "tp", telescope.extensions.lsp_code_context.list)
  vim.keymap.set("n", "tj", builtin.jumplist)
  vim.keymap.set("n", "tw", builtin.lsp_dynamic_workspace_symbols)
  vim.keymap.set("n", "th", require("poly.git-hunks-picker").pick)
  vim.keymap.set("n", "tm", telescope.extensions.railgun.list)
end

do
  vim.diagnostic.config({
    virtual_text = {
      severity = vim.diagnostic.severity.ERROR,
    },
    signs = { text = require("poly.icons").diagnostic_signs },
  })

  --- @param opts vim.diagnostic.JumpOpts
  local function jump_cb(opts)
    return function()
      vim.diagnostic.jump(opts)
    end
  end

  local bracketed = require("poly.bracketed")

  vim.keymap.set("n", "gl", vim.diagnostic.open_float)
  vim.keymap.set("n", "[d", jump_cb({ count = -1, severity = { min = vim.diagnostic.severity.WARN } }))
  vim.keymap.set("n", "]d", jump_cb({ count = 1, severity = { min = vim.diagnostic.severity.WARN } }))
  vim.keymap.set("n", "[D", jump_cb({ count = -1, severity = { min = vim.diagnostic.severity.ERROR } }))
  vim.keymap.set("n", "]D", jump_cb({ count = 1, severity = { min = vim.diagnostic.severity.ERROR } }))

  vim.keymap.set("n", "]q", ":cn<CR>", { silent = true })
  vim.keymap.set("n", "[q", ":cp<CR>", { silent = true })

  vim.keymap.set("n", "[p", bracketed.goto_parent, { expr = true })
  vim.keymap.set("n", "[s", bracketed.prev_sibling, { expr = true })
  vim.keymap.set("n", "]s", bracketed.next_sibling, { expr = true })
end

-- harpoon
do
  local function select_cb(index)
    return function()
      require("harpoon"):list():select(index)
    end
  end

  vim.keymap.set("n", "<leader>a", function()
    require("harpoon"):list():add()
  end)
  vim.keymap.set("n", "<leader>h", function()
    local harpoon = require("harpoon")
    harpoon.ui:toggle_quick_menu(harpoon:list())
  end)
  vim.keymap.set("n", "<C-h>", select_cb(1))
  vim.keymap.set("n", "<C-j>", select_cb(2))
  vim.keymap.set("n", "<C-k>", select_cb(3))
  vim.keymap.set("n", "<C-l>", select_cb(4))
  vim.keymap.set("n", "<C-;>", select_cb(5))
end

vim.api.nvim_create_user_command("MiniDiffToggleOverlay", function()
  require("mini.diff").toggle_overlay(0)
end, {})

vim.api.nvim_create_user_command("LspToggleInlayHints", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
end, {})
