local Path = require("plenary.path")

---@class RailgunDbData
---@field projects table<string, RailgunDbProjectData>

---@class RailgunDbProjectData
---@field files table<string, RailgunDbTargetData[]>
---@field marks table<string>

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
  local out = setmetatable({
    config = config,
    path = Path:new(config.data_path .. "/default.json"),
    data = {
      projects = vim.empty_dict(),
    },
  }, self)

  out:load()

  return out
end

function M:load()
  if not self.path:exists() then
    self.path:touch({ parents = true })
    self:save()
  else
    local data = self.path:read()
    self.data = vim.json.decode(data)
  end
end

function M:save()
  self.path:write(vim.json.encode(self.data), "w")
end

---@param project_path? string
---@return RailgunDbProjectData?
function M:get_project(project_path)
  project_path = project_path or vim.loop.cwd()
  return self.data.projects[project_path]
end

---@param project_path string
---@param file_path string
---@param line integer
---@param col integer
---@param annotation string
function M:add(project_path, file_path, line, col, annotation)
  local project = self.data.projects[project_path] or {}

  local files = project.files or {}

  local relative_file = Path:new(file_path):make_relative(project_path)

  local file = files[relative_file] or {}

  table.insert(file, { line = line, col = col, annotation = annotation })

  files[relative_file] = file

  project.files = files
  self.data.projects[project_path] = project

  self:save()
end

---@param project_path string
---@param file_path string
function M:add_quick_mark(project_path, file_path)
  local project = self.data.projects[project_path] or {}

  local marks = project.marks or {}

  local relative_file = Path:new(file_path):make_relative(project_path)
  table.insert(marks, relative_file)

  project.marks = marks
  self.data.projects[project_path] = project

  self:save()
end

---@param project_path string
---@param file_path string
---@param line integer
---@param col integer
function M:remove(project_path, file_path, line, col)
  local project = self.data.projects[project_path] or {}
  local files = project.files or {}
  local file = files[file_path] or {}

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
