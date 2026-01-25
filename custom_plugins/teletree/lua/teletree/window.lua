local M = {}

function M.init_window(bufnr)
  local P = {
    bufnr = bufnr,
  }

  ---@param width number
  ---@param height number
  P.open = function(row, col, width, height)
    local opts = {
      style = "minimal",
      relative = "editor",
      width = math.floor(width),
      height = math.floor(height),
      row = row,
      col = col,
      border = "rounded",
    }

    P.winid = vim.api.nvim_open_win(P.bufnr, true, opts)
    vim.wo[P.winid].cursorline = true
    vim.wo[P.winid].number = true
    vim.wo[P.winid].relativenumber = true
    vim.wo[P.winid].wrap = false

    -- vim.wo[P.winid].winhighlight = "Normal:Pmenu"

    if false then
      vim.api.nvim_create_autocmd("BufLeave", {
        buffer = P.bufnr,
        callback = function()
          P.close()
        end,
      })
    end
  end

  P.close = function()
    if P.winid ~= nil and vim.api.nvim_win_is_valid(P.winid) then
      vim.api.nvim_win_close(P.winid, true)
      P.winid = nil
    end
    -- if vim.api.nvim_buf_is_valid(P.bufnr) then
    --   vim.api.nvim_buf_delete(P.bufnr, { force = true })
    -- end
  end

  P.set_size = function(width, height)
    vim.api.nvim_win_set_config(P.winid, {
      width = width,
      height = height,
    })
  end

  return P
end

return M
