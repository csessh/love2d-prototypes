local AIController = require("controllers/ai_controller")
local Constants = require("utils/constants")
local Flux = require("libraries/flux")
local GameState = require("models/game_state")
local LayoutCalculator = require("utils/layout_calculator")
local CardRenderState = require("views/card_render_state")

local GameController = {}
GameController.__index = GameController

function GameController.new()
  local instance = {
    game_state = GameState.new(),
    animation_queue = {},
    ai_controller = nil,
    animating = false,
    animation_card = nil,
    card_render_state = CardRenderState.new(),
  }
  setmetatable(instance, GameController)
  instance.ai_controller = AIController.new(instance)
  return instance
end

function GameController:update(dt)
  Flux.update(dt)
  self.ai_controller:update(dt)

  if self.game_state.current_state == Constants.STATES.MENU then
    self:handle_menu()
  elseif self.game_state.current_state == Constants.STATES.DEALING then
    self:handle_dealing()
  elseif self.game_state.current_state == Constants.STATES.PLAYER_TURN then
    self:handle_player_turn()
  elseif self.game_state.current_state == Constants.STATES.ROUND_END then
    self:handle_round_end()
  elseif self.game_state.current_state == Constants.STATES.GAME_OVER then
    self:handle_game_over()
  end
end

function GameController:handle_menu()
  self:start_new_round()
end

function GameController:start_new_round()
  self.game_state = GameState.new()
  self.game_state.current_state = Constants.STATES.DEALING
end

function GameController:handle_dealing()
  -- Deal cards (no animation for now)
  -- TODO: Add drawing animations
  self.game_state:deal_cards(9)

  -- TODO: This might not be correct. Review later.
  local first_discard = self.game_state.deck:draw()
  if first_discard then
    self.game_state:add_to_discard(first_discard)
  end

  -- Set initial state based on who starts (current_player_index was randomized)
  local starting_player = self.game_state:get_current_player()
  if starting_player.type == "human" then
    self.game_state.current_state = Constants.STATES.PLAYER_TURN
    self.game_state.turn_substep = Constants.TURN_SUBSTEPS.CHOOSE_ACTION
  else
    self.game_state.current_state = Constants.STATES.AI_TURN
  end
end

function GameController:handle_player_turn()
  -- Input handled by InputController
  -- Just manage substeps here
end

function GameController:handle_round_end()
  self.game_state:calculate_all_scores()
  print("Round ended!")
  for _, player in ipairs(self.game_state.players) do
    print(
      "Player " .. player.id .. " score:",
      self.game_state.scores[player.id]
    )
  end
  self.game_state.current_state = Constants.STATES.GAME_OVER
end

function GameController:handle_game_over()
  -- Wait for restart
end

function GameController:draw_card()
  local card = self.game_state.deck:draw()
  if card then
    local player = self.game_state:get_current_player()
    card.face_up = (player.type == "human")

    local target_x, target_y, rotation =
      self:calculate_card_target_position(player)

    self:start_draw_animation(card, target_x, target_y, rotation)
  end
end

function GameController:discard_card(card)
  local current_player = self.game_state:get_current_player()

  if current_player.type == "human" then
    -- Human player already uses animation via InputController
    if current_player:remove_card_from_hand(card) then
      self.game_state:add_to_discard(card)
      self:end_turn()
    end
  else
    -- AI player: use animation
    self:start_discard_animation(card)
  end
end

function GameController:end_turn()
  local winner = self.game_state:check_win_condition()
  if winner then
    self.game_state.current_state = Constants.STATES.ROUND_END
    return
  end

  self.game_state:next_player()

  if self.game_state:is_deck_empty() then
    self.game_state.current_state = Constants.STATES.ROUND_END
    return
  end

  local next_player = self.game_state:get_current_player()
  if next_player.type == "human" then
    self.game_state.current_state = Constants.STATES.PLAYER_TURN
    self.game_state.turn_substep = Constants.TURN_SUBSTEPS.CHOOSE_ACTION
  else
    self.game_state.current_state = Constants.STATES.AI_TURN
  end
end

function GameController:calculate_card_target_position(player)
  return LayoutCalculator.calculate_next_card_position(
    player,
    Constants.CARD_SCALE
  )
end

function GameController:start_draw_animation(card, target_x, target_y, rotation)
  print("=== START DRAW ANIMATION ===")
  print("Card:", card)
  print("From:", Constants.DRAW_PILE_X, Constants.DRAW_PILE_Y)
  print("To:", target_x, target_y)
  print("Rotation:", rotation or 0)

  self.animating = true
  self.animation_card = card
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.ANIMATING_DRAW

  -- Use CardRenderState instead of card properties
  local render_state = self.card_render_state:get_state(card.id)
  render_state.x = Constants.DRAW_PILE_X
  render_state.y = Constants.DRAW_PILE_Y
  render_state.rotation = 0
  render_state.hover_offset_y = 0
  render_state.face_up = (self.game_state:get_current_player().type == "human")

  rotation = rotation or 0

  -- Animate the render state, not the card
  Flux.to(
    render_state,
    Constants.ANIM_DRAW_DURATION_S,
    { x = target_x, y = target_y, rotation = rotation }
  ):oncomplete(function()
    print("=== DRAW ANIMATION COMPLETE ===")
    self:on_draw_animation_complete(card)
  end)
end

function GameController:on_draw_animation_complete(card)
  local player = self.game_state:get_current_player()
  player:add_card_to_hand(card)

  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.DISCARD_PHASE
  self.animating = false
  self.animation_card = nil
end

function GameController:start_discard_animation(card)
  self.animating = true
  self.animation_card = card
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.ANIMATING_DISCARD

  local player = self.game_state:get_current_player()
  player:remove_card_from_hand(card)

  -- Use CardRenderState
  local render_state = self.card_render_state:get_state(card.id)
  render_state.face_up = true
  -- render_state.x and render_state.y already set by GameView

  -- Rotation animates to 0 for AI players, stays at 0 for human players
  Flux.to(render_state, Constants.ANIM_DISCARD_DURATION_S, {
    x = Constants.DISCARD_PILE_X,
    y = Constants.DISCARD_PILE_Y,
    rotation = 0,
  }):oncomplete(function()
    self:on_discard_animation_complete(card)
  end)
end

function GameController:on_discard_animation_complete(card)
  self.game_state:add_to_discard(card)
  self:end_turn()
  self.animating = false
  self.animation_card = nil
end

function GameController:get_animation_state()
  return {
    animating = self.animating,
    animation_card = self.animation_card,
    card_render_state = self.card_render_state,
  }
end

return GameController
