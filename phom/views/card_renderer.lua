local Constants = require("utils/constants")

local CardRenderer = {}

function CardRenderer.new()
  local instance = {
    card_width = Constants.CARD_WIDTH,
    card_height = Constants.CARD_HEIGHT,
    card_images = {},
    card_back = nil,
  }
  setmetatable(instance, { __index = CardRenderer })
  instance:load_card_images()
  return instance
end

function CardRenderer:load_card_images()
  -- Load individual card images
  -- File naming pattern: card_<suit>_<face_value>.png
  -- Suits: hearts, diamonds, clubs, spades (lowercase)
  -- Face values: A, 02-10 (zero-padded), J, Q, K (uppercase)
  -- Load all 52 card images
  for _, suit in ipairs(Constants.SUITS) do
    self.card_images[suit] = {}

    for rank = 1, 13 do
      local face_value = Constants.RANK_NAMES[rank]
      local filename =
        string.format("assets/sprites/cards/card_%s_%s.png", suit, face_value)
      self.card_images[suit][rank] = love.graphics.newImage(filename)
    end
  end

  self.card_back = love.graphics.newImage("assets/sprites/cards/card_back.png")
end

function CardRenderer:draw_card(card, x, y, rotation, scale)
  rotation = rotation or 0
  scale = scale or 1

  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)
  love.graphics.scale(scale, scale)

  if card.face_up then
    self:draw_face_up(card)
  else
    self:draw_face_down()
  end

  love.graphics.pop()
end

function CardRenderer:draw_face_up(card)
  love.graphics.setColor(1, 1, 1)
  local image = self.card_images[card.suit][card.rank]
  love.graphics.draw(image, -self.card_width / 2, -self.card_height / 2)
end

function CardRenderer:draw_face_down()
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(
    self.card_back,
    -self.card_width / 2,
    -self.card_height / 2
  )
end

return CardRenderer
