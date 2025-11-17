local Constants = require("utils/constants")

local LayoutCalculator = {}

-- Calculate positions for all cards in a player's hand
-- Returns: table mapping card.id -> {x, y, rotation, index}
function LayoutCalculator.calculateHandPositions(player, card_scale)
  card_scale = card_scale or 1
  local positions = {}

  if player.position == Constants.POSITIONS.BOTTOM then
    positions = LayoutCalculator.calculateBottomHandPositions(player.hand, card_scale)
  elseif player.position == Constants.POSITIONS.LEFT then
    positions = LayoutCalculator.calculateLeftHandPositions(player.hand, card_scale)
  elseif player.position == Constants.POSITIONS.TOP then
    positions = LayoutCalculator.calculateTopHandPositions(player.hand, card_scale)
  elseif player.position == Constants.POSITIONS.RIGHT then
    positions = LayoutCalculator.calculateRightHandPositions(player.hand, card_scale)
  end

  return positions
end

function LayoutCalculator.calculateBottomHandPositions(hand, card_scale)
  local center_x = Constants.SCREEN_WIDTH / 2
  local center_y = Constants.SCREEN_HEIGHT - 70
  local card_spacing = Constants.CARD_WIDTH * card_scale - 5
  local total_width = (#hand - 1) * card_spacing
  local start_x = center_x - total_width / 2

  local positions = {}
  for i, card in ipairs(hand) do
    positions[card.id] = {
      x = start_x + (i - 1) * card_spacing,
      y = center_y,
      rotation = 0,
      index = i
    }
  end

  return positions
end

function LayoutCalculator.calculateLeftHandPositions(hand, card_scale)
  local x = 150
  local center_y = Constants.SCREEN_HEIGHT / 2
  local card_spacing = Constants.CARD_WIDTH * card_scale - 5
  local total_height = (#hand - 1) * card_spacing
  local start_y = center_y - total_height / 2

  local positions = {}
  for i, card in ipairs(hand) do
    positions[card.id] = {
      x = x,
      y = start_y + (i - 1) * card_spacing,
      rotation = math.pi / 2,
      index = i
    }
  end

  return positions
end

function LayoutCalculator.calculateTopHandPositions(hand, card_scale)
  local center_x = Constants.SCREEN_WIDTH / 2
  local y = 120
  local card_spacing = Constants.CARD_WIDTH * card_scale - 5
  local total_width = (#hand - 1) * card_spacing
  local start_x = center_x - total_width / 2

  local positions = {}
  for i, card in ipairs(hand) do
    positions[card.id] = {
      x = start_x + (i - 1) * card_spacing,
      y = y,
      rotation = 0,
      index = i
    }
  end

  return positions
end

function LayoutCalculator.calculateRightHandPositions(hand, card_scale)
  local x = Constants.SCREEN_WIDTH - 150
  local center_y = Constants.SCREEN_HEIGHT / 2
  local card_spacing = Constants.CARD_WIDTH * card_scale - 5
  local total_height = (#hand - 1) * card_spacing
  local start_y = center_y - total_height / 2

  local positions = {}
  for i, card in ipairs(hand) do
    positions[card.id] = {
      x = x,
      y = start_y + (i - 1) * card_spacing,
      rotation = math.pi / 2,
      index = i
    }
  end

  return positions
end

-- Calculate where the NEXT card should go (for animations)
-- This is the position after the card is added to the hand
function LayoutCalculator.calculateNextCardPosition(player, card_scale)
  card_scale = card_scale or 1
  local hand_size = #player.hand

  if player.position == Constants.POSITIONS.BOTTOM then
    local center_x = Constants.SCREEN_WIDTH / 2
    local center_y = Constants.SCREEN_HEIGHT - 70
    local card_spacing = Constants.CARD_WIDTH * card_scale - 5
    local total_width = hand_size * card_spacing
    local start_x = center_x - total_width / 2
    local target_x = start_x + hand_size * card_spacing
    return target_x, center_y, 0

  elseif player.position == Constants.POSITIONS.LEFT then
    local x = 150
    local center_y = Constants.SCREEN_HEIGHT / 2
    local card_spacing = Constants.CARD_WIDTH * card_scale - 5
    local total_height = hand_size * card_spacing
    local start_y = center_y - total_height / 2
    local target_y = start_y + hand_size * card_spacing
    return x, target_y, math.pi / 2

  elseif player.position == Constants.POSITIONS.TOP then
    local center_x = Constants.SCREEN_WIDTH / 2
    local y = 120
    local card_spacing = Constants.CARD_WIDTH * card_scale - 5
    local total_width = hand_size * card_spacing
    local start_x = center_x - total_width / 2
    local target_x = start_x + hand_size * card_spacing
    return target_x, y, 0

  elseif player.position == Constants.POSITIONS.RIGHT then
    local x = Constants.SCREEN_WIDTH - 150
    local center_y = Constants.SCREEN_HEIGHT / 2
    local card_spacing = Constants.CARD_WIDTH * card_scale - 5
    local total_height = hand_size * card_spacing
    local start_y = center_y - total_height / 2
    local target_y = start_y + hand_size * card_spacing
    return x, target_y, math.pi / 2
  end

  return 0, 0, 0
end

-- Helper: Check if point (px, py) is inside a card at position
function LayoutCalculator.isPointInCard(px, py, card_x, card_y, card_scale, rotation)
  card_scale = card_scale or 1
  rotation = rotation or 0

  -- For simplicity, ignore rotation for hit testing (good enough for now)
  -- TODO: Add proper rotated rectangle collision if needed

  local half_w = (Constants.CARD_WIDTH * card_scale) / 2
  local half_h = (Constants.CARD_HEIGHT * card_scale) / 2

  return px >= card_x - half_w and px <= card_x + half_w and
         py >= card_y - half_h and py <= card_y + half_h
end

return LayoutCalculator
