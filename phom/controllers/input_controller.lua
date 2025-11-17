local Constants = require("utils/constants")
local Flux = require("libraries/flux")
local LayoutCalculator = require("utils/layout_calculator")

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

  if self.game_controller.animating then
    self:clearHover()
    return
  end

  if game_state.turn_substep == Constants.TURN_SUBSTEPS.ANIMATING_DRAW then
    self:clearHover()
    return
  end

  if game_state.turn_substep == Constants.TURN_SUBSTEPS.ANIMATING_DISCARD then
    self:clearHover()
    return
  end

  if game_state.current_state ~= Constants.STATES.PLAYER_TURN then
    self:clearHover()
    return
  end

  local player = game_state:getCurrentPlayer()
  if player.type ~= "human" then
    self:clearHover()
    return
  end

  -- Use LayoutCalculator for positions
  local positions = LayoutCalculator.calculateHandPositions(player, Constants.CARD_SCALE)
  local card_render_state = self.game_controller.card_render_state

  -- Find which card (if any) is being hovered
  -- Check cards in REVERSE order (rightmost/topmost first)
  local new_hovered_index = nil
  for i = #player.hand, 1, -1 do
    local card = player.hand[i]
    local pos = positions[card.id]
    if pos then
      local render_state = card_render_state:getState(card.id)
      local y = pos.y + (render_state.hover_offset_y or 0)

      if LayoutCalculator.isPointInCard(self.mouse_x, self.mouse_y, pos.x, y, Constants.CARD_SCALE) then
        new_hovered_index = i
        break
      end
    end
  end

  -- Handle hover state changes
  if new_hovered_index ~= self.hovered_card_index then
    -- Clear previous hover
    if self.hovered_card_index then
      local prev_card = player.hand[self.hovered_card_index]
      if prev_card then
        local prev_render_state = card_render_state:getState(prev_card.id)
        if prev_render_state.hover_offset_y then
          Flux.to(prev_render_state, 0.1, { hover_offset_y = 0 })
        end
      end
    end

    -- Set new hover
    self.hovered_card_index = new_hovered_index
    if new_hovered_index then
      local card = player.hand[new_hovered_index]
      local render_state = card_render_state:getState(card.id)
      if not render_state.hover_offset_y then
        render_state.hover_offset_y = 0
      end
      local hover_offset = -(Constants.CARD_HEIGHT * Constants.CARD_SCALE * 0.15)
      Flux.to(render_state, 0.1, { hover_offset_y = hover_offset })
    end
  end
end

function InputController:clearHover()
  if self.hovered_card_index then
    local game_state = self.game_controller.game_state
    local player = game_state:getCurrentPlayer()
    if player and player.hand[self.hovered_card_index] then
      local card = player.hand[self.hovered_card_index]
      local render_state = self.game_controller.card_render_state:getState(card.id)
      if render_state.hover_offset_y then
        Flux.to(render_state, 0.1, { hover_offset_y = 0 })
      end
    end
    self.hovered_card_index = nil
  end
end

function InputController:handleChooseAction(x, y)
  local game_state = self.game_controller.game_state

  if
    LayoutCalculator.isPointInCard(x, y, Constants.DECK_X, Constants.DECK_Y, Constants.CARD_SCALE)
    and not game_state:isDeckEmpty()
  then
    print("Clicked deck - drawing card")
    self.game_controller:drawCard()
    return
  end

  -- TODO: Handle clicking on hand cards for meld formation
end

function InputController:handleDiscardPhase(x, y)
  local game_state = self.game_controller.game_state
  local player = game_state:getCurrentPlayer()

  -- Use LayoutCalculator for positions
  local positions = LayoutCalculator.calculateHandPositions(player, Constants.CARD_SCALE)
  local card_render_state = self.game_controller.card_render_state

  -- Check cards in REVERSE order (rightmost/topmost first)
  for i = #player.hand, 1, -1 do
    local card = player.hand[i]
    local pos = positions[card.id]
    if pos then
      local render_state = card_render_state:getState(card.id)
      local card_y = pos.y + (render_state.hover_offset_y or 0)

      if LayoutCalculator.isPointInCard(x, y, pos.x, card_y, Constants.CARD_SCALE) then
        print("Discarding card with animation:", card)
        self.game_controller:startDiscardAnimation(card)
        self:clearHover() -- Clear hover when discarding
        return
      end
    end
  end
end

return InputController
