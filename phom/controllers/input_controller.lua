local Constants = require("utils/constants")
local Flux = require("libraries/flux")

local InputController = {}
InputController.__index = InputController

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
  self:update_hover()
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

  if self.game_controller.animating then
    print("BLOCKED: Animation flag is true")
    return
  end

  if game_state.turn_substep == Constants.TURN_SUBSTEPS.ANIMATING_DISCARD then
    print("BLOCKED: Animation substep active")
    return
  end

  if game_state.turn_substep == Constants.TURN_SUBSTEPS.ANIMATING_DRAW then
    print("BLOCKED: Animation substep active")
    return
  end

  if game_state.current_state == Constants.STATES.PLAYER_TURN then
    if game_state.turn_substep == Constants.TURN_SUBSTEPS.CHOOSE_ACTION then
      print("Calling handle_choose_action")
      self:handle_choose_action(x, y)
    elseif game_state.turn_substep == Constants.TURN_SUBSTEPS.DISCARD_PHASE then
      print("Calling handle_discard_phase")
      self:handle_discard_phase(x, y)
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

function InputController:update_hover()
  local game_state = self.game_controller.game_state

  if self.game_controller.animating then
    self:clear_hover()
    return
  end

  if game_state.turn_substep == Constants.TURN_SUBSTEPS.ANIMATING_DRAW then
    self:clear_hover()
    return
  end

  if game_state.turn_substep == Constants.TURN_SUBSTEPS.ANIMATING_DISCARD then
    self:clear_hover()
    return
  end

  if game_state.current_state ~= Constants.STATES.PLAYER_TURN then
    self:clear_hover()
    return
  end

  local player = game_state:get_current_player()
  if player.type ~= "human" then
    self:clear_hover()
    return
  end

  -- Calculate card positions (must match GameView:drawBottomPlayer)
  local center_x = Constants.SCREEN_WIDTH / 2
  local center_y = Constants.SCREEN_HEIGHT - 70
  local total_width = (#player.hand - 1) * Constants.CARD_WIDTH
  local start_x = center_x - total_width / 2

  -- Find which card (if any) is being hovered
  -- Check cards in REVERSE order (rightmost/topmost first)
  local new_hovered_index = nil
  for i = #player.hand, 1, -1 do
    local card = player.hand[i]
    local x = start_x + (i - 1) * Constants.CARD_WIDTH
    local y = center_y + (card.hover_offset_y or 0)

    if
      self:is_point_in_card(self.mouse_x, self.mouse_y, x, y, Constants.CARD_SCALE)
    then
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
        Flux.to(prev_card, 0.1, { hover_offset_y = 0 })
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
      local hover_offset = -(
        Constants.CARD_HEIGHT
        * Constants.CARD_SCALE
        * 0.15
      )
      Flux.to(card, 0.1, { hover_offset_y = hover_offset })
    end
  end
end

function InputController:clear_hover()
  if self.hovered_card_index then
    local game_state = self.game_controller.game_state
    local player = game_state:get_current_player()
    if player and player.hand[self.hovered_card_index] then
      local card = player.hand[self.hovered_card_index]
      if card.hover_offset_y then
        Flux.to(card, 0.1, { hover_offset_y = 0 })
      end
    end
    self.hovered_card_index = nil
  end
end

function InputController:handle_choose_action(x, y)
  local game_state = self.game_controller.game_state

  if
    self:is_point_in_card(
      x,
      y,
      Constants.DECK_X,
      Constants.DECK_Y,
      Constants.CARD_SCALE
    ) and not game_state:is_deck_empty()
  then
    print("Clicked deck - drawing card")
    self.game_controller:draw_card()
    return
  end

  -- TODO: Handle clicking on hand cards for meld formation
end

function InputController:handle_discard_phase(x, y)
  local game_state = self.game_controller.game_state
  local player = game_state:get_current_player()

  -- Calculate card positions (must match GameView:draw_bottom_player)
  local center_x = Constants.SCREEN_WIDTH / 2
  local center_y = Constants.SCREEN_HEIGHT - 70
  local total_width = (#player.hand - 1) * Constants.CARD_WIDTH
  local start_x = center_x - total_width / 2

  -- Check cards in REVERSE order (rightmost/topmost first)
  for i = #player.hand, 1, -1 do
    local card = player.hand[i]
    local card_x = start_x + (i - 1) * Constants.CARD_WIDTH
    local card_y = center_y + (card.hover_offset_y or 0)

    if self:is_point_in_card(x, y, card_x, card_y, Constants.CARD_SCALE) then
      print("Discarding card with animation:", card)
      self.game_controller:start_discard_animation(card)
      self:clear_hover() -- Clear hover when discarding
      return
    end
  end
end

function InputController:is_point_in_card(px, py, card_x, card_y, scale)
  scale = scale or 1
  local half_w = (Constants.CARD_WIDTH * scale) / 2
  local half_h = (Constants.CARD_HEIGHT * scale) / 2

  return px >= card_x - half_w
    and px <= card_x + half_w
    and py >= card_y - half_h
    and py <= card_y + half_h
end

return InputController
