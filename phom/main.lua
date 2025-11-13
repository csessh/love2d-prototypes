local flux = require("libraries/flux")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  print("Phom Card Game - Loading...")
  print("Flux loaded:", flux ~= nil)
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.print("Phom Card Game", 10, 10)
end
