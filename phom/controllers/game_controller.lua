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
    self:handleMenu()
  elseif self.game_state.current_state == Constants.STATES.DEALING then
    self:handleDealing()
  elseif self.game_state.current_state == Constants.STATES.PLAYER_TURN then
    self:handlePlayerTurn()
  elseif self.game_state.current_state == Constants.STATES.ROUND_END then
    self:handleRoundEnd()
  elseif self.game_state.current_state == Constants.STATES.GAME_OVER then
    self:handleGameOver()
  end
end

function GameController:handleMenu()
  self:startNewRound()
end

function GameController:startNewRound()
  self.game_state = GameState.new()
  self.game_state.current_state = Constants.STATES.DEALING
end

function GameController:handleDealing()
  -- Deal cards (no animation for now)
  -- TODO: Add drawing animations
  self.game_state:dealCards(9)

  -- TODO: This might not be correct. Review later.
  local first_discard = self.game_state.deck:draw()
  if first_discard then
    self.game_state:addToDiscard(first_discard)
  end

  -- Set initial state based on who starts (current_player_index was randomized)
  local starting_player = self.game_state:getCurrentPlayer()
  if starting_player.type == "human" then
    self.game_state.current_state = Constants.STATES.PLAYER_TURN
    self.game_state.turn_substep = Constants.TURN_SUBSTEPS.CHOOSE_ACTION
  else
    self.game_state.current_state = Constants.STATES.AI_TURN
  end
end

function GameController:handlePlayerTurn()
  -- Input handled by InputController
  -- Just manage substeps here
end

function GameController:handleRoundEnd()
  self.game_state:calculateAllScores()
  print("Round ended!")
  for _, player in ipairs(self.game_state.players) do
    print(
      "Player " .. player.id .. " score:",
      self.game_state.scores[player.id]
    )
  end
  self.game_state.current_state = Constants.STATES.GAME_OVER
end

function GameController:handleGameOver()
  -- Wait for restart
end

function GameController:drawCard()
  local card = self.game_state.deck:draw()
  if card then
    local player = self.game_state:getCurrentPlayer()
    card.face_up = (player.type == "human")

    local target_x, target_y, rotation =
      self:calculateCardTargetPosition(player)

    self:startDrawAnimation(card, target_x, target_y, rotation)
  end
end

function GameController:discardCard(card)
  local current_player = self.game_state:getCurrentPlayer()

  if current_player.type == "human" then
    -- Human player already uses animation via InputController
    if current_player:removeCardFromHand(card) then
      self.game_state:addToDiscard(card)
      self:endTurn()
    end
  else
    -- AI player: use animation
    self:startDiscardAnimation(card)
  end
end

function GameController:endTurn()
  local winner = self.game_state:checkWinCondition()
  if winner then
    self.game_state.current_state = Constants.STATES.ROUND_END
    return
  end

  self.game_state:nextPlayer()

  if self.game_state:isDeckEmpty() then
    self.game_state.current_state = Constants.STATES.ROUND_END
    return
  end

  local next_player = self.game_state:getCurrentPlayer()
  if next_player.type == "human" then
    self.game_state.current_state = Constants.STATES.PLAYER_TURN
    self.game_state.turn_substep = Constants.TURN_SUBSTEPS.CHOOSE_ACTION
  else
    self.game_state.current_state = Constants.STATES.AI_TURN
  end
end

function GameController:calculateCardTargetPosition(player)
  return LayoutCalculator.calculateNextCardPosition(player, Constants.CARD_SCALE)
end

function GameController:startDrawAnimation(card, target_x, target_y, rotation)
  print("=== START DRAW ANIMATION ===")
  print("Card:", card)
  print("From:", Constants.DECK_X, Constants.DECK_Y)
  print("To:", target_x, target_y)
  print("Rotation:", rotation or 0)

  self.animating = true
  self.animation_card = card
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.ANIMATING_DRAW

  -- Use CardRenderState instead of card properties
  local render_state = self.card_render_state:getState(card.id)
  render_state.x = Constants.DECK_X
  render_state.y = Constants.DECK_Y
  render_state.rotation = 0
  render_state.hover_offset_y = 0
  render_state.face_up = (self.game_state:getCurrentPlayer().type == "human")

  rotation = rotation or 0

  -- Animate the render state, not the card
  Flux.to(render_state, 0.3, { x = target_x, y = target_y, rotation = rotation })
    :oncomplete(function()
      print("=== DRAW ANIMATION COMPLETE ===")
      self:onDrawAnimationComplete(card)
    end)
end

function GameController:onDrawAnimationComplete(card)
  local player = self.game_state:getCurrentPlayer()
  player:addCardToHand(card)

  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.DISCARD_PHASE
  self.animating = false
  self.animation_card = nil
end

function GameController:startDiscardAnimation(card)
  self.animating = true
  self.animation_card = card
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.ANIMATING_DISCARD

  local player = self.game_state:getCurrentPlayer()
  player:removeCardFromHand(card)

  -- Use CardRenderState
  local render_state = self.card_render_state:getState(card.id)
  render_state.face_up = true
  -- render_state.x and render_state.y already set by GameView

  Flux.to(render_state, 0.25, { x = Constants.DISCARD_X, y = Constants.DISCARD_Y, rotation = 0 })
    :oncomplete(function()
      self:onDiscardAnimationComplete(card)
    end)
end

function GameController:onDiscardAnimationComplete(card)
  self.game_state:addToDiscard(card)
  self:endTurn()
  self.animating = false
  self.animation_card = nil
end

function GameController:getAnimationState()
  return {
    animating = self.animating,
    animation_card = self.animation_card,
    card_render_state = self.card_render_state
  }
end

return GameController
