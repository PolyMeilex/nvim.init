---@param names string[]
local function load_custom_plugins(names)
  for _, name in pairs(names) do
    vim.opt.rtp:prepend("~/.config/nvim/custom_plugins/" .. name)
  end
end

load_custom_plugins({
  "renui",
  "yaml_utils",
  "json_utils",
  "lsp-code-context",
  "rs-derive-menu",
  "railgun",
  "rust-targets",
  "path-lsp",
  "gitblame",
  "ferris",
  "omni_picker",
  "teletree",
  "fmt",
  "venn",
})

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind

    if kind == "install" or kind == "update" then
      if name == "nvim-treesitter" then
        vim.cmd.packadd(name)
        vim.cmd("TSUpdate")
      elseif name == "telescope-fzf-native.nvim" then
        vim.print("Compiling fzf")
        local path = ev.data.path
        vim.system({ "cmake", "-S.", "-Bbuild", "-DCMAKE_BUILD_TYPE=Release" }, { cwd = path }):wait()
        vim.system({ "cmake", "--build", "build", "--config", "Release" }, { cwd = path }):wait()
        vim.system({ "cmake", "--install", "build", "--prefix", "build" }, { cwd = path }):wait()
      end
    end
  end,
})

local function gh(name)
  return "https://github.com/" .. name
end

vim.pack.add({
  -- Deps
  gh("nvim-lua/plenary.nvim"),
  -- Plugins
  gh("bkad/CamelCaseMotion"),
  gh("wakatime/vim-wakatime"),
  gh("neovim/nvim-lspconfig"),
  gh("nvim-telescope/telescope.nvim"),
  gh("nvim-telescope/telescope-ui-select.nvim"),
  gh("nvim-telescope/telescope-fzf-native.nvim"),

  { src = gh("ThePrimeagen/harpoon"), version = "harpoon2" },
  gh("williamboman/mason.nvim"),
  gh("echasnovski/mini.surround"),
  gh("echasnovski/mini.diff"),
  gh("nvim-tree/nvim-web-devicons"),

  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },

  gh("folke/lazydev.nvim"),
  gh("saecki/crates.nvim"),
  gh("ellisonleao/gruvbox.nvim"),
}, { load = true })

require("yaml_utils").setup()
require("json_utils").setup()
require("lsp-code-context").setup()
require("rs-derive-menu").setup()
require("railgun").setup()
require("rust-targets").setup()
require("path-lsp").setup()
require("gitblame").setup()
require("ferris").setup()
require("teletree").setup()
require("mason").setup({})

require("mini.surround").setup({ n_lines = 1000 })

require("mini.diff").setup({
  view = { style = "sign", priority = 0 },
  options = { wrap_goto = true },
})

require("nvim-web-devicons").setup({
  override = {
    rs = {
      icon = "",
      color = "#f46623",
      cterm_color = "216",
      name = "Rs",
    },
  },
})

require("lazydev").setup({
  library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
})

require("crates").setup({
  lsp = {
    enabled = true,
    completion = true,
    hover = true,
    actions = true,
  },
})

require("fmt").setup({
  formatters = {
    rust = { on_save = true },
    lua = { lsp_name = "stylua", on_save = true },
  },
  on_attach = function(buffer, format)
    vim.keymap.set("n", "<F3>", function()
      format({ async = true })
    end)
    vim.keymap.set("x", "<F3>", function()
      format({ async = true })
    end)
  end,
})

require("gruvbox").setup({
  -- transparent_mode = true,
  terminal_colors = false,
  overrides = {
    PmenuSel = { fg = "NONE", bg = "#4d4d4d" },
    Pmenu = { fg = "NONE", bg = "#2e2e2e" },
    LspReferenceText = { bold = true },
    LspReferenceRead = { bold = true },
    LspReferenceWrite = { bold = true },
    TelescopeResultsBorder = { link = "FloatBorder" },
    TelescopePromptBorder = { link = "FloatBorder" },
    TelescopePreviewBorder = { link = "FloatBorder" },
    FloatBorder = { bg = "#1f1f1f", fg = "#4e433a" },
    NormalFloat = { link = "Normal" },
    WinSeparator = { bg = "#1f1f1f", fg = "#322d29" },
    YankIncSearch = { bg = "#544C45", fg = "NONE", reverse = false, bold = true },
    SignColumn = { link = "Normal" },

    WinBar = { link = "Normal" },
    WinBarNC = { link = "NormalNC" },

    StatusLine = { link = "Normal" },
    StatusLineNC = { link = "NormalNC" },

    Normal = { bg = "#1f1f1f" },
    NormalNC = { bg = "#1c1c1c" },

    LspInlayHint = { bg = "#36302c", fg = "#878787" },
    NeoTreeDirectoryIcon = { link = "GruvboxGreenBold" },
    NeoTreeDirectoryName = { link = "GruvboxGreenBold" },
  },
})

vim.cmd.colorscheme("gruvbox")

do
  -- venn.nvim: enable or disable keymappings
  function _G.Toggle_venn()
    local venn_enabled = vim.inspect(vim.b.venn_enabled)
    if venn_enabled == "nil" then
      vim.b.venn_enabled = true
      vim.cmd([[setlocal ve=all]])
      -- draw a line on HJKL keystokes
      vim.api.nvim_buf_set_keymap(0, "n", "J", "<C-v>j:VBox<CR>", { noremap = true })
      vim.api.nvim_buf_set_keymap(0, "n", "K", "<C-v>k:VBox<CR>", { noremap = true })
      vim.api.nvim_buf_set_keymap(0, "n", "L", "<C-v>l:VBox<CR>", { noremap = true })
      vim.api.nvim_buf_set_keymap(0, "n", "H", "<C-v>h:VBox<CR>", { noremap = true })
      -- draw a box by pressing "f" with visual selection
      vim.api.nvim_buf_set_keymap(0, "v", "f", ":VBoxO<CR>", { noremap = true })
    else
      vim.cmd([[setlocal ve=]])
      vim.api.nvim_buf_del_keymap(0, "n", "J")
      vim.api.nvim_buf_del_keymap(0, "n", "K")
      vim.api.nvim_buf_del_keymap(0, "n", "L")
      vim.api.nvim_buf_del_keymap(0, "n", "H")
      vim.api.nvim_buf_del_keymap(0, "v", "f")

      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.b.venn_enabled = nil
    end
  end
  -- toggle keymappings for venn using <leader>v
  vim.api.nvim_set_keymap("n", "<leader>v", ":lua Toggle_venn()<CR>", { noremap = true })
end
