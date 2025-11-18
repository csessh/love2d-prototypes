local Constants = require("utils/constants")

local LayoutCalculator = {}

-- Fixed position constants for player hand layouts
local BOTTOM_PLAYER_Y_OFFSET = 70
local TOP_PLAYER_Y = 120
local LEFT_PLAYER_X = 150
local RIGHT_PLAYER_X_OFFSET = 150

-- Calculate positions for all cards in a player's hand
-- Returns: table mapping card.id -> {x, y, rotation, index}
function LayoutCalculator.calculate_hand_positions(player, card_scale)
  card_scale = card_scale or 1
  local positions = {}

  if player.position == Constants.POSITIONS.BOTTOM then
    positions =
      LayoutCalculator.calculate_bottom_hand_positions(player.hand, card_scale)
  elseif player.position == Constants.POSITIONS.LEFT then
    positions =
      LayoutCalculator.calculate_left_hand_positions(player.hand, card_scale)
  elseif player.position == Constants.POSITIONS.TOP then
    positions =
      LayoutCalculator.calculate_top_hand_positions(player.hand, card_scale)
  elseif player.position == Constants.POSITIONS.RIGHT then
    positions =
      LayoutCalculator.calculate_right_hand_positions(player.hand, card_scale)
  end

  return positions
end

function LayoutCalculator.calculate_bottom_hand_positions(hand, card_scale)
  local center_x = Constants.SCREEN_WIDTH / 2
  local center_y = Constants.SCREEN_HEIGHT - BOTTOM_PLAYER_Y_OFFSET
  local card_spacing = Constants.CARD_WIDTH
  local total_width = (#hand - 1) * card_spacing
  local start_x = center_x - total_width / 2

  local positions = {}
  for i, card in ipairs(hand) do
    positions[card.id] = {
      x = start_x + (i - 1) * card_spacing,
      y = center_y,
      rotation = 0,
      index = i,
    }
  end

  return positions
end

function LayoutCalculator.calculate_left_hand_positions(hand, card_scale)
  local x = LEFT_PLAYER_X
  local center_y = Constants.SCREEN_HEIGHT / 2
  local card_spacing = Constants.CARD_WIDTH -- Width becomes vertical spacing when rotated
  local total_height = (#hand - 1) * card_spacing
  local start_y = center_y - total_height / 2

  local positions = {}
  for i, card in ipairs(hand) do
    positions[card.id] = {
      x = x,
      y = start_y + (i - 1) * card_spacing,
      rotation = math.pi / 2,
      index = i,
    }
  end

  return positions
end

function LayoutCalculator.calculate_top_hand_positions(hand, card_scale)
  local center_x = Constants.SCREEN_WIDTH / 2
  local y = TOP_PLAYER_Y
  local card_spacing = Constants.CARD_WIDTH
  local total_width = (#hand - 1) * card_spacing
  local start_x = center_x - total_width / 2

  local positions = {}
  for i, card in ipairs(hand) do
    positions[card.id] = {
      x = start_x + (i - 1) * card_spacing,
      y = y,
      rotation = 0,
      index = i,
    }
  end

  return positions
end

function LayoutCalculator.calculate_right_hand_positions(hand, card_scale)
  local x = Constants.SCREEN_WIDTH - RIGHT_PLAYER_X_OFFSET
  local center_y = Constants.SCREEN_HEIGHT / 2
  local card_spacing = Constants.CARD_WIDTH
  local total_height = (#hand - 1) * card_spacing
  local start_y = center_y - total_height / 2

  local positions = {}
  for i, card in ipairs(hand) do
    positions[card.id] = {
      x = x,
      y = start_y + (i - 1) * card_spacing,
      rotation = math.pi / 2,
      index = i,
    }
  end

  return positions
end

-- Calculate where the NEXT card should go (for animations)
-- This is the position after the card is added to the hand
function LayoutCalculator.calculate_next_card_position(player, card_scale)
  card_scale = card_scale or 1
  local hand_size = #player.hand -- Size AFTER card will be added

  if player.position == Constants.POSITIONS.BOTTOM then
    local center_x = Constants.SCREEN_WIDTH / 2
    local center_y = Constants.SCREEN_HEIGHT - BOTTOM_PLAYER_Y_OFFSET
    local card_spacing = Constants.CARD_WIDTH
    local total_width = hand_size * card_spacing -- Use current size (includes new card)
    local start_x = center_x - total_width / 2
    local target_x = start_x + hand_size * card_spacing
    return target_x, center_y, 0
  elseif player.position == Constants.POSITIONS.LEFT then
    local x = LEFT_PLAYER_X
    local center_y = Constants.SCREEN_HEIGHT / 2
    local card_spacing = Constants.CARD_WIDTH
    local total_height = hand_size * card_spacing
    local start_y = center_y - total_height / 2
    local target_y = start_y + hand_size * card_spacing
    return x, target_y, math.pi / 2
  elseif player.position == Constants.POSITIONS.TOP then
    local center_x = Constants.SCREEN_WIDTH / 2
    local y = TOP_PLAYER_Y
    local card_spacing = Constants.CARD_WIDTH
    local total_width = hand_size * card_spacing
    local start_x = center_x - total_width / 2
    local target_x = start_x + hand_size * card_spacing
    return target_x, y, 0
  elseif player.position == Constants.POSITIONS.RIGHT then
    local x = Constants.SCREEN_WIDTH - RIGHT_PLAYER_X_OFFSET
    local center_y = Constants.SCREEN_HEIGHT / 2
    local card_spacing = Constants.CARD_WIDTH
    local total_height = hand_size * card_spacing
    local start_y = center_y - total_height / 2
    local target_y = start_y + hand_size * card_spacing
    return x, target_y, math.pi / 2
  end

  return 0, 0, 0
end

-- Helper: Check if point (px, py) is inside a card at position
function LayoutCalculator.is_point_in_card(
  px,
  py,
  card_x,
  card_y,
  card_scale,
  rotation
)
  card_scale = card_scale or 1
  rotation = rotation or 0

  -- For simplicity, ignore rotation for hit testing (good enough for now)
  -- TODO: Add proper rotated rectangle collision if needed

  local half_w = (Constants.CARD_WIDTH * card_scale) / 2
  local half_h = (Constants.CARD_HEIGHT * card_scale) / 2

  return px >= card_x - half_w
    and px <= card_x + half_w
    and py >= card_y - half_h
    and py <= card_y + half_h
end

-- Calculate positions for cards in a discard pile with horizontal spreading
-- Returns: table mapping card.id -> {x, y, rotation, z_index}
function LayoutCalculator.calculate_discard_pile_positions(cards, base_x, base_y, rotation, card_scale)
  card_scale = card_scale or 1
  rotation = rotation or 0

  local positions = {}
  local overlap_offset = Constants.DISCARD_OVERLAP_OFFSET

  for i, card in ipairs(cards) do
    local is_top_card = (i == #cards)
    positions[card.id] = {
      x = base_x + (i - 1) * overlap_offset,
      y = base_y,
      rotation = rotation,
      z_index = i,  -- Higher index = rendered on top
      fully_visible = is_top_card
    }
  end

  return positions
end

return LayoutCalculator
