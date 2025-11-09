local Shape = require("shapes/shape")

local Rectangle = setmetatable({}, { __index = Shape })
Rectangle.__index = Rectangle

function Rectangle.new(x, y, width, height, velocity_x, velocity_y)
  local instance = {
    type = "rectangle",
    x = x,
    y = y,
    width = width,
    height = height,
    velocity_x = velocity_x,
    velocity_y = velocity_y,
    is_colliding = false,
  }
  return setmetatable(instance, Rectangle)
end

function Rectangle:update(dt, screen_width, screen_height)
  Shape.update(self, dt, screen_width, screen_height)

  if self.x < 0 or self.x + self.width > screen_width then
    self.velocity_x = -self.velocity_x
  end
  if self.y < 0 or self.y + self.height > screen_height then
    self.velocity_y = -self.velocity_y
  end
end

function Rectangle:draw()
  local mode = self.is_colliding and "fill" or "line"
  love.graphics.rectangle(mode, self.x, self.y, self.width, self.height)
end

return Rectangle
