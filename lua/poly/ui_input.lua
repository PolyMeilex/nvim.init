local function try_typos_lsp_launch(buffer)
  local client = vim.lsp.get_clients({ name = "typos_lsp" })[1]

  if client == nil then
    return
  end

  vim.lsp.buf_attach_client(buffer, client.id)
end

---@diagnostic disable-next-line: duplicate-set-field
vim.ui.input = function(opts, on_confirm)
  vim.validate({
    opts = { opts, "table", true },
    on_confirm = { on_confirm, "function", false },
  })

  opts = opts or {}

  local prompt = opts.prompt or "Input: "
  local default = opts.default or ""

  -- Calculate a minimal width with a bit buffer
  local default_width = vim.str_utfindex(default, "utf-8") + 20
  local prompt_width = vim.str_utfindex(prompt, "utf-8") + 20
  local input_width = default_width > prompt_width and default_width or prompt_width

  local win_config = {
    focusable = true,
    style = "minimal",
    border = "rounded",
    width = input_width,
    height = 1,
    title = prompt,
  }

  -- Place the window near cursor or at the center of the window.
  if prompt == "New Name: " then
    win_config.relative = "cursor"
    win_config.row = 1
    win_config.col = 0
  else
    win_config.relative = "win"
    win_config.row = vim.api.nvim_win_get_height(0) / 2 - 1
    win_config.col = vim.api.nvim_win_get_width(0) / 2 - win_config.width / 2
  end

  -- Create floating window.
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buffer })
  vim.api.nvim_set_option_value("filetype", "my.ui.input", { buf = buffer })
  vim.api.nvim_buf_set_name(buffer, "my.ui.input")

  try_typos_lsp_launch(buffer)

  local window = vim.api.nvim_open_win(buffer, true, win_config)
  vim.api.nvim_buf_set_text(buffer, 0, 0, 0, 0, { default })

  -- Put cursor at the end of the default value
  vim.cmd("startinsert")
  vim.api.nvim_win_set_cursor(window, { 1, vim.str_utfindex(default, "utf-8") + 1 })

  local close = function()
    vim.cmd("stopinsert")

    if vim.api.nvim_win_is_valid(window) then
      vim.api.nvim_win_close(window, true)
    end

    if vim.api.nvim_buf_is_valid(buffer) then
      vim.api.nvim_buf_delete(buffer, { force = true })
    end
  end

  local confirm = function()
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, 1, false)
    close()
    on_confirm(lines[1])
  end

  local cancel = function()
    close()
    on_confirm(nil)
  end

  vim.api.nvim_create_autocmd({ "BufWriteCmd" }, {
    buffer = buffer,
    callback = confirm,
  })

  vim.keymap.set({ "n", "i", "v" }, "<cr>", confirm, { buffer = buffer })
  vim.keymap.set("n", "<esc>", cancel, { buffer = buffer })
  vim.keymap.set("n", "q", cancel, { buffer = buffer })
end
