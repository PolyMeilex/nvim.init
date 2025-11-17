local Path = require("plenary.path")

---@class RailgunDbData
---@field project RailgunDbProjectData

---@class RailgunDbProjectData
---@field bookmarks table<string, RailgunDbTargetData[]>
---@field marks table<string, RailgunDbTargetData[]>

---@class RailgunDbTargetData
---@field annotation? string
---@field line integer
---@field col integer

---@class RailgunDb
---@field config RailgunConfig
---@field data RailgunDbData
---@field path Path
local M = {}
M.__index = M

---@param config RailgunConfig
---@return RailgunDb
function M:new(config)
  local cwd = vim.loop.cwd()
  local escaped_cwd = cwd:gsub("/", "@")

  local out = setmetatable({
    config = config,
    path = Path:new(config.data_path .. "/" .. escaped_cwd .. ".json"),
    dirty = false,
    data = {
      cwd = cwd,
      project = vim.empty_dict(),
    },
  }, self)

  out:load()

  return out
end

function M:load()
  if not self.path:exists() then
    self:save()
  else
    local data = self.path:read()
    self.data = vim.json.decode(data)
  end
end

function M:save()
  if self.dirty then
    self.path:touch({ parents = true })
    self.path:write(vim.json.encode(self.data), "w")
  end
  self.dirty = false
end

---@param project_path? string
---@return RailgunDbProjectData?
function M:get_project(project_path)
  project_path = project_path or vim.loop.cwd()
  return self.data.project
end

---@param project_path string
---@param file_path string
---@param line integer
---@param col integer
---@param annotation string
function M:add(project_path, file_path, line, col, annotation)
  self.dirty = true
  local project = self.data.project or {}

  local bookmarks = project.bookmarks or {}

  local relative_file = Path:new(file_path):make_relative(project_path)

  local file = bookmarks[relative_file] or {}

  table.insert(file, { line = line, col = col, annotation = annotation })

  bookmarks[relative_file] = file

  project.bookmarks = bookmarks
  self.data.project = project

  self:save()
end

---@param project_path string
---@param file_path string
function M:add_quick_mark(project_path, file_path, line, col, annotation)
  self.dirty = true
  local project = self.data.project or {}

  local marks = project.marks or {}

  local relative_file = Path:new(file_path):make_relative(project_path)

  local file = marks[relative_file] or {}

  table.insert(file, { line = line, col = col, annotation = annotation })

  marks[relative_file] = file

  project.marks = marks
  self.data.project = project

  self:save()
end

---@param project_path string
---@param file_path string
---@param line integer
---@param col integer
function M:remove(project_path, file_path, line, col)
  self.dirty = true
  local project = self.data.project or {}
  local bookmarks = project.bookmarks or {}
  local file = bookmarks[file_path] or {}

  local pos = nil

  for id, target in pairs(file) do
    if target.line == line and target.col == col then
      pos = id
      break
    end
  end

  if pos ~= nil then
    table.remove(file, pos)
  end

  self:save()
end

return M
