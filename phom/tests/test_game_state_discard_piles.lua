local GameState = require("models/game_state")

print("=== GameState Discard Piles Tests ===\n")

local tests_passed = 0
local tests_failed = 0

local function assert_equal(actual, expected, test_name)
  if actual == expected then
    print("Test: " .. test_name .. "... PASS")
    tests_passed = tests_passed + 1
  else
    print("Test: " .. test_name .. "... FAIL")
    print("  Expected: " .. tostring(expected))
    print("  Got: " .. tostring(actual))
    tests_failed = tests_failed + 1
  end
end

-- Test 1: Discard piles initialized as empty tables
local game = GameState.new()
local has_discard_piles = game.discard_piles ~= nil
assert_equal(has_discard_piles, true, "GameState has discard_piles field")

-- Test 2: Each player gets empty discard pile after dealing
game:deal_cards(9)
local bottom_player = game.players[1]
local pile_exists = game.discard_piles[bottom_player.id] ~= nil
assert_equal(pile_exists, true, "Player discard pile initialized")

local pile_empty = #game.discard_piles[bottom_player.id] == 0
assert_equal(pile_empty, true, "Player discard pile starts empty")

local Card = require("models/card")

-- Test 3: add_to_discard adds card to specific player's pile
local test_card = Card.new("hearts", 5)
game:add_to_discard(bottom_player.id, test_card)
local pile_size = #game.discard_piles[bottom_player.id]
assert_equal(pile_size, 1, "add_to_discard increases pile size")

local added_card = game.discard_piles[bottom_player.id][1]
assert_equal(added_card.id, test_card.id, "add_to_discard adds correct card")

-- Test 4: get_cards_from_discard_pile returns pile array
local cards = game:get_cards_from_discard_pile(bottom_player.id)
assert_equal(#cards, 1, "get_cards_from_discard_pile returns correct count")
assert_equal(cards[1].id, test_card.id, "get_cards_from_discard_pile returns correct card")

-- Test 5: take_top_card_from_discard_pile removes and returns card
local taken_card = game:take_top_card_from_discard_pile(bottom_player.id)
assert_equal(taken_card.id, test_card.id, "take_top_card returns correct card")

local pile_after_take = game:get_cards_from_discard_pile(bottom_player.id)
assert_equal(#pile_after_take, 0, "take_top_card removes card from pile")

-- Test 6: take from empty pile returns nil
local from_empty = game:take_top_card_from_discard_pile(bottom_player.id)
assert_equal(from_empty, nil, "take from empty pile returns nil")

-- Test 7: get_previous_player returns correct player in sequence
game.current_player_index = 2  -- Second player
local prev_player = game:get_previous_player()
assert_equal(prev_player.id, game.players[1].id, "get_previous_player returns player 1 when current is 2")

-- Test 8: get_previous_player wraps around
game.current_player_index = 1  -- First player
prev_player = game:get_previous_player()
assert_equal(prev_player.id, game.players[4].id, "get_previous_player wraps to player 4 when current is 1")

-- Test 9: get_previous_player_discard_pile returns previous player's pile
local card_for_prev = Card.new("diamonds", 10)
game.current_player_index = 2
local prev = game:get_previous_player()
game:add_to_discard(prev.id, card_for_prev)

local prev_pile = game:get_previous_player_discard_pile()
assert_equal(#prev_pile, 1, "get_previous_player_discard_pile returns correct pile")
assert_equal(prev_pile[1].id, card_for_prev.id, "get_previous_player_discard_pile has correct card")

print("\n=== Test Summary ===")
print("Tests run: " .. (tests_passed + tests_failed))
print("Tests passed: " .. tests_passed)
print("Tests failed: " .. tests_failed)

if tests_failed == 0 then
  print("\nAll tests passed!")
else
  print("\nSome tests failed!")
  os.exit(1)
end
