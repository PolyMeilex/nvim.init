local M = {}

local function run_process(cmd, opts)
  local args = opts.args
  local write_cb = opts.write
  local callback = opts.done

  local stdin = vim.loop.new_pipe(false)
  local stdout = vim.loop.new_pipe(false)
  local handle

  local output = {}

  handle = vim.loop.spawn(cmd, {
    args = args,
    stdio = { stdin, stdout, nil },
  }, function(code)
    stdout:close()
    handle:close()

    vim.schedule(function()
      callback(code, table.concat(output))
    end)
  end)

  if not handle then
    stdin:close()
    stdout:close()
    vim.notify("typos-cli Error", vim.log.levels.ERROR)
    return
  end

  vim.loop.read_start(stdout, function(err, data)
    assert(not err, err)
    if data then
      table.insert(output, data)
    end
  end)

  write_cb(stdin)
end

local function write_buffer_to_stdin(buffer, stdin)
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, true)

  for _, line in ipairs(lines) do
    stdin:write(line .. "\n")
  end

  stdin:shutdown(function()
    stdin:close()
  end)
end

function M.run_for_buffer(buffer, done)
  run_process("typos", {
    args = { "-", "--format", "json" },
    write = function(stdin)
      write_buffer_to_stdin(buffer, stdin)
    end,
    done = function(_code, out)
      local lines = vim.split(out, "\n", {
        plain = true,
        trimempty = true,
      })
      local results = vim.tbl_map(vim.json.decode, lines)

      done(results)
    end,
  })
end

return M
