local Constants = require("utils/constants")
local CardRenderer = require("views/card_renderer")

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

function GameView:draw(game_state)
  love.graphics.clear(0.1, 0.4, 0.2)
  self:drawDeck(game_state)
  self:drawDiscardPile(game_state)

  for _, player in ipairs(game_state.players) do
    self:drawPlayer(player)
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
  local center_x = Constants.SCREEN_WIDTH / 2
  local center_y = Constants.SCREEN_HEIGHT - 70

  -- Calculate horizontal positioning with no spacing
  local card_spacing = Constants.CARD_WIDTH
  local total_width = (#player.hand - 1) * card_spacing
  local start_x = center_x - total_width / 2

  for i, card in ipairs(player.hand) do
    local x = start_x + (i - 1) * card_spacing
    card.face_up = player.type == "human"
    self.card_renderer:drawCard(card, x, center_y, 0, CARD_SCALE)
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
  local x = 150
  local center_y = Constants.SCREEN_HEIGHT / 2

  -- Calculate vertical centering for hand cards (no spacing, cards touching)
  local card_spacing = Constants.CARD_WIDTH  -- When rotated, width becomes the vertical spacing
  local total_height = (player:getHandSize() - 1) * card_spacing
  local start_y = center_y - total_height / 2

  for i = 1, player:getHandSize() do
    local card = { face_up = false }
    self.card_renderer:drawCard(
      card,
      x,
      start_y + (i - 1) * card_spacing,
      math.pi / 2,
      CARD_SCALE
    )
  end

  local hand_area_x = x + 180
  local hand_area_y = center_y
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
  local center_x = Constants.SCREEN_WIDTH / 2
  local y = 120

  -- Calculate horizontal centering (no spacing, cards touching)
  local card_spacing = Constants.CARD_WIDTH
  local total_width = (player:getHandSize() - 1) * card_spacing
  local start_x = center_x - total_width / 2

  for i = 1, player:getHandSize() do
    local card = { face_up = false }
    self.card_renderer:drawCard(
      card,
      start_x + (i - 1) * card_spacing,
      y,
      0,
      CARD_SCALE
    )
  end

  local hand_area_x = center_x - 100
  local hand_area_y = y + 150
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
  local x = Constants.SCREEN_WIDTH - 150
  local center_y = Constants.SCREEN_HEIGHT / 2

  -- Calculate vertical centering for hand cards (no spacing, cards touching)
  local card_spacing = Constants.CARD_WIDTH  -- When rotated, width becomes the vertical spacing
  local total_height = (player:getHandSize() - 1) * card_spacing
  local start_y = center_y - total_height / 2

  for i = 1, player:getHandSize() do
    local card = { face_up = false }
    self.card_renderer:drawCard(
      card,
      x,
      start_y + (i - 1) * card_spacing,
      math.pi / 2,
      CARD_SCALE
    )
  end

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
end

return GameView
