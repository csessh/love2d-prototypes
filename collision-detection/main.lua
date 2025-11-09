local Circle = require("shapes/circle")
local Rectangle = require("shapes/rectangle")
local Triangle = require("shapes/triangle")
local algo = require("libs/collision_detection")

local objects = {}
local screen_width
local screen_height

local function spawn_random_object()
  local choice = math.random()
  local obj

  if choice < 0.33 then
    obj = Rectangle.new(
      math.random(0, screen_width - 50),
      math.random(0, screen_height - 50),
      50,
      50,
      math.random(-100, 100),
      math.random(-100, 100)
    )
  elseif choice < 0.66 then
    local radius = 25
    obj = Circle.new(
      math.random(radius, screen_width - radius),
      math.random(radius, screen_height - radius),
      radius,
      math.random(-100, 100),
      math.random(-100, 100)
    )
  else
    local size = 50
    obj = Triangle.new(
      math.random(size, screen_width - size),
      math.random(size, screen_height - size),
      size,
      math.random(-100, 100),
      math.random(-100, 100)
    )
  end

  table.insert(objects, obj)
end

local function remove_random_object()
  if #objects > 0 then
    local index = math.random(1, #objects)
    table.remove(objects, index)
  end
end

function love.load()
  screen_width = love.graphics.getWidth()
  screen_height = love.graphics.getHeight()

  math.randomseed(os.time())

  for _ = 1, 5 do
    spawn_random_object()
  end
end

function love.keypressed(key)
  if key == "=" or key == "+" then
    spawn_random_object()
  elseif key == "-" then
    remove_random_object()
  elseif key == "x" then
    love.event.quit(0)
  end
end

function love.update(dt)
  for i = 1, #objects do
    objects[i]:update(dt, screen_width, screen_height)
  end

  for i = 1, #objects do
    objects[i].is_colliding = false
  end

  for i = 1, #objects do
    for j = i + 1, #objects do
      if algo.detect_collision(objects[i], objects[j]) then
        objects[i].is_colliding = true
        objects[j].is_colliding = true
      end
    end
  end
end

function love.draw()
  for i = 1, #objects do
    objects[i]:draw()
  end

  love.graphics.print("Objects: " .. #objects, 10, 10)
  love.graphics.print("Press '+' to add, '-' to remove, 'x' to quit", 10, 30)
end
