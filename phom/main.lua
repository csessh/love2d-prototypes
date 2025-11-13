local flux = require("libraries/flux")
local GameController = require("controllers/game_controller")
local InputController = require("controllers/input_controller")
local GameView = require("views/game_view")

local game_controller
local input_controller
local game_view

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  game_controller = GameController.new()
  input_controller = InputController.new(game_controller)
  game_view = GameView.new()
end

function love.update(dt)
  flux.update(dt)
  game_controller:update(dt)
  input_controller:update(dt)
end

function love.draw()
  game_view:draw(game_controller.game_state)
end

function love.mousepressed(x, y, button)
  input_controller:mousepressed(x, y, button)
end

function love.mousemoved(x, y)
  input_controller:mousemoved(x, y)
end
