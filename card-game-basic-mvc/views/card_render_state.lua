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

function CardRenderState:get_state(card_id)
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

function CardRenderState:set_state(card_id, x, y, rotation, hover_offset_y, face_up)
  local state = self:get_state(card_id)
  if x then state.x = x end
  if y then state.y = y end
  if rotation then state.rotation = rotation end
  if hover_offset_y then state.hover_offset_y = hover_offset_y end
  if face_up ~= nil then state.face_up = face_up end
end

function CardRenderState:clear_state(card_id)
  self.render_states[card_id] = nil
end

function CardRenderState:clear_all()
  self.render_states = {}
end

return CardRenderState
