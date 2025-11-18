local Constants = require("utils/constants")
local CardRenderer = require("views/card_renderer")
local LayoutCalculator = require("utils/layout_calculator")

local GameView = {}
GameView.__index = GameView

-- MVC CONTRACT:
-- GameView is a PURE VIEW - it reads state but NEVER mutates Model data.
-- All rendering is read-only. All state changes happen in Controllers.
--
-- Exception: CardRenderState (view-specific state) is mutated to track visual positions.
-- This is acceptable because it's rendering state, not game logic state.
--
-- Temporary: card.face_up is set for rendering compatibility with CardRenderer.
-- This will be removed once CardRenderer is updated to accept face_up as a parameter.

function GameView.new()
  local instance = {
    card_renderer = CardRenderer.new(),
  }
  return setmetatable(instance, GameView)
end

function GameView:draw(game_state, animation_state)
  love.graphics.clear(0.1, 0.4, 0.2)
  self:draw_deck(game_state)

  local card_render_state = animation_state.card_render_state

  -- Draw each player's discard pile
  for _, player in ipairs(game_state.players) do
    self:draw_player_discard_pile(game_state, player, card_render_state)
  end

  for _, player in ipairs(game_state.players) do
    self:draw_player(player, card_render_state)
  end

  -- Draw animating card on top of everything
  if animation_state.animating and animation_state.animation_card then
    local card = animation_state.animation_card
    local render_state = card_render_state:get_state(card.id)

    -- Only draw if render state has valid position
    if render_state.x and render_state.y then
      -- Temporarily set card.face_up for rendering (will be removed in future)
      card.face_up = render_state.face_up

      self.card_renderer:draw_card(
        card,
        render_state.x,
        render_state.y,
        render_state.rotation or 0,
        Constants.CARD_SCALE
      )
    end
  end

  self:draw_ui(game_state)
end

function GameView:draw_deck(game_state)
  if not game_state.deck:is_empty() then
    local card = { face_up = false }
    self.card_renderer:draw_card(
      card,
      Constants.DRAW_PILE_X,
      Constants.DRAW_PILE_Y,
      0,
      Constants.CARD_SCALE
    )

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(
      "Deck: " .. game_state.deck:size(),
      Constants.DRAW_PILE_X - 50,
      Constants.DRAW_PILE_Y + 110
    )
  end
end


function GameView:draw_player(player, card_render_state)
  if player.position == Constants.POSITIONS.BOTTOM then
    self:draw_bottom_player(player, card_render_state)
  elseif player.position == Constants.POSITIONS.LEFT then
    self:draw_left_player(player, card_render_state)
  elseif player.position == Constants.POSITIONS.TOP then
    self:draw_top_player(player, card_render_state)
  elseif player.position == Constants.POSITIONS.RIGHT then
    self:draw_right_player(player, card_render_state)
  end
end

function GameView:draw_bottom_player(player, card_render_state)
  local positions =
    LayoutCalculator.calculate_hand_positions(player, Constants.CARD_SCALE)

  for i, card in ipairs(player.hand) do
    local pos = positions[card.id]
    if pos then
      local render_state = card_render_state:get_state(card.id)

      -- Update render state (not card properties!)
      render_state.x = pos.x
      render_state.y = pos.y
      render_state.rotation = 0
      render_state.face_up = (player.type == "human")

      local y = pos.y + (render_state.hover_offset_y or 0)

      -- Temporarily set card.face_up for rendering (will be removed later)
      card.face_up = render_state.face_up

      self.card_renderer:draw_card(card, pos.x, y, 0, Constants.CARD_SCALE)
    end
  end

  -- Draw hand area cards
  local hand_area_x = 100
  local hand_area_y = Constants.SCREEN_HEIGHT - 30
  for i, card in ipairs(player.hand_area_cards) do
    self.card_renderer:draw_card(
      card,
      hand_area_x + (i - 1) * (Constants.CARD_WIDTH * Constants.CARD_SCALE),
      hand_area_y,
      0,
      Constants.CARD_SCALE
    )
  end
end

function GameView:draw_left_player(player, card_render_state)
  local x = 150
  local center_y = Constants.SCREEN_HEIGHT / 2
  local positions =
    LayoutCalculator.calculate_hand_positions(player, Constants.CARD_SCALE)

  for i, card in ipairs(player.hand) do
    local pos = positions[card.id]
    if pos then
      local render_state = card_render_state:get_state(card.id)

      -- Update render state (not card properties!)
      render_state.x = pos.x
      render_state.y = pos.y
      render_state.rotation = pos.rotation
      render_state.face_up = false

      -- Temporarily set card.face_up for rendering (will be removed later)
      card.face_up = render_state.face_up

      self.card_renderer:draw_card(
        card,
        pos.x,
        pos.y,
        pos.rotation,
        Constants.CARD_SCALE
      )
    end
  end

  local hand_area_x = 180
  local hand_area_y = center_y
  for i, card in ipairs(player.hand_area_cards) do
    self.card_renderer:draw_card(
      card,
      hand_area_x + (i - 1) * Constants.CARD_HEIGHT,
      hand_area_y,
      math.pi / 2,
      Constants.CARD_SCALE
    )
  end
end

function GameView:draw_top_player(player, card_render_state)
  local center_x = Constants.SCREEN_WIDTH / 2
  local y = 120
  local positions =
    LayoutCalculator.calculate_hand_positions(player, Constants.CARD_SCALE)

  for i, card in ipairs(player.hand) do
    local pos = positions[card.id]
    if pos then
      local render_state = card_render_state:get_state(card.id)

      -- Update render state (not card properties!)
      render_state.x = pos.x
      render_state.y = pos.y
      render_state.rotation = pos.rotation
      render_state.face_up = false

      -- Temporarily set card.face_up for rendering (will be removed later)
      card.face_up = render_state.face_up

      self.card_renderer:draw_card(
        card,
        pos.x,
        pos.y,
        pos.rotation,
        Constants.CARD_SCALE
      )
    end
  end

  local hand_area_x = center_x - 100
  local hand_area_y = y + 150
  for i, card in ipairs(player.hand_area_cards) do
    self.card_renderer:draw_card(
      card,
      hand_area_x + (i - 1) * Constants.CARD_WIDTH,
      hand_area_y,
      0,
      Constants.CARD_SCALE
    )
  end
end

function GameView:draw_right_player(player, card_render_state)
  local x = Constants.SCREEN_WIDTH - 150
  local center_y = Constants.SCREEN_HEIGHT / 2
  local positions =
    LayoutCalculator.calculate_hand_positions(player, Constants.CARD_SCALE)

  for _, card in ipairs(player.hand) do
    local pos = positions[card.id]
    if pos then
      local render_state = card_render_state:get_state(card.id)

      -- Update render state (not card properties!)
      render_state.x = pos.x
      render_state.y = pos.y
      render_state.rotation = pos.rotation
      render_state.face_up = false

      -- Temporarily set card.face_up for rendering (will be removed later)
      card.face_up = render_state.face_up

      self.card_renderer:draw_card(
        card,
        pos.x,
        pos.y,
        pos.rotation,
        Constants.CARD_SCALE
      )
    end
  end

  local hand_area_x = x - 180
  local hand_area_y = center_y
  for i, card in ipairs(player.hand_area_cards) do
    self.card_renderer:draw_card(
      card,
      hand_area_x - (i - 1) * Constants.CARD_HEIGHT,
      hand_area_y,
      math.pi / 2,
      Constants.CARD_SCALE
    )
  end
end

function GameView:draw_hand_in_row(cards, center_x, center_y, face_up, scale)
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
    self.card_renderer:draw_card(card, x, center_y, 0, scale)
  end
end

function GameView:draw_ui(game_state)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Round: " .. game_state.round_number, 10, 10)
  love.graphics.print("State: " .. game_state.current_state, 10, 30)

  -- Draw turn indicator
  self:draw_turn_indicator(game_state)
end

function GameView:draw_turn_indicator(game_state)
  local current_player = game_state:get_current_player()
  if not current_player then
    return
  end

  -- Draw indicator based on player position
  love.graphics.setColor(1, 1, 0, 0.8) -- Yellow with slight transparency

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

  love.graphics.setColor(1, 1, 1) -- Reset to white
end

function GameView:get_discard_pile_anchor(position)
  if position == Constants.POSITIONS.BOTTOM then
    return Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 300, 0
  elseif position == Constants.POSITIONS.TOP then
    return Constants.SCREEN_WIDTH / 2, 300, 0
  elseif position == Constants.POSITIONS.LEFT then
    return 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  elseif position == Constants.POSITIONS.RIGHT then
    return Constants.SCREEN_WIDTH - 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  end
  return 0, 0, 0
end

function GameView:draw_player_discard_pile(game_state, player, card_render_state)
  local cards = game_state:get_cards_from_discard_pile(player.id)
  if #cards == 0 then
    return  -- No rendering for empty piles
  end

  -- Get anchor position based on player position
  local base_x, base_y, rotation = self:get_discard_pile_anchor(player.position)

  -- Calculate spread positions for all cards
  local positions = LayoutCalculator.calculate_discard_pile_positions(
    cards, base_x, base_y, rotation, Constants.CARD_SCALE
  )

  -- Render cards in z-index order (bottom to top)
  for i, card in ipairs(cards) do
    local pos = positions[card.id]
    self.card_renderer:draw_card(
      card, pos.x, pos.y, pos.rotation,
      Constants.CARD_SCALE, true  -- Always face up
    )
  end
end

return GameView
