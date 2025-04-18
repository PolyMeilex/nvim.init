local IsNotVsCode = require("vscode").IsNotVsCode()

vim.lsp.commands["rust-analyzer.runSingle"] = function(command)
  local args = command.arguments[1].args

  local handle
  handle = vim.loop.spawn("kgx", {
    args = {
      "--tab",
      "-e",
      "fish",
      "-C",
      "cargo " .. table.concat(args.cargoArgs, " "),
    },
    stdio = { nil, nil, nil },
    function()
      handle:close()
    end,
  })
end

vim.lsp.commands["rust-analyzer.showReferences"] = function(command)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local make_entry = require("telescope.make_entry")

  local locations = command.arguments[3]
  local title = command.title

  pickers
    .new({}, {
      prompt_title = title,
      finder = finders.new_table({
        results = vim.lsp.util.locations_to_items(locations, "utf-8"),
        entry_maker = make_entry.gen_from_quickfix({}),
      }),
      previewer = conf.qflist_previewer({}),
      sorter = conf.generic_sorter({}),
      push_cursor_on_edit = true,
      push_tagstack_on_edit = true,
    })
    :find()
end

return {
  {
    "saecki/crates.nvim",
    enabled = IsNotVsCode,
    ft = "toml",
    -- tag = 'stable',
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local crates = require("crates")
      crates.setup({
        lsp = {
          enabled = true,
          completion = true,
          hover = true,
          actions = true,
        },
      })

      vim.keymap.set("n", "<leader>cv", function()
        crates.show_versions_popup()
        crates.focus_popup()
      end, {})
      vim.keymap.set("n", "<leader>cf", function()
        crates.show_features_popup()
        crates.focus_popup()
      end, {})
    end,
  },
  {
    "vxpm/ferris.nvim",
    enabled = IsNotVsCode,
    ft = "rust",
    opts = {
      create_commands = true,
    },
  },
}
