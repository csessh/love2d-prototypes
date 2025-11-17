local Constants = require("utils/constants")
local HandValidator = require("utils/hand_validator")

local AIController = {}
AIController.__index = AIController

function AIController.new(game_controller)
  local instance = {
    game_controller = game_controller,
    think_timer = 0,
    think_duration = 1.0,
    waiting_for_animation = false,
    card_to_discard = nil,
  }
  return setmetatable(instance, AIController)
end

function AIController:update(dt)
  local game_state = self.game_controller.game_state

  if game_state.current_state == Constants.STATES.AI_TURN then
    if self.waiting_for_animation then
      if game_state.turn_substep == Constants.TURN_SUBSTEPS.DISCARD_PHASE then
        local ai_player = game_state:get_current_player()
        local highest_card = self:find_highest_point_card(ai_player.hand)

        if highest_card then
          self.game_controller:discard_card(highest_card)
        end

        self.waiting_for_animation = false
      end
    else
      self.think_timer = self.think_timer + dt

      if self.think_timer >= self.think_duration then
        self:make_move()
        self.think_timer = 0
      end
    end
  end
end

function AIController:make_move()
  -- Simple AI: just draw and discard
  -- TODO: Implement behavior tree

  self.game_controller:draw_card()

  -- Wait for draw animation to complete before discarding
  -- (update() will handle discarding once turn_substep becomes DISCARD_PHASE)
  self.waiting_for_animation = true
end

function AIController:find_highest_point_card(hand)
  if #hand == 0 then
    return nil
  end

  local highest = hand[1]
  for _, card in ipairs(hand) do
    if card:get_point_value() > highest:get_point_value() then
      highest = card
    end
  end

  return highest
end

return AIController
