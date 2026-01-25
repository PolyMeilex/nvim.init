local M = {}

M.rust_snippets = {
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

return M
