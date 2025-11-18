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
