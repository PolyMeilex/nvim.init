local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" } -- Unicode spinner frames

local function create_spinner()
  local S = {}

  S.count = 0
  S.current_frame = 1

  S.get_frame = function()
    S.current_frame = S.current_frame % #spinner_frames + 1
    return spinner_frames[S.current_frame]
  end

  S.label = function()
    if S.count > 1 then
      return S.get_frame() .. " (" .. S.count .. ")"
    elseif S.count > 0 then
      return S.get_frame()
    end
    return ""
  end

  return S
end

local spinner = create_spinner()

local M = {}
M.label = spinner.label

function M.print_requests()
  for _, client in ipairs(vim.lsp.get_clients()) do
    vim.print(client.name)
    for _, request in pairs(client.requests) do
      vim.print(request)
    end
  end
end

function M.list_requests()
  local count = 0
  for _, client in ipairs(vim.lsp.get_clients()) do
    if client.name == "stylua-lsp" then
      goto continue
    end

    if client.name == "json-bendec-ls" then
      goto continue
    end

    for _, request in pairs(client.requests) do
      if request.type ~= "cancel" and request.type ~= "complete" then
        count = count + 1
      end
    end

    ::continue::
  end

  return count
end

local skip_render = true
vim.fn.timer_start(500, function()
  spinner.count = M.list_requests()

  if spinner.count > 0 then
    skip_render = false
  end

  if not skip_render then
    vim.api.nvim_command("redrawstatus!")
  end

  if spinner.count == 0 then
    skip_render = true
  end
end, { ["repeat"] = -1 })

return M
