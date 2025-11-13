local flux = require("libraries/flux")
local GameController = require("controllers/game_controller")
local GameView = require("views/game_view")

local game_controller
local game_view

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  game_controller = GameController.new()
  game_view = GameView.new()
end

function love.update(dt)
  flux.update(dt)
  game_controller:update(dt)
end

function love.draw()
  game_view:draw(game_controller.game_state)
end
