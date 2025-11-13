local Constants = require("utils/constants")
local GameState = require("models/game_state")
local AIController = require("controllers/ai_controller")
local flux = require("libraries/flux")

local GameController = {}
GameController.__index = GameController

function GameController.new()
  local instance = {
    game_state = GameState.new(),
    animation_queue = {},
    ai_controller = nil,
    animating = false,
    animation_card = nil,
  }
  setmetatable(instance, GameController)
  instance.ai_controller = AIController.new(instance)
  return instance
end

function GameController:update(dt)
  flux.update(dt)
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

  self.game_state.current_state = Constants.STATES.PLAYER_TURN
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.CHOOSE_ACTION
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
    self.game_state:getCurrentPlayer():addCardToHand(card)
    self.game_state.turn_substep = Constants.TURN_SUBSTEPS.DISCARD_PHASE
  end
end

function GameController:discardCard(card)
  local current_player = self.game_state:getCurrentPlayer()
  if current_player:removeCardFromHand(card) then
    self.game_state:addToDiscard(card)
    self:endTurn()
  end
end

function GameController:endTurn()
  local winner = self.game_state:checkWinCondition()
  if winner then
    self.game_state.current_state = Constants.STATES.ROUND_END
    return
  end

  if self.game_state:isDeckEmpty() then
    self.game_state.current_state = Constants.STATES.ROUND_END
    return
  end

  self.game_state:nextPlayer()

  local next_player = self.game_state:getCurrentPlayer()
  if next_player.type == "human" then
    self.game_state.current_state = Constants.STATES.PLAYER_TURN
    self.game_state.turn_substep = Constants.TURN_SUBSTEPS.CHOOSE_ACTION
  else
    self.game_state.current_state = Constants.STATES.AI_TURN
  end
end

function GameController:startDrawAnimation(card, target_x, target_y)
  self.animating = true
  self.animation_card = card
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.ANIMATING_DRAW

  card.x = Constants.DECK_X
  card.y = Constants.DECK_Y

  flux.to(card, 0.3, {x = target_x, y = target_y})
    :oncomplete(function()
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

  -- Remove card from hand immediately so it's not drawn in hand during animation
  local player = self.game_state:getCurrentPlayer()
  player:removeCardFromHand(card)

  -- Card position should already be set by GameView
  -- Start animation from current position to discard pile
  flux.to(card, 0.25, {x = Constants.DISCARD_X, y = Constants.DISCARD_Y})
    :oncomplete(function()
      self:onDiscardAnimationComplete(card)
    end)
end

function GameController:onDiscardAnimationComplete(card)
  -- Add to discard pile
  self.game_state:addToDiscard(card)

  -- End turn
  self:endTurn()

  -- Clear animation state
  self.animating = false
  self.animation_card = nil
end

return GameController
