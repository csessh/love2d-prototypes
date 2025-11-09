local anim8 = require("libraries/anim8")
local player = {}

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  player.speed = 5
  player.sprite = love.graphics.newImage("sprites/player-sheet.png")
  player.x = 400
  player.y = 300

  player.grid =
    anim8.newGrid(12, 18, player.sprite:getWidth(), player.sprite:getHeight())

  local animation_speed = 0.3
  player.animations = {}
  player.animations.down =
    anim8.newAnimation(player.grid("1-4", 1), animation_speed)
  player.animations.left =
    anim8.newAnimation(player.grid("1-4", 2), animation_speed)
  player.animations.right =
    anim8.newAnimation(player.grid("1-4", 3), animation_speed)
  player.animations.up =
    anim8.newAnimation(player.grid("1-4", 4), animation_speed)
  player.direction = player.animations.left
end

function love.update(dt)
  if love.keyboard.isDown("l") then
    player.direction = player.animations.right
    player.x = player.x + player.speed
  end

  if love.keyboard.isDown("h") then
    player.direction = player.animations.left
    player.x = player.x - player.speed
  end

  if love.keyboard.isDown("k") then
    player.direction = player.animations.up
    player.y = player.y - player.speed
  end

  if love.keyboard.isDown("j") then
    player.direction = player.animations.down
    player.y = player.y + player.speed
  end

  player.direction:update(dt)
end

function love.draw()
  player.direction:draw(player.sprite, player.x, player.y, nil, 10)
end
