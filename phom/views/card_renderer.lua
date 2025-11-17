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
  instance:loadCardImages()
  return instance
end

function CardRenderer:loadCardImages()
  -- Load individual card images
  -- File naming pattern: card_<suit>_<face_value>.png
  -- Suits: hearts, diamonds, clubs, spades (lowercase)
  -- Face values: A, 02-10 (zero-padded), J, Q, K (uppercase)

  -- Map rank numbers to file face values
  local rank_to_file = {
    [1] = "A",
    [2] = "02",
    [3] = "03",
    [4] = "04",
    [5] = "05",
    [6] = "06",
    [7] = "07",
    [8] = "08",
    [9] = "09",
    [10] = "10",
    [11] = "J",
    [12] = "Q",
    [13] = "K",
  }

  for _, suit in ipairs(Constants.SUITS) do
    self.card_images[suit] = {}

    for rank = 1, 13 do
      local face_value = rank_to_file[rank]
      local filename =
        string.format("assets/sprites/cards/card_%s_%s.png", suit, face_value)
      self.card_images[suit][rank] = love.graphics.newImage(filename)
    end
  end

  self.card_back = love.graphics.newImage("assets/sprites/cards/card_back.png")
end

function CardRenderer:drawCard(card, x, y, rotation, scale, face_up)
  rotation = rotation or 0
  scale = scale or 1
  face_up = face_up == nil and true or face_up

  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)
  love.graphics.scale(scale, scale)

  if face_up then
    self:drawFaceUp(card)
  else
    self:drawFaceDown()
  end

  love.graphics.pop()
end

function CardRenderer:drawFaceUp(card)
  love.graphics.setColor(1, 1, 1)
  local image = self.card_images[card.suit][card.rank]
  love.graphics.draw(image, -self.card_width / 2, -self.card_height / 2)
end

function CardRenderer:drawFaceDown()
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(
    self.card_back,
    -self.card_width / 2,
    -self.card_height / 2
  )
end

return CardRenderer
