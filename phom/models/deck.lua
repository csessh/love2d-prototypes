local Constants = require("utils/constants")
local Card = require("models/card")

local Deck = {}
Deck.__index = Deck

function Deck.new()
  local instance = {
    cards = {},
  }
  setmetatable(instance, Deck)
  instance:initialize()
  return instance
end

function Deck:initialize()
  self.cards = {}
  for _, suit in ipairs(Constants.SUITS) do
    for _, rank in ipairs(Constants.RANKS) do
      table.insert(self.cards, Card.new(suit, rank))
    end
  end
end

function Deck:shuffle()
  for i = #self.cards, 2, -1 do
    local j = math.random(i)
    self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
  end
end

function Deck:draw()
  if #self.cards == 0 then
    return nil
  end
  return table.remove(self.cards, 1)
end

function Deck:size()
  return #self.cards
end

function Deck:isEmpty()
  return #self.cards == 0
end

return Deck
