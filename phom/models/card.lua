local Constants = require("utils/constants")

local Card = {}
Card.__index = Card

function Card.new(suit, rank)
  local instance = {
    suit = suit,
    rank = rank,
    id = suit .. "_" .. rank,
  }
  return setmetatable(instance, Card)
end

function Card:getPointValue()
  return Constants.CARD_POINTS[self.rank]
end

function Card:getRankName()
  return Constants.RANK_NAMES[self.rank]
end

function Card:getSuitSymbol()
  return Constants.SUIT_SYMBOLS[self.suit]
end

function Card:__tostring()
  return self:getRankName() .. self:getSuitSymbol()
end

return Card
