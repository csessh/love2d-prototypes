local Constants = require("utils/constants")
local Deck = require("models/deck")
local Player = require("models/player")

local GameState = {}
GameState.__index = GameState

function GameState.new()
  local instance = {
    deck = Deck.new(),
    discard_pile = {},
    players = {},
    current_player_index = math.random(1, 4),  -- Random starting player
    current_state = Constants.STATES.MENU,
    turn_substep = nil,
    selected_cards = {},
    round_number = 1,
    scores = {}
  }
  setmetatable(instance, GameState)
  instance:initializePlayers()
  return instance
end

function GameState:initializePlayers()
  self.players = {
    Player.new(1, "human", Constants.POSITIONS.BOTTOM),
    Player.new(2, "ai", Constants.POSITIONS.LEFT),
    Player.new(3, "ai", Constants.POSITIONS.TOP),
    Player.new(4, "ai", Constants.POSITIONS.RIGHT)
  }
end

function GameState:getCurrentPlayer()
  return self.players[self.current_player_index]
end

function GameState:nextPlayer()
  self.current_player_index = self.current_player_index % 4 + 1
end

function GameState:getTopDiscard()
  if #self.discard_pile == 0 then
    return nil
  end
  return self.discard_pile[#self.discard_pile]
end

function GameState:addToDiscard(card)
  table.insert(self.discard_pile, card)
end

function GameState:takeFromDiscard()
  if #self.discard_pile == 0 then
    return nil
  end
  return table.remove(self.discard_pile)
end

function GameState:isDeckEmpty()
  return self.deck:isEmpty()
end

function GameState:dealCards(cards_per_player)
  self.deck:shuffle()

  for i = 1, cards_per_player do
    for _, player in ipairs(self.players) do
      local card = self.deck:draw()
      if card then
        player:addCardToHand(card)
      end
    end
  end
end

function GameState:checkWinCondition()
  for _, player in ipairs(self.players) do
    if player:isHandEmpty() then
      return player
    end
  end
  return nil
end

function GameState:calculateAllScores()
  for _, player in ipairs(self.players) do
    self.scores[player.id] = player:calculateScore()
  end
end

return GameState
