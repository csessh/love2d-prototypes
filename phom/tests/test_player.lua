#!/usr/bin/env lua
-- Test file for Player
-- Run from project root: cd phom && lua tests/test_player.lua

-- Set up paths to access parent modules
-- Works when run from project root or tests directory
package.path = package.path .. ";./?.lua;./?/init.lua;../?.lua;../?/init.lua"

-- Load modules or use mocks
local Card, Player, Constants

-- Try to load actual modules, fall back to mocks if needed
local function try_require(module_name)
  local success, result = pcall(require, module_name)
  return success and result or nil
end

Card = try_require("models/card")
Player = try_require("models/player")
Constants = try_require("utils/constants")

-- If modules aren't available, create minimal mocks for testing
if not Card then
  Card = {}
  Card.__index = Card
  function Card.new(suit, rank)
    return setmetatable({suit = suit, rank = rank, id = suit .. "_" .. rank}, Card)
  end
  function Card:getPointValue()
    return self.rank
  end
  function Card:getRankName()
    local names = {[1]="A", [2]="2", [3]="3", [4]="4", [5]="5", [6]="6",
                   [7]="7", [8]="8", [9]="9", [10]="10", [11]="J", [12]="Q", [13]="K"}
    return names[self.rank]
  end
  function Card:getSuitSymbol()
    local symbols = {hearts = "♥", diamonds = "♦", clubs = "♣", spades = "♠"}
    return symbols[self.suit]
  end
  function Card:__tostring()
    return self:getRankName() .. self:getSuitSymbol()
  end
end

if not Constants then
  Constants = {
    POSITIONS = {
      BOTTOM = "BOTTOM",
      LEFT = "LEFT",
      TOP = "TOP",
      RIGHT = "RIGHT"
    }
  }
end

if not Player then
  error("Player module not found. Make sure you're running from the project root.")
end

local tests_passed = 0
local tests_failed = 0

local function test(name, func)
  local success, err = pcall(func)
  if success then
    print("[PASS] " .. name)
    tests_passed = tests_passed + 1
  else
    print("[FAIL] " .. name .. ": " .. tostring(err))
    tests_failed = tests_failed + 1
  end
end

local function assert_true(condition, message)
  if not condition then
    error(message or "Assertion failed: expected true")
  end
end

local function assert_false(condition, message)
  if condition then
    error(message or "Assertion failed: expected false")
  end
end

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(message or ("Expected " .. tostring(expected) .. " but got " .. tostring(actual)))
  end
end

print("\n=== Player Tests ===\n")

-- Test player creation
test("Player creation: human player at bottom position", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  assert_equal(player.id, 1, "Player ID should be 1")
  assert_equal(player.type, "human", "Player type should be 'human'")
  assert_equal(player.position, Constants.POSITIONS.BOTTOM, "Player position should be BOTTOM")
  assert_equal(#player.hand, 0, "Initial hand should be empty")
  assert_equal(#player.hands, 0, "Initial hands should be empty")
  assert_equal(player.score, 0, "Initial score should be 0")
end)

test("Player creation: AI player at left position", function()
  local player = Player.new(2, "ai", Constants.POSITIONS.LEFT)
  assert_equal(player.id, 2, "Player ID should be 2")
  assert_equal(player.type, "ai", "Player type should be 'ai'")
  assert_equal(player.position, Constants.POSITIONS.LEFT, "Player position should be LEFT")
end)

-- Test adding cards to hand
test("addCardToHand: add single card", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  local card = Card.new("hearts", 7)

  player:add_card_to_hand(card)
  assert_equal(player:get_hand_size(), 1, "Hand size should be 1")
  assert_true(player:has_card(card), "Player should have the card")
end)

test("addCardToHand: add multiple cards", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  local card1 = Card.new("hearts", 7)
  local card2 = Card.new("spades", 10)
  local card3 = Card.new("diamonds", 1)

  player:add_card_to_hand(card1)
  player:add_card_to_hand(card2)
  player:add_card_to_hand(card3)

  assert_equal(player:get_hand_size(), 3, "Hand size should be 3")
  assert_true(player:has_card(card1), "Player should have card1")
  assert_true(player:has_card(card2), "Player should have card2")
  assert_true(player:has_card(card3), "Player should have card3")
end)

-- Test removing cards from hand
test("removeCardFromHand: remove existing card", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  local card = Card.new("hearts", 7)

  player:add_card_to_hand(card)
  local removed = player:remove_card_from_hand(card)

  assert_true(removed, "Should return true when card is removed")
  assert_equal(player:get_hand_size(), 0, "Hand should be empty after removal")
  assert_false(player:has_card(card), "Player should not have the card")
end)

test("removeCardFromHand: remove non-existing card", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  local card1 = Card.new("hearts", 7)
  local card2 = Card.new("spades", 10)

  player:add_card_to_hand(card1)
  local removed = player:remove_card_from_hand(card2)

  assert_false(removed, "Should return false when card doesn't exist")
  assert_equal(player:get_hand_size(), 1, "Hand size should remain 1")
end)

test("removeCardFromHand: remove from multiple cards", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  local card1 = Card.new("hearts", 7)
  local card2 = Card.new("spades", 10)
  local card3 = Card.new("diamonds", 1)

  player:add_card_to_hand(card1)
  player:add_card_to_hand(card2)
  player:add_card_to_hand(card3)

  player:remove_card_from_hand(card2)

  assert_equal(player:get_hand_size(), 2, "Hand size should be 2")
  assert_true(player:has_card(card1), "Player should still have card1")
  assert_false(player:has_card(card2), "Player should not have card2")
  assert_true(player:has_card(card3), "Player should still have card3")
end)

-- Test hasCard
test("hasCard: check for existing card", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  local card = Card.new("hearts", 7)

  player:add_card_to_hand(card)
  assert_true(player:has_card(card), "Should return true for existing card")
end)

test("hasCard: check for non-existing card", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  local card1 = Card.new("hearts", 7)
  local card2 = Card.new("spades", 10)

  player:add_card_to_hand(card1)
  assert_false(player:has_card(card2), "Should return false for non-existing card")
end)

-- Test hand size and empty checks
test("getHandSize: empty hand", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  assert_equal(player:get_hand_size(), 0, "Empty hand should have size 0")
end)

test("isHandEmpty: empty hand", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  assert_true(player:is_hand_empty(), "Should return true for empty hand")
end)

test("isHandEmpty: non-empty hand", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  player:add_card_to_hand(Card.new("hearts", 7))
  assert_false(player:is_hand_empty(), "Should return false for non-empty hand")
end)

-- Test score calculation
test("calculateScore: empty hand", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  local score = player:calculate_score()
  assert_equal(score, 0, "Empty hand should have score 0")
end)

test("calculateScore: single card", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  player:add_card_to_hand(Card.new("hearts", 7))  -- 7 points

  local score = player:calculate_score()
  assert_equal(score, 7, "Score should be 7")
end)

test("calculateScore: multiple cards", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  player:add_card_to_hand(Card.new("hearts", 1))   -- Ace = 1 point
  player:add_card_to_hand(Card.new("spades", 13))  -- King = 13 points
  player:add_card_to_hand(Card.new("diamonds", 5)) -- 5 = 5 points

  local score = player:calculate_score()
  assert_equal(score, 19, "Score should be 1 + 13 + 5 = 19")
end)

test("calculateScore: high value cards", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  player:add_card_to_hand(Card.new("hearts", 11))  -- Jack = 11 points
  player:add_card_to_hand(Card.new("spades", 12))  -- Queen = 12 points
  player:add_card_to_hand(Card.new("diamonds", 13)) -- King = 13 points

  local score = player:calculate_score()
  assert_equal(score, 36, "Score should be 11 + 12 + 13 = 36")
end)

-- Test forming hands
test("formHand: form set hand", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  local card1 = Card.new("hearts", 7)
  local card2 = Card.new("diamonds", 7)
  local card3 = Card.new("clubs", 7)

  player:add_card_to_hand(card1)
  player:add_card_to_hand(card2)

  -- Form hand with card3 as visible card
  player:form_hand("set", {card1, card2, card3}, card3)

  assert_equal(#player.hands, 1, "Should have 1 formed hand")
  assert_equal(player.hands[1].type, "set", "Hand type should be 'set'")
  assert_equal(#player.hands[1].cards, 3, "Hand should have 3 cards")
  assert_equal(player.hands[1].visible_card.id, card3.id, "Visible card should be card3")
  assert_equal(#player.hand_area_cards, 1, "Should have 1 card in hand area")
end)

test("formHand: removes cards from hand except visible card", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  local card1 = Card.new("hearts", 7)
  local card2 = Card.new("diamonds", 7)
  local card3 = Card.new("clubs", 7)

  player:add_card_to_hand(card1)
  player:add_card_to_hand(card2)

  -- Form hand with card3 as visible card (from discard)
  player:form_hand("set", {card1, card2, card3}, card3)

  assert_equal(player:get_hand_size(), 0, "Hand should be empty (card1 and card2 removed)")
  assert_false(player:has_card(card1), "Should not have card1 in hand")
  assert_false(player:has_card(card2), "Should not have card2 in hand")
end)

test("formHand: form sequence hand", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  local card1 = Card.new("hearts", 5)
  local card2 = Card.new("hearts", 6)
  local card3 = Card.new("hearts", 7)

  player:add_card_to_hand(card1)
  player:add_card_to_hand(card2)

  player:form_hand("sequence", {card1, card2, card3}, card3)

  assert_equal(#player.hands, 1, "Should have 1 formed hand")
  assert_equal(player.hands[1].type, "sequence", "Hand type should be 'sequence'")
end)

test("formHand: multiple hands", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)

  -- First hand (set)
  local card1 = Card.new("hearts", 7)
  local card2 = Card.new("diamonds", 7)
  local card3 = Card.new("clubs", 7)
  player:add_card_to_hand(card1)
  player:add_card_to_hand(card2)
  player:form_hand("set", {card1, card2, card3}, card3)

  -- Second hand (sequence)
  local card4 = Card.new("spades", 5)
  local card5 = Card.new("spades", 6)
  local card6 = Card.new("spades", 7)
  player:add_card_to_hand(card4)
  player:add_card_to_hand(card5)
  player:form_hand("sequence", {card4, card5, card6}, card6)

  assert_equal(#player.hands, 2, "Should have 2 formed hands")
  assert_equal(#player.hand_area_cards, 2, "Should have 2 cards in hand area")
  assert_equal(player.hands[1].type, "set", "First hand should be 'set'")
  assert_equal(player.hands[2].type, "sequence", "Second hand should be 'sequence'")
end)

-- Test integration scenarios
test("Integration: deal 9 cards and calculate score", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)

  -- Deal 9 cards (simulate dealing)
  for i = 1, 9 do
    player:add_card_to_hand(Card.new("hearts", i))
  end

  assert_equal(player:get_hand_size(), 9, "Should have 9 cards")

  -- Score should be 1+2+3+4+5+6+7+8+9 = 45
  local score = player:calculate_score()
  assert_equal(score, 45, "Score should be 45")
end)

test("Integration: form hand and check remaining score", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)

  -- Add cards to hand
  local card1 = Card.new("hearts", 7)  -- 7 points
  local card2 = Card.new("diamonds", 7) -- 7 points
  local card3 = Card.new("clubs", 7)    -- 7 points (from discard)
  local card4 = Card.new("spades", 10)  -- 10 points

  player:add_card_to_hand(card1)
  player:add_card_to_hand(card2)
  player:add_card_to_hand(card4)

  -- Initial score: 7 + 7 + 10 = 24
  assert_equal(player:calculate_score(), 24, "Initial score should be 24")

  -- Form hand (removes card1 and card2 from hand)
  player:form_hand("set", {card1, card2, card3}, card3)

  -- Remaining score: only card4 (10 points)
  assert_equal(player:calculate_score(), 10, "After forming hand, score should be 10")
  assert_equal(player:get_hand_size(), 1, "Should have 1 card left in hand")
end)

test("Integration: win condition - empty hand", function()
  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)

  player:add_card_to_hand(Card.new("hearts", 7))
  assert_false(player:is_hand_empty(), "Hand should not be empty")
  assert_true(player:calculate_score() > 0, "Score should be positive")

  player:remove_card_from_hand(player.hand[1])
  assert_true(player:is_hand_empty(), "Hand should be empty")
  assert_equal(player:calculate_score(), 0, "Score should be 0 when hand is empty")
end)

print("\n=== Test Results ===")
print("Passed: " .. tests_passed)
print("Failed: " .. tests_failed)
print("Total:  " .. (tests_passed + tests_failed))

if tests_failed == 0 then
  print("\nAll tests passed!")
  os.exit(0)
else
  print("\nSome tests failed!")
  os.exit(1)
end
