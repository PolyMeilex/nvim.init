local IsNotVsCode = require("vscode").IsNotVsCode()

RustSnippets = {
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
  ["Err"] = {
    postfix = "err",
    body = "Err(${receiver})",
    description = "Wrap the expression in a `Result::Err`",
    scope = "expr",
  },
  ["Some"] = {
    postfix = "some",
    body = "Some(${receiver})",
    description = "Wrap the expression in an `Option::Some`",
    scope = "expr",
  },
  ["Arc::new"] = {
    postfix = "arc",
    body = "Arc::new(${receiver})",
    requires = "std::sync::Arc",
    description = "Put the expression into an `Arc`",
    scope = "expr",
  },
  ["Rc::new"] = {
    postfix = "rc",
    body = "Rc::new(${receiver})",
    requires = "std::rc::Rc",
    description = "Put the expression into an `Rc`",
    scope = "expr",
  },
}

vim.lsp.commands["rust-analyzer.runSingle"] = function(command)
  local args = command.arguments[1].args
  require("kgx").in_new_tab("cargo " .. table.concat(args.cargoArgs, " "))
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
    dir = "~/.config/nvim/ferris",
    enabled = IsNotVsCode,
    ft = "rust",
    opts = {
      create_commands = true,
    },
  },
}
