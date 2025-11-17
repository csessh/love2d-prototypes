local GameController = require("controllers/game_controller")
local GameView = require("views/game_view")
local InputController = require("controllers/input_controller")
local Flux = require("libraries/flux")

local game_controller
local input_controller
local game_view

function love.load()
  -- Initialize random seed once at startup for better randomness
  math.randomseed(os.time() + math.floor(love.timer.getTime() * 1000))

  love.graphics.setDefaultFilter("nearest", "nearest")

  game_controller = GameController.new()
  input_controller = InputController.new(game_controller)
  game_view = GameView.new()
end

function love.update(dt)
  game_controller:update(dt)
  input_controller:update(dt)
end

function love.draw()
  local animation_state = game_controller:getAnimationState()
  game_view:draw(game_controller.game_state, animation_state)
end

function love.mousepressed(x, y, button)
  input_controller:mousepressed(x, y, button)
end

function love.mousemoved(x, y)
  input_controller:mousemoved(x, y)
end
