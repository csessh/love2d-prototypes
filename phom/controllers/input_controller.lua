local Constants = require("utils/constants")
local flux = require("libraries/flux")

local InputController = {}
InputController.__index = InputController

-- Card scale constant (must match GameView)
local CARD_SCALE = 2

function InputController.new(game_controller)
  local instance = {
    game_controller = game_controller,
    hovered_card = nil,
    hovered_card_index = nil,
    mouse_x = 0,
    mouse_y = 0,
  }
  return setmetatable(instance, InputController)
end

function InputController:update(dt)
  -- Update hover detection based on mouse position
  self:updateHover()
end

function InputController:mousepressed(x, y, button)
  print("=== MOUSE PRESSED ===")
  print("Button:", button)
  print("Position:", x, y)

  if button ~= 1 then
    print("Not left click, ignoring")
    return
  end

  local game_state = self.game_controller.game_state
  print("Game state:", game_state.current_state)
  print("Turn substep:", game_state.turn_substep)

  -- Block input during animations (both flag and animation substeps)
  if self.game_controller.animating then
    print("BLOCKED: Animation flag is true")
    return
  end

  if game_state.turn_substep == Constants.TURN_SUBSTEPS.ANIMATING_DRAW or
     game_state.turn_substep == Constants.TURN_SUBSTEPS.ANIMATING_DISCARD then
    print("BLOCKED: Animation substep active")
    return
  end

  if game_state.current_state == Constants.STATES.PLAYER_TURN then
    if game_state.turn_substep == Constants.TURN_SUBSTEPS.CHOOSE_ACTION then
      print("Calling handleChooseAction")
      self:handleChooseAction(x, y)
    elseif game_state.turn_substep == Constants.TURN_SUBSTEPS.DISCARD_PHASE then
      print("Calling handleDiscardPhase")
      self:handleDiscardPhase(x, y)
    else
      print("Unknown substep:", game_state.turn_substep)
    end
  else
    print("Not PLAYER_TURN state")
  end
end

function InputController:mousemoved(x, y)
  self.mouse_x = x
  self.mouse_y = y
end

function InputController:updateHover()
  local game_state = self.game_controller.game_state

  -- Block hover during animations (both flag and animation substeps)
  if self.game_controller.animating then
    self:clearHover()
    return
  end

  if game_state.turn_substep == Constants.TURN_SUBSTEPS.ANIMATING_DRAW or
     game_state.turn_substep == Constants.TURN_SUBSTEPS.ANIMATING_DISCARD then
    self:clearHover()
    return
  end

  -- Only apply hover effects during player turn for human player
  if game_state.current_state ~= Constants.STATES.PLAYER_TURN then
    self:clearHover()
    return
  end

  local player = game_state:getCurrentPlayer()
  if player.type ~= "human" then
    self:clearHover()
    return
  end

  -- Calculate card positions (must match GameView:drawBottomPlayer)
  local center_x = Constants.SCREEN_WIDTH / 2
  local center_y = Constants.SCREEN_HEIGHT - 70
  local card_spacing = Constants.CARD_WIDTH
  local total_width = (#player.hand - 1) * card_spacing
  local start_x = center_x - total_width / 2

  -- Find which card (if any) is being hovered
  -- Check cards in REVERSE order (rightmost/topmost first)
  local new_hovered_index = nil
  for i = #player.hand, 1, -1 do
    local card = player.hand[i]
    local x = start_x + (i - 1) * card_spacing
    local y = center_y + (card.hover_offset_y or 0)

    if self:isPointInCard(self.mouse_x, self.mouse_y, x, y, CARD_SCALE) then
      new_hovered_index = i
      break
    end
  end

  -- Handle hover state changes
  if new_hovered_index ~= self.hovered_card_index then
    -- Clear previous hover
    if self.hovered_card_index then
      local prev_card = player.hand[self.hovered_card_index]
      if prev_card and prev_card.hover_offset_y then
        -- Animate back down
        flux.to(prev_card, 0.1, { hover_offset_y = 0 })
      end
    end

    -- Set new hover
    self.hovered_card_index = new_hovered_index
    if new_hovered_index then
      local card = player.hand[new_hovered_index]
      if not card.hover_offset_y then
        card.hover_offset_y = 0
      end
      -- Animate up by 15% of card height
      local hover_offset = -(Constants.CARD_HEIGHT * CARD_SCALE * 0.15)
      flux.to(card, 0.1, { hover_offset_y = hover_offset })
    end
  end
end

function InputController:clearHover()
  if self.hovered_card_index then
    local game_state = self.game_controller.game_state
    local player = game_state:getCurrentPlayer()
    if player and player.hand[self.hovered_card_index] then
      local card = player.hand[self.hovered_card_index]
      if card.hover_offset_y then
        flux.to(card, 0.1, { hover_offset_y = 0 })
      end
    end
    self.hovered_card_index = nil
  end
end

function InputController:handleChooseAction(x, y)
  local game_state = self.game_controller.game_state

  -- Check if clicked on deck
  if self:isPointInCard(x, y, Constants.DECK_X, Constants.DECK_Y, CARD_SCALE) and not game_state:isDeckEmpty() then
    print("Clicked deck - drawing card")
    self.game_controller:drawCard()
    return
  end

  -- TODO: Handle clicking on hand cards for meld formation
end

function InputController:handleDiscardPhase(x, y)
  local game_state = self.game_controller.game_state
  local player = game_state:getCurrentPlayer()

  -- Calculate card positions (must match GameView:drawBottomPlayer)
  local center_x = Constants.SCREEN_WIDTH / 2
  local center_y = Constants.SCREEN_HEIGHT - 70
  local card_spacing = Constants.CARD_WIDTH
  local total_width = (#player.hand - 1) * card_spacing
  local start_x = center_x - total_width / 2

  -- Check cards in REVERSE order (rightmost/topmost first)
  for i = #player.hand, 1, -1 do
    local card = player.hand[i]
    local card_x = start_x + (i - 1) * card_spacing
    local card_y = center_y + (card.hover_offset_y or 0)

    if self:isPointInCard(x, y, card_x, card_y, CARD_SCALE) then
      print("Discarding card with animation:", card)
      self.game_controller:startDiscardAnimation(card)
      self:clearHover()  -- Clear hover when discarding
      return
    end
  end
end

function InputController:isPointInCard(px, py, card_x, card_y, scale)
  scale = scale or 1
  local half_w = (Constants.CARD_WIDTH * scale) / 2
  local half_h = (Constants.CARD_HEIGHT * scale) / 2

  return px >= card_x - half_w and px <= card_x + half_w and
         py >= card_y - half_h and py <= card_y + half_h
end

return InputController
