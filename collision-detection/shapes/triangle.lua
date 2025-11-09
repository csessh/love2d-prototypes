local Shape = require("shapes/shape")

local Triangle = setmetatable({}, { __index = Shape })
Triangle.__index = Triangle

function Triangle.new(center_x, center_y, size, velocity_x, velocity_y)
  local instance = {
    type = "triangle",
    x = center_x,
    y = center_y,
    vertices = {
      center_x,
      center_y - size / 2,
      center_x - size / 2,
      center_y + size / 2,
      center_x + size / 2,
      center_y + size / 2,
    },
    velocity_x = velocity_x,
    velocity_y = velocity_y,
    is_colliding = false,
  }
  return setmetatable(instance, Triangle)
end

function Triangle:update(dt, screen_width, screen_height)
  local delta_x = self.velocity_x * dt
  local delta_y = self.velocity_y * dt

  self.x = self.x + delta_x
  self.y = self.y + delta_y

  for i = 1, #self.vertices, 2 do
    self.vertices[i] = self.vertices[i] + delta_x
    self.vertices[i + 1] = self.vertices[i + 1] + delta_y
  end

  local min_x, max_x = math.huge, -math.huge
  local min_y, max_y = math.huge, -math.huge
  for i = 1, #self.vertices, 2 do
    min_x = math.min(min_x, self.vertices[i])
    max_x = math.max(max_x, self.vertices[i])
    min_y = math.min(min_y, self.vertices[i + 1])
    max_y = math.max(max_y, self.vertices[i + 1])
  end

  if min_x < 0 or max_x > screen_width then
    self.velocity_x = -self.velocity_x
  end
  if min_y < 0 or max_y > screen_height then
    self.velocity_y = -self.velocity_y
  end
end

function Triangle:draw()
  local mode = self.is_colliding and "fill" or "line"
  love.graphics.polygon(mode, self.vertices)
end

return Triangle
