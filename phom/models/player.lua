local Constants = require("utils/constants")

local Player = {}
Player.__index = Player

function Player.new(id, player_type, position)
  local instance = {
    id = id,
    type = player_type, -- "human" or "ai"
    position = position, -- "BOTTOM", "LEFT", "TOP", "RIGHT"
    hand = {},
    hands = {}, -- {type="set"|"sequence", cards={}, visible_card=Card}
    hand_area_cards = {}, -- face-up discard cards taken
    score = 0,
  }
  return setmetatable(instance, Player)
end

function Player:addCardToHand(card)
  table.insert(self.hand, card)
end

function Player:removeCardFromHand(card)
  for i, c in ipairs(self.hand) do
    if c.id == card.id then
      table.remove(self.hand, i)
      return true
    end
  end
  return false
end

function Player:hasCard(card)
  for _, c in ipairs(self.hand) do
    if c.id == card.id then
      return true
    end
  end
  return false
end

function Player:formHand(hand_type, cards, visible_card)
  local hand_obj = {
    type = hand_type,
    cards = cards,
    visible_card = visible_card,
  }
  table.insert(self.hands, hand_obj)
  table.insert(self.hand_area_cards, visible_card)

  -- Remove hand cards from hand (except visible card already removed)
  for _, card in ipairs(cards) do
    if card.id ~= visible_card.id then
      self:removeCardFromHand(card)
    end
  end
end

function Player:calculateScore()
  if #self.hand == 0 then
    return 0
  end

  local score = 0
  for _, card in ipairs(self.hand) do
    score = score + card:getPointValue()
  end
  return score
end

function Player:getHandSize()
  return #self.hand
end

function Player:isHandEmpty()
  return #self.hand == 0
end

return Player
