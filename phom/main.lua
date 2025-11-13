function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  print("Phom Card Game - Loading...")
end

function love.update(dt)
end

function love.draw()
  love.graphics.print("Phom Card Game", 10, 10)
end
