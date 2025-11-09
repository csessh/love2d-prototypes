local Shape = require("shapes/shape")

local Circle = setmetatable({}, { __index = Shape })
Circle.__index = Circle

function Circle.new(x, y, radius, velocity_x, velocity_y)
  local instance = {
    type = "circle",
    x = x,
    y = y,
    radius = radius,
    velocity_x = velocity_x,
    velocity_y = velocity_y,
    is_colliding = false,
  }
  return setmetatable(instance, Circle)
end

function Circle:update(dt, screen_width, screen_height)
  Shape.update(self, dt, screen_width, screen_height)

  if self.x - self.radius < 0 or self.x + self.radius > screen_width then
    self.velocity_x = -self.velocity_x
  end
  if self.y - self.radius < 0 or self.y + self.radius > screen_height then
    self.velocity_y = -self.velocity_y
  end
end

function Circle:draw()
  local mode = self.is_colliding and "fill" or "line"
  love.graphics.circle(mode, self.x, self.y, self.radius)
end

return Circle
