local function string_contains(str, substr)
  return string.find(str, substr, 1, true) ~= nil
end

local function does_line_have_lens(line)
  local namespaces = vim.api.nvim_get_namespaces()

  for ns_name, ns_id in pairs(namespaces) do
    if string_contains(ns_name, "vim_lsp_codelens:") then
      local extmarks = vim.api.nvim_buf_get_extmarks(0, ns_id, { line, 0 }, { line, -1 }, {})

      if #extmarks ~= 0 then
        return true
      end
    end
  end

  return false
end

local function get_line_length(bufnr, line)
  local line_content = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ""
  return #line_content
end

local function _is_lens_clicked()
  local mouse = vim.fn.getmousepos()
  local winid = mouse.winid
  local mouse_winrow = mouse.winrow - 1
  local mouse_wincol = mouse.wincol - 1

  if winid == 0 then
    return nil
  end

  local buf = vim.api.nvim_win_get_buf(winid)
  local win_info = vim.fn.getwininfo(winid)[1]
  local topline = win_info.topline
  local wincol = win_info.wincol

  local line = mouse_winrow + topline
  local col = mouse_wincol - win_info.textoff

  if win_info.winbar then
    line = line - 1
    -- TODO: Handle 0 line
  end

  local line_len = get_line_length(buf, line)

  if does_line_have_lens(line - 1) then
    if col > line_len then
      return true
    end
  end

  return false
end

vim.api.nvim_create_autocmd({ "CursorHold", "InsertLeave" }, {
  desc = "LSP attach actions",
  callback = function()
    vim.lsp.codelens.refresh()
  end,
})

vim.cmd([[
      aunmenu PopUp
      anoremenu PopUp.Inspect                 <Cmd>Inspect<CR>
      anoremenu PopUp.Lens <Cmd>lua vim.lsp.codelens.run()<CR>
]])

local nvim_popupmenu_augroup = vim.api.nvim_create_augroup("nvim_popupmenu", { clear = true })
vim.api.nvim_create_autocmd("MenuPopup", {
  pattern = "*",
  group = nvim_popupmenu_augroup,
  desc = "Mouse popup menu",
  callback = function()
    local cursor = vim.api.nvim_win_get_cursor(0)

    if does_line_have_lens(cursor[1] - 1) then
      vim.cmd([[
        anoremenu enable PopUp.Lens
      ]])
    else
      vim.cmd([[
        anoremenu disable PopUp.Lens
      ]])
    end
  end,
})

return {}