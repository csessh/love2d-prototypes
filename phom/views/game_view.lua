local Constants = require("utils/constants")
local CardRenderer = require("views/card_renderer")
local LayoutCalculator = require("utils/layout_calculator")

local GameView = {}
GameView.__index = GameView

-- Card scale constant for consistent sizing
local CARD_SCALE = 2

function GameView.new()
  local instance = {
    card_renderer = CardRenderer.new(),
  }
  return setmetatable(instance, GameView)
end

function GameView:draw(game_state, game_controller)
  love.graphics.clear(0.1, 0.4, 0.2)
  self:drawDeck(game_state)
  self:drawDiscardPile(game_state)

  for _, player in ipairs(game_state.players) do
    self:drawPlayer(player)
  end

  -- Draw animating card on top of everything
  if game_controller and game_controller.animating and game_controller.animation_card then
    local card = game_controller.animation_card
    local rotation = card.rotation or 0
    self.card_renderer:drawCard(card, card.x, card.y, rotation, CARD_SCALE)
  end

  self:drawUI(game_state)
end

function GameView:drawDeck(game_state)
  if not game_state.deck:isEmpty() then
    -- Center both deck and discard pile horizontally, with some spacing between them
    local spacing = 20
    local total_width = (Constants.CARD_WIDTH * CARD_SCALE * 2) + spacing
    local deck_x = Constants.SCREEN_WIDTH / 2 - total_width / 2 + (Constants.CARD_WIDTH * CARD_SCALE / 2)
    local deck_y = Constants.SCREEN_HEIGHT / 2

    local card = { face_up = false }
    self.card_renderer:drawCard(card, deck_x, deck_y, 0, CARD_SCALE)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(
      "Deck: " .. game_state.deck:size(),
      deck_x - 50,
      deck_y + 110
    )
  end
end

function GameView:drawDiscardPile(game_state)
  -- Center both deck and discard pile horizontally, with some spacing between them
  local spacing = 20
  local total_width = (Constants.CARD_WIDTH * CARD_SCALE * 2) + spacing
  local discard_x = Constants.SCREEN_WIDTH / 2 + total_width / 2 - (Constants.CARD_WIDTH * CARD_SCALE / 2)
  local discard_y = Constants.SCREEN_HEIGHT / 2

  local top_card = game_state:getTopDiscard()
  if top_card then
    self.card_renderer:drawCard(top_card, discard_x, discard_y, 0, CARD_SCALE)
  else
    -- Draw placeholder with size * 1.2
    local placeholder_scale = 1.2
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle(
      "line",
      discard_x - Constants.CARD_WIDTH * placeholder_scale / 2,
      discard_y - Constants.CARD_HEIGHT * placeholder_scale / 2,
      Constants.CARD_WIDTH * placeholder_scale,
      Constants.CARD_HEIGHT * placeholder_scale,
      5,
      5
    )
    love.graphics.setColor(1, 1, 1)
  end

  love.graphics.print("Discard", discard_x - 30, discard_y + 110)
end

function GameView:drawPlayer(player)
  if player.position == Constants.POSITIONS.BOTTOM then
    self:drawBottomPlayer(player)
  elseif player.position == Constants.POSITIONS.LEFT then
    self:drawLeftPlayer(player)
  elseif player.position == Constants.POSITIONS.TOP then
    self:drawTopPlayer(player)
  elseif player.position == Constants.POSITIONS.RIGHT then
    self:drawRightPlayer(player)
  end
end

function GameView:drawBottomPlayer(player)
  local positions = LayoutCalculator.calculateHandPositions(player, CARD_SCALE)

  for i, card in ipairs(player.hand) do
    local pos = positions[card.id]
    if pos then
      local x = pos.x
      local y = pos.y + (card.hover_offset_y or 0)

      -- Store position on card for animation system (temporary, will fix in Task 2)
      card.x = x
      card.y = y

      card.face_up = player.type == "human"
      self.card_renderer:drawCard(card, x, y, 0, CARD_SCALE)
    end
  end

  -- Draw hand area cards
  local hand_area_x = 100
  local hand_area_y = Constants.SCREEN_HEIGHT - 30
  for i, card in ipairs(player.hand_area_cards) do
    self.card_renderer:drawCard(
      card,
      hand_area_x + (i - 1) * (Constants.CARD_WIDTH * CARD_SCALE),
      hand_area_y,
      0,
      CARD_SCALE
    )
  end
end

function GameView:drawLeftPlayer(player)
  local positions = LayoutCalculator.calculateHandPositions(player, CARD_SCALE)

  for i, card in ipairs(player.hand) do
    local pos = positions[card.id]
    if pos then
      -- Store position on card for animation system (temporary, will fix in Task 2)
      card.x = pos.x
      card.y = pos.y
      card.rotation = pos.rotation

      card.face_up = false
      self.card_renderer:drawCard(card, pos.x, pos.y, pos.rotation, CARD_SCALE)
    end
  end

  local hand_area_x = 150 + 180
  local hand_area_y = Constants.SCREEN_HEIGHT / 2
  for i, card in ipairs(player.hand_area_cards) do
    self.card_renderer:drawCard(
      card,
      hand_area_x + (i - 1) * Constants.CARD_HEIGHT,
      hand_area_y,
      math.pi / 2,
      CARD_SCALE
    )
  end
end

function GameView:drawTopPlayer(player)
  local positions = LayoutCalculator.calculateHandPositions(player, CARD_SCALE)

  for i, card in ipairs(player.hand) do
    local pos = positions[card.id]
    if pos then
      -- Store position on card for animation system (temporary, will fix in Task 2)
      card.x = pos.x
      card.y = pos.y
      card.rotation = pos.rotation

      card.face_up = false
      self.card_renderer:drawCard(card, pos.x, pos.y, pos.rotation, CARD_SCALE)
    end
  end

  local center_x = Constants.SCREEN_WIDTH / 2
  local hand_area_x = center_x - 100
  local hand_area_y = 120 + 150
  for i, card in ipairs(player.hand_area_cards) do
    self.card_renderer:drawCard(
      card,
      hand_area_x + (i - 1) * Constants.CARD_WIDTH,
      hand_area_y,
      0,
      CARD_SCALE
    )
  end
end

function GameView:drawRightPlayer(player)
  local positions = LayoutCalculator.calculateHandPositions(player, CARD_SCALE)

  for i, card in ipairs(player.hand) do
    local pos = positions[card.id]
    if pos then
      -- Store position on card for animation system (temporary, will fix in Task 2)
      card.x = pos.x
      card.y = pos.y
      card.rotation = pos.rotation

      card.face_up = false
      self.card_renderer:drawCard(card, pos.x, pos.y, pos.rotation, CARD_SCALE)
    end
  end

  local x = Constants.SCREEN_WIDTH - 150
  local center_y = Constants.SCREEN_HEIGHT / 2
  local hand_area_x = x - 180
  local hand_area_y = center_y
  for i, card in ipairs(player.hand_area_cards) do
    self.card_renderer:drawCard(
      card,
      hand_area_x - (i - 1) * Constants.CARD_HEIGHT,
      hand_area_y,
      math.pi / 2,
      CARD_SCALE
    )
  end
end

function GameView:drawHandInRow(cards, center_x, center_y, face_up, scale)
  if #cards == 0 then
    return
  end

  scale = scale or 1
  local card_spacing = Constants.CARD_WIDTH * scale * 1.1
  local total_width = (#cards - 1) * card_spacing
  local start_x = center_x - total_width / 2

  for i, card in ipairs(cards) do
    local x = start_x + (i - 1) * card_spacing
    card.face_up = face_up
    self.card_renderer:drawCard(card, x, center_y, 0, scale)
  end
end

function GameView:drawUI(game_state)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Round: " .. game_state.round_number, 10, 10)
  love.graphics.print("State: " .. game_state.current_state, 10, 30)

  -- Draw turn indicator
  self:drawTurnIndicator(game_state)
end

function GameView:drawTurnIndicator(game_state)
  local current_player = game_state:getCurrentPlayer()
  if not current_player then return end

  -- Draw indicator based on player position
  love.graphics.setColor(1, 1, 0, 0.8)  -- Yellow with slight transparency

  if current_player.position == Constants.POSITIONS.BOTTOM then
    -- Arrow pointing down at bottom player
    local x = Constants.SCREEN_WIDTH / 2
    local y = Constants.SCREEN_HEIGHT - 200
    love.graphics.polygon("fill", x, y + 30, x - 15, y, x + 15, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("YOUR TURN", x - 35, y - 25)

  elseif current_player.position == Constants.POSITIONS.LEFT then
    -- Arrow pointing left
    local x = 280
    local y = Constants.SCREEN_HEIGHT / 2
    love.graphics.polygon("fill", x - 30, y, x, y - 15, x, y + 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("AI TURN", x + 10, y - 10)

  elseif current_player.position == Constants.POSITIONS.TOP then
    -- Arrow pointing up at top player
    local x = Constants.SCREEN_WIDTH / 2
    local y = 220
    love.graphics.polygon("fill", x, y - 30, x - 15, y, x + 15, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("AI TURN", x - 25, y + 10)

  elseif current_player.position == Constants.POSITIONS.RIGHT then
    -- Arrow pointing right
    local x = Constants.SCREEN_WIDTH - 280
    local y = Constants.SCREEN_HEIGHT / 2
    love.graphics.polygon("fill", x + 30, y, x, y - 15, x, y + 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("AI TURN", x - 60, y - 10)
  end

  love.graphics.setColor(1, 1, 1)  -- Reset to white
end

return GameView
