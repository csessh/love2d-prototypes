local flux = require("libraries/flux")
local GameState = require("models/game_state")
local GameView = require("views/game_view")

local game_state
local game_view

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  game_state = GameState.new()
  game_state:dealCards(9)

  game_view = GameView.new()
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  game_view:draw(game_state)
end
