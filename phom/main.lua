local flux = require("libraries/flux")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  print("Phỏm Card Game - Loading...")
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.print("Phỏm Card Game", 10, 10)
end
