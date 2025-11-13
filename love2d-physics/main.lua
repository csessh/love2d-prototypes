local screen = {
  x = 500,
  y = 500,
}
local color = {
  blue = { 0.23, 0.25, 0.59, 1 },
  purple = { 0.25, 0.09, 0.28, 1 },
  white = { 0.89, 0.91, 0.90, 1 },
}

local physics = {
  normals = {},
}

-- Source: https://www.love2d.org/forums/viewtopic.php?p=17018&sid=5c8509cf6b97e3ce5aab1bc49e85acc5#p17018
local function draw_arrow(x1, y1, x2, y2)
  local head_length = 10
  local head_angle = math.pi * 0.2
  love.graphics.line(x1, y1, x2, y2)
  local a = math.atan2(y1 - y2, x1 - x2)
  love.graphics.polygon(
    "fill",
    x2,
    y2,
    x2 + head_length * math.cos(a + head_angle),
    y2 + head_length * math.sin(a + head_angle),
    x2 + head_length * math.cos(a - head_angle),
    y2 + head_length * math.sin(a - head_angle)
  )
end

function physics.collisionOnEnter(fixture_a, fixture_b, contact)
  local dx, dy = contact:getNormal()
  dx = dx * 30
  dy = dy * 30
  local point = { contact:getPositions() }
  for i = 1, #point, 2 do
    local x, y = point[i], point[i + 1]
    -- Cache the values inside the contacts because they're not guaranteed
    -- to be valid later in the frame.
    table.insert(physics.normals, { x, y, x + dx, y + dy })
  end

  -- do not use contact after this function returns
end

function love.load()
  love.physics.setMeter(64)
  local can_bodies_sleep = true
  physics.world = love.physics.newWorld(0, 9.8, can_bodies_sleep)
  physics.world:setCallbacks(physics.collisionOnEnter)

  physics.geo = {}
  for y = 0, 1 do
    local side = {}
    side.body = love.physics.newBody(physics.world, screen.x / 2, screen.y * y)
    side.shape = love.physics.newRectangleShape(screen.x, 50)
    side.fixture = love.physics.newFixture(side.body, side.shape)
    table.insert(physics.geo, side)
  end
  for x = 0, 1 do
    local side = {}
    side.body = love.physics.newBody(physics.world, screen.x * x, screen.y / 2)
    side.shape = love.physics.newRectangleShape(50, screen.y)
    side.fixture = love.physics.newFixture(side.body, side.shape)
    table.insert(physics.geo, side)
  end

  physics.bouncers = {}
  for y = 50, screen.y - 50, 50 do
    for x = 50, screen.x - 100, 50 do
      local ball = {}
      ball.body = love.physics.newBody(physics.world, x, y, "dynamic")
      ball.shape = love.physics.newCircleShape(20)
      ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1)
      ball.fixture:setRestitution(0.9)
      ball.body:setMass(50)
      ball.body:setLinearVelocity(100, 10)
      table.insert(physics.bouncers, ball)
    end
  end

  love.graphics.setBackgroundColor(color.blue)
  love.window.setMode(screen.x, screen.y)
end

function love.update(dt)
  -- Updating the world will trigger collisionOnEnter
  physics.world:update(dt)

  if love.keyboard.isDown("space") then
    for _, ball in ipairs(physics.bouncers) do
      ball.body:applyLinearImpulse(0, 1000)
    end
  elseif love.keyboard.isDown("escape") then
    love.event.quit()
  end
end

function love.draw()
  love.graphics.setColor(color.purple)
  for i, side in ipairs(physics.geo) do
    love.graphics.polygon(
      "fill",
      side.body:getWorldPoints(side.shape:getPoints())
    )
  end
  for i, ball in ipairs(physics.bouncers) do
    love.graphics.circle(
      "fill",
      ball.body:getX(),
      ball.body:getY(),
      ball.shape:getRadius()
    )
  end

  love.graphics.setColor(color.white)
  love.graphics.printf("smoosh balls with space", 5, 5, 200, "left")
  love.graphics.printf(
    string.format("%i contacts", #physics.normals),
    screen.x - 100,
    5,
    100,
    "right"
  )
  love.graphics.printf(
    "arrows show contact normals",
    5,
    screen.y - 20,
    200,
    "left"
  )

  -- Use our cached normals
  for key, args in pairs(physics.normals) do
    local x1, y1, x2, y2 = unpack(args)
    draw_arrow(x1, y1, x2, y2)
    physics.normals[key] = nil
  end
end
