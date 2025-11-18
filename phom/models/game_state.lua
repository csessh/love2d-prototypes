local Constants = require("utils/constants")
local Deck = require("models/deck")
local Player = require("models/player")

local GameState = {}
GameState.__index = GameState

function GameState.new()
  local instance = {
    current_player_index = math.random(1, Constants.MAX_PLAYER_COUNT),
    current_state = Constants.STATES.MENU,
    deck = Deck.new(),
    discard_piles = {},  -- Per-player discard piles
    players = {},
    round_number = 1,
    scores = {},
    selected_cards = {},
    turn_substep = nil,
  }
  setmetatable(instance, GameState)
  instance:initialize_players()
  return instance
end

function GameState:initialize_players()
  self.players = {
    Player.new(1, "human", Constants.POSITIONS.BOTTOM),
    Player.new(2, "ai", Constants.POSITIONS.LEFT),
    Player.new(3, "ai", Constants.POSITIONS.TOP),
    Player.new(4, "ai", Constants.POSITIONS.RIGHT),
  }
end

function GameState:get_current_player()
  return self.players[self.current_player_index]
end

function GameState:next_player()
  self.current_player_index = self.current_player_index
      % Constants.MAX_PLAYER_COUNT
    + 1
end

function GameState:get_previous_player()
  local prev_index = self.current_player_index - 1
  if prev_index < 1 then
    prev_index = #self.players  -- Wrap to last player
  end
  return self.players[prev_index]
end


function GameState:is_deck_empty()
  return self.deck:is_empty()
end

function GameState:deal_cards(cards_per_player)
  self.deck:shuffle()

  for _ = 1, cards_per_player do
    for _, player in ipairs(self.players) do
      local card = self.deck:draw()
      if card then
        player:add_card_to_hand(card)
      end
    end
  end

  -- Initialize empty discard pile for each player
  for _, player in ipairs(self.players) do
    self.discard_piles[player.id] = {}
  end
end

function GameState:check_win_condition()
  for _, player in ipairs(self.players) do
    if player:is_hand_empty() then
      return player
    end
  end
  return nil
end

function GameState:calculate_all_scores()
  for _, player in ipairs(self.players) do
    self.scores[player.id] = player:calculate_score()
  end
end

function GameState:add_to_discard(player_id, card)
  if not self.discard_piles[player_id] then
    self.discard_piles[player_id] = {}
  end
  table.insert(self.discard_piles[player_id], card)
end

function GameState:get_cards_from_discard_pile(player_id)
  return self.discard_piles[player_id] or {}
end

function GameState:take_top_card_from_discard_pile(player_id)
  local pile = self.discard_piles[player_id]
  if not pile or #pile == 0 then
    return nil
  end
  return table.remove(pile)  -- Removes last element and returns it
end

function GameState:get_previous_player_discard_pile()
  local prev_player = self:get_previous_player()
  return self:get_cards_from_discard_pile(prev_player.id)
end

return GameState
