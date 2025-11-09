local Shape = {}
Shape.__index = Shape

function Shape:update(dt, screen_width, screen_height)
  self.x = self.x + self.velocity_x * dt
  self.y = self.y + self.velocity_y * dt
end

function Shape:draw()
  error("Shape:draw() must be implemented by subclass")
end

function Shape:get_type()
  return self.type
end

return Shape
