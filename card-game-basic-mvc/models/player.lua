local Player = {}
Player.__index = Player

function Player.new(id, player_type, position)
  local instance = {
    id = id,
    type = player_type,
    position = position,
    hand = {},
    hands = {},
    hand_area_cards = {},
    score = 0,
  }
  return setmetatable(instance, Player)
end

function Player:add_card_to_hand(card)
  table.insert(self.hand, card)
end

function Player:remove_card_from_hand(card)
  for i, c in ipairs(self.hand) do
    if c.id == card.id then
      table.remove(self.hand, i)
      return true
    end
  end
  return false
end

function Player:has_card(card)
  for _, c in ipairs(self.hand) do
    if c.id == card.id then
      return true
    end
  end

  return false
end

function Player:form_hand(hand_type, cards, visible_card)
  local hand_obj = {
    type = hand_type,
    cards = cards,
    visible_card = visible_card,
  }
  table.insert(self.hands, hand_obj)
  table.insert(self.hand_area_cards, visible_card)

  for _, card in ipairs(cards) do
    if card.id ~= visible_card.id then
      self:remove_card_from_hand(card)
    end
  end
end

function Player:calculate_score()
  if #self.hand == 0 then
    return 0
  end

  local score = 0
  for _, card in ipairs(self.hand) do
    score = score + card:get_point_value()
  end
  return score
end

function Player:get_hand_size()
  return #self.hand
end

function Player:is_hand_empty()
  return #self.hand == 0
end

return Player
