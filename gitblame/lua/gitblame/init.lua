local namespace_id = vim.api.nvim_create_namespace("gitblame")
local group = vim.api.nvim_create_augroup("gitblame", { clear = true })

local M = {}

---@param line string
---@param key string
local function get_value_with_key(line, key)
  if vim.startswith(line, key) then
    return line:sub(#key + 1)
  end

  return nil
end

---@param delta_sec integer
local function format_time_ago(delta_sec)
  local delta_min = math.floor(delta_sec / 60)
  local delta_h = math.floor(delta_min / 60)
  local delta_days = math.floor(delta_h / 24)
  local delta_weeks = math.floor(delta_days / 7)
  local delta_months = math.floor(delta_days / 30)
  local delta_years = math.floor(delta_days / 365)

  if delta_min < 60 then
    return delta_min .. " minutes ago"
  elseif delta_h < 24 then
    return delta_h .. " hours ago"
  elseif delta_days < 7 then
    return delta_days .. " days ago"
  elseif delta_days < 30 then
    return delta_weeks .. " weeks ago"
  elseif delta_days < 365 then
    return delta_months .. " months ago"
  else
    return delta_years .. " years ago"
  end
end

M.run = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]

  local filepath = vim.api.nvim_buf_get_name(bufnr)

  vim.system({ "git", "blame", filepath, "-bwp", "-L " .. line_num .. ",+1" }, { text = true }, function(out)
    if out.code ~= 0 then
      return
    end

    local author = nil
    local smummary = nil
    local time = nil

    for _, line in ipairs(vim.split(out.stdout, "\n")) do
      author = author or get_value_with_key(line, "author ")
      smummary = smummary or get_value_with_key(line, "summary ")
      time = time or get_value_with_key(line, "committer-time ")
    end

    local delta = "?"
    if time ~= nil then
      time = tonumber(time)

      if time ~= nil then
        local now = os.time()
        local delta_sec = os.difftime(now, time)
        delta = format_time_ago(delta_sec)
      end
    end

    local text = author .. ", " .. delta .. ": " .. smummary

    local virt_text = {
      { text, "Comment" },
    }

    vim.schedule(function()
      vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
      vim.api.nvim_buf_set_extmark(bufnr, namespace_id, line_num - 1, 0, {
        virt_text_pos = "eol_right_align",
        virt_text = virt_text,
      })
    end)
  end)
end

M.register_autocmd = function()
  vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
      M.run()
    end,
    group = group,
  })
end

M.setup = function()
  vim.o.updatetime = 500
end

M.on = false

M.toggle = function()
  vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)
  vim.api.nvim_clear_autocmds({ group = group })

  if M.on then
    M.on = false
  else
    M.on = true
    M.run()
    M.register_autocmd()
  end
end

return M
