local Constants = require("utils/constants")
local HandValidator = require("models/hand_validator")

local AIController = {}
AIController.__index = AIController

function AIController.new(game_controller)
  local instance = {
    game_controller = game_controller,
    think_timer = 0,
    think_duration = 1.0  -- AI waits 1 second before acting
  }
  return setmetatable(instance, AIController)
end

function AIController:update(dt)
  local game_state = self.game_controller.game_state

  if game_state.current_state == Constants.STATES.AI_TURN then
    self.think_timer = self.think_timer + dt

    if self.think_timer >= self.think_duration then
      self:makeMove()
      self.think_timer = 0
    end
  end
end

function AIController:makeMove()
  local game_state = self.game_controller.game_state
  local ai_player = game_state:getCurrentPlayer()

  -- Simple AI: just draw and discard
  -- TODO: Implement behavior tree

  -- Draw card from deck
  self.game_controller:drawCard()

  -- Discard highest point card (simple strategy)
  local highest_card = self:findHighestPointCard(ai_player.hand)
  if highest_card then
    self.game_controller:discardCard(highest_card)
  end
end

function AIController:findHighestPointCard(hand)
  if #hand == 0 then return nil end

  local highest = hand[1]
  for _, card in ipairs(hand) do
    if card:getPointValue() > highest:getPointValue() then
      highest = card
    end
  end

  return highest
end

return AIController
