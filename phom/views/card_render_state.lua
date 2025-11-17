-- Manages rendering state for cards (separate from card data model)
local CardRenderState = {}
CardRenderState.__index = CardRenderState

function CardRenderState.new()
  local instance = {
    -- Map card.id -> {x, y, rotation, hover_offset_y, face_up}
    render_states = {}
  }
  return setmetatable(instance, CardRenderState)
end

function CardRenderState:getState(card_id)
  if not self.render_states[card_id] then
    self.render_states[card_id] = {
      x = 0,
      y = 0,
      rotation = 0,
      hover_offset_y = 0,
      face_up = true
    }
  end
  return self.render_states[card_id]
end

function CardRenderState:setState(card_id, x, y, rotation, hover_offset_y, face_up)
  local state = self:getState(card_id)
  state.x = x or state.x
  state.y = y or state.y
  state.rotation = rotation or state.rotation
  state.hover_offset_y = hover_offset_y or state.hover_offset_y
  state.face_up = (face_up ~= nil) and face_up or state.face_up
end

function CardRenderState:clearState(card_id)
  self.render_states[card_id] = nil
end

function CardRenderState:clearAll()
  self.render_states = {}
end

return CardRenderState
