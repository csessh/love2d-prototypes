#!/usr/bin/env lua
-- Test file for MeldValidator
-- Run from project root: cd phom && lua tests/test_meld_validator.lua

-- Set up paths to access parent modules
-- Works when run from project root or tests directory
package.path = package.path .. ";./?.lua;./?/init.lua;../?.lua;../?/init.lua"

-- Load modules or use mocks
local Card, MeldValidator

-- Try to load actual modules, fall back to mocks if needed
local function try_require(module_name)
  local success, result = pcall(require, module_name)
  return success and result or nil
end

Card = try_require("models/card")
MeldValidator = try_require("models/meld_validator")

-- If modules aren't available, create minimal mocks for testing
if not Card then
  Card = {}
  Card.__index = Card
  function Card.new(suit, rank)
    return setmetatable({suit = suit, rank = rank, id = suit .. "_" .. rank}, Card)
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

if not MeldValidator then
  error("MeldValidator module not found. Make sure you're running from the project root.")
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

print("\n=== MeldValidator Tests ===\n")

-- Test valid sets
test("Valid set: 3 cards same rank, different suits", function()
  local set = {
    Card.new("hearts", 7),
    Card.new("diamonds", 7),
    Card.new("clubs", 7)
  }
  assert_true(MeldValidator.isValidSet(set), "Should be valid set")
end)

test("Valid set: 4 cards same rank, all different suits", function()
  local set = {
    Card.new("hearts", 10),
    Card.new("diamonds", 10),
    Card.new("clubs", 10),
    Card.new("spades", 10)
  }
  assert_true(MeldValidator.isValidSet(set), "Should be valid set")
end)

-- Test invalid sets
test("Invalid set: only 2 cards", function()
  local set = {
    Card.new("hearts", 5),
    Card.new("diamonds", 5)
  }
  assert_false(MeldValidator.isValidSet(set), "Should not be valid set (too few cards)")
end)

test("Invalid set: different ranks", function()
  local set = {
    Card.new("hearts", 7),
    Card.new("diamonds", 8),
    Card.new("clubs", 7)
  }
  assert_false(MeldValidator.isValidSet(set), "Should not be valid set (different ranks)")
end)

-- Test valid sequences
test("Valid sequence: A-2-3 (Ace as low)", function()
  local seq = {
    Card.new("hearts", 1),  -- Ace
    Card.new("hearts", 2),
    Card.new("hearts", 3)
  }
  assert_true(MeldValidator.isValidSequence(seq), "Should be valid sequence (A-2-3)")
end)

test("Valid sequence: 5-6-7-8", function()
  local seq = {
    Card.new("spades", 5),
    Card.new("spades", 6),
    Card.new("spades", 7),
    Card.new("spades", 8)
  }
  assert_true(MeldValidator.isValidSequence(seq), "Should be valid sequence")
end)

test("Valid sequence: J-Q-K (11-12-13)", function()
  local seq = {
    Card.new("diamonds", 11),  -- Jack
    Card.new("diamonds", 12),  -- Queen
    Card.new("diamonds", 13)   -- King
  }
  assert_true(MeldValidator.isValidSequence(seq), "Should be valid sequence (J-Q-K)")
end)

test("Valid sequence: unsorted input order", function()
  local seq = {
    Card.new("clubs", 7),
    Card.new("clubs", 5),
    Card.new("clubs", 6)
  }
  assert_true(MeldValidator.isValidSequence(seq), "Should be valid sequence (unsorted input)")
end)

-- Test invalid sequences
test("Invalid sequence: K-A-2 (wrap around)", function()
  local seq = {
    Card.new("hearts", 13),  -- King
    Card.new("hearts", 1),   -- Ace
    Card.new("hearts", 2)
  }
  assert_false(MeldValidator.isValidSequence(seq), "Should not be valid (no wrap-around K-A-2)")
end)

test("Invalid sequence: Q-K-A (wrap around)", function()
  local seq = {
    Card.new("spades", 12),  -- Queen
    Card.new("spades", 13),  -- King
    Card.new("spades", 1)    -- Ace
  }
  assert_false(MeldValidator.isValidSequence(seq), "Should not be valid (no wrap-around Q-K-A)")
end)

test("Invalid sequence: different suits", function()
  local seq = {
    Card.new("hearts", 5),
    Card.new("diamonds", 6),  -- Different suit
    Card.new("hearts", 7)
  }
  assert_false(MeldValidator.isValidSequence(seq), "Should not be valid (different suits)")
end)

test("Invalid sequence: only 2 cards", function()
  local seq = {
    Card.new("clubs", 8),
    Card.new("clubs", 9)
  }
  assert_false(MeldValidator.isValidSequence(seq), "Should not be valid (too few cards)")
end)

test("Invalid sequence: non-consecutive ranks", function()
  local seq = {
    Card.new("hearts", 3),
    Card.new("hearts", 5),  -- Skips 4
    Card.new("hearts", 6)
  }
  assert_false(MeldValidator.isValidSequence(seq), "Should not be valid (non-consecutive)")
end)

-- Test canFormMeld
test("canFormMeld: valid set with discard", function()
  local hand = {
    Card.new("diamonds", 9),
    Card.new("clubs", 9)
  }
  local discard = Card.new("hearts", 9)
  assert_true(MeldValidator.canFormMeld(hand, discard), "Should form valid set")
end)

test("canFormMeld: valid sequence with discard", function()
  local hand = {
    Card.new("spades", 4),
    Card.new("spades", 5)
  }
  local discard = Card.new("spades", 6)
  assert_true(MeldValidator.canFormMeld(hand, discard), "Should form valid sequence")
end)

test("canFormMeld: invalid - only 1 hand card", function()
  local hand = {
    Card.new("hearts", 7)
  }
  local discard = Card.new("diamonds", 7)
  assert_false(MeldValidator.canFormMeld(hand, discard), "Should not form meld (need 2+ hand cards)")
end)

test("canFormMeld: invalid - no discard card", function()
  local hand = {
    Card.new("hearts", 7),
    Card.new("diamonds", 7)
  }
  local discard = nil
  assert_false(MeldValidator.canFormMeld(hand, discard), "Should not form meld (no discard)")
end)

test("canFormMeld: invalid - cards don't form meld", function()
  local hand = {
    Card.new("hearts", 3),
    Card.new("diamonds", 5)
  }
  local discard = Card.new("spades", 8)
  assert_false(MeldValidator.canFormMeld(hand, discard), "Should not form meld (unrelated cards)")
end)

-- Test validateMeldSelection
test("validateMeldSelection: returns 'set' for valid set", function()
  local hand = {
    Card.new("hearts", 6),
    Card.new("clubs", 6)
  }
  local discard = Card.new("spades", 6)
  local result = MeldValidator.validateMeldSelection(hand, discard)
  assert_true(result == "set", "Should return 'set' for valid set, got: " .. tostring(result))
end)

test("validateMeldSelection: returns 'sequence' for valid sequence", function()
  local hand = {
    Card.new("diamonds", 2),
    Card.new("diamonds", 3)
  }
  local discard = Card.new("diamonds", 4)
  local result = MeldValidator.validateMeldSelection(hand, discard)
  assert_true(result == "sequence", "Should return 'sequence' for valid sequence, got: " .. tostring(result))
end)

test("validateMeldSelection: returns nil for invalid meld", function()
  local hand = {
    Card.new("hearts", 2),
    Card.new("clubs", 5)
  }
  local discard = Card.new("spades", 9)
  local result = MeldValidator.validateMeldSelection(hand, discard)
  assert_true(result == nil, "Should return nil for invalid meld, got: " .. tostring(result))
end)

-- Edge cases
test("Edge case: Ace-low sequence A-2-3-4-5", function()
  local seq = {
    Card.new("hearts", 1),
    Card.new("hearts", 2),
    Card.new("hearts", 3),
    Card.new("hearts", 4),
    Card.new("hearts", 5)
  }
  assert_true(MeldValidator.isValidSequence(seq), "Should be valid (Ace-low long sequence)")
end)

test("Edge case: Cannot wrap 13-1 (K-A)", function()
  local seq = {
    Card.new("clubs", 13),
    Card.new("clubs", 1)
  }
  assert_false(MeldValidator.isValidSequence(seq), "Should not be valid (K-A wrap)")
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
