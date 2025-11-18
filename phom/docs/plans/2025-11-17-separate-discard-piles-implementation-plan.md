# Separate Discard Piles Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace single shared discard pile with per-player discard piles with horizontal spreading and previous-player interaction.

**Architecture:** GameState-managed approach - discard piles stored in GameState indexed by player.id, keeping Player models clean. LayoutCalculator handles position calculations for spreading. Views render per-player piles, Controller handles animations and input.

**Tech Stack:** Lua, LÖVE2D, Flux (animation), existing MVC architecture

**Design Reference:** `docs/plans/2025-11-17-separate-discard-piles-design.md`

---

## Prerequisites

**Current state:**
- Branch: `feature/separate-discard-piles`
- MVC refactoring complete

**Progress (Updated 2025-11-19):**
- ✅ Tasks 1-6 COMPLETE
- ✅ Code review COMPLETE - All critical issues resolved
- 🔄 Ready to proceed with Tasks 7-11

**Note on snake_case:**
The design specifies converting all methods to snake_case, but this is a **breaking change** affecting many files. For this implementation:
- New methods use snake_case (as designed)
- Existing methods keep camelCase (avoid massive refactor)
- TODO: Create separate task for full snake_case conversion

---

## Task 1: Add Constants for Discard Piles

**Files:**
- Modify: `utils/constants.lua`

**Step 1: Add discard pile constants**

Add after line 91 (after `Constants.ANIM_MELD_DURATION_S`):

```lua
-- Discard pile configuration
Constants.DISCARD_OVERLAP_OFFSET = 30  -- Horizontal spacing between cards in pile

-- Discard pile anchor positions (base position for each player's pile)
Constants.DISCARD_PILE_POSITIONS = {
  BOTTOM = { x = 640, y = 420 },  -- Above player hand
  TOP = { x = 640, y = 300 },     -- Below player cards
  LEFT = { x = 400, y = 360 },    -- Right of player hand
  RIGHT = { x = 880, y = 360 }    -- Left of player hand
}
```

**Step 2: Verify constants**

Run the game to ensure no syntax errors:
```bash
love .
```

Expected: Game starts without errors

**Step 3: Commit**

```bash
git add utils/constants.lua
git commit -m "feat: add constants for separate discard piles

- Add DISCARD_OVERLAP_OFFSET for card spacing (30px)
- Add DISCARD_PILE_POSITIONS for anchor points per player

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 2: Add GameState Discard Pile Methods (Part 1 - Data Structure)

**Files:**
- Modify: `models/game_state.lua`
- Create: `tests/test_game_state_discard_piles.lua`

**Step 1: Write failing test for discard pile initialization**

Create `tests/test_game_state_discard_piles.lua`:

```lua
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
game:dealCards(9)
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
```

**Step 2: Run test to verify it fails**

```bash
lua tests/test_game_state_discard_piles.lua
```

Expected: FAIL - "discard_piles" field doesn't exist

**Step 3: Add discard_piles to GameState.new()**

In `models/game_state.lua`, modify `GameState.new()` (around line 8):

```lua
function GameState.new()
  local instance = {
    players = {},
    deck = Deck.new(),
    discard_pile = {},  -- Keep for backwards compat (initial card)
    discard_piles = {},  -- NEW: Per-player discard piles
    current_player_index = 1,
    current_state = Constants.STATES.MENU,
    turn_substep = nil,
    round_number = 1,
    scores = {}
  }

  -- ... rest of initialization
```

**Step 4: Initialize discard piles in dealCards()**

In `models/game_state.lua`, add to `GameState:dealCards()` after players are created (around line 30):

```lua
function GameState:dealCards(cards_per_player)
  self.deck:shuffle()

  for _, player in ipairs(self.players) do
    for i = 1, cards_per_player do
      local card = self.deck:draw()
      if card then
        player:addCardToHand(card)
      end
    end

    -- Initialize empty discard pile for each player
    self.discard_piles[player.id] = {}
  end
end
```

**Step 5: Run test to verify it passes**

```bash
lua tests/test_game_state_discard_piles.lua
```

Expected: PASS (3 tests)

**Step 6: Commit**

```bash
git add models/game_state.lua tests/test_game_state_discard_piles.lua
git commit -m "feat: add discard_piles data structure to GameState

- Add discard_piles table to GameState.new()
- Initialize empty pile per player in dealCards()
- Add tests for initialization

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 3: Add GameState Discard Pile Methods (Part 2 - API)

**Files:**
- Modify: `models/game_state.lua`
- Modify: `tests/test_game_state_discard_piles.lua`

**Step 1: Write failing tests for add/get/take methods**

Add to `tests/test_game_state_discard_piles.lua` before the summary:

```lua
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
```

**Step 2: Run test to verify it fails**

```bash
lua tests/test_game_state_discard_piles.lua
```

Expected: FAIL - methods don't exist

**Step 3: Implement add_to_discard**

Add to `models/game_state.lua` at end of file (before `return GameState`):

```lua
function GameState:add_to_discard(player_id, card)
  if not self.discard_piles[player_id] then
    self.discard_piles[player_id] = {}
  end
  table.insert(self.discard_piles[player_id], card)
end
```

**Step 4: Implement get_cards_from_discard_pile**

```lua
function GameState:get_cards_from_discard_pile(player_id)
  return self.discard_piles[player_id] or {}
end
```

**Step 5: Implement take_top_card_from_discard_pile**

```lua
function GameState:take_top_card_from_discard_pile(player_id)
  local pile = self.discard_piles[player_id]
  if not pile or #pile == 0 then
    return nil
  end
  return table.remove(pile)  -- Removes last element and returns it
end
```

**Step 6: Run test to verify it passes**

```bash
lua tests/test_game_state_discard_piles.lua
```

Expected: PASS (9 tests)

**Step 7: Commit**

```bash
git add models/game_state.lua tests/test_game_state_discard_piles.lua
git commit -m "feat: add GameState methods for per-player discard piles

- add_to_discard(player_id, card): Add card to player's pile
- get_cards_from_discard_pile(player_id): Get all cards in pile
- take_top_card_from_discard_pile(player_id): Remove and return top card
- Add tests for all methods

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 4: Add Helper Methods for Previous Player

**Files:**
- Modify: `models/game_state.lua`
- Modify: `tests/test_game_state_discard_piles.lua`

**Step 1: Write failing test for get_previous_player**

Add to `tests/test_game_state_discard_piles.lua`:

```lua
-- Test 7: get_previous_player returns correct player in sequence
game.current_player_index = 2  -- Second player
local prev_player = game:get_previous_player()
assert_equal(prev_player.id, game.players[1].id, "get_previous_player returns player 1 when current is 2")

-- Test 8: get_previous_player wraps around
game.current_player_index = 1  -- First player
prev_player = game:get_previous_player()
assert_equal(prev_player.id, game.players[4].id, "get_previous_player wraps to player 4 when current is 1")
```

**Step 2: Run test to verify it fails**

```bash
lua tests/test_game_state_discard_piles.lua
```

Expected: FAIL - method doesn't exist

**Step 3: Implement get_previous_player**

Add to `models/game_state.lua`:

```lua
function GameState:get_previous_player()
  local prev_index = self.current_player_index - 1
  if prev_index < 1 then
    prev_index = #self.players  -- Wrap to last player
  end
  return self.players[prev_index]
end
```

**Step 4: Write test for get_previous_player_discard_pile**

Add to test file:

```lua
-- Test 9: get_previous_player_discard_pile returns previous player's pile
local card_for_prev = Card.new("diamonds", 10)
game.current_player_index = 2
local prev = game:get_previous_player()
game:add_to_discard(prev.id, card_for_prev)

local prev_pile = game:get_previous_player_discard_pile()
assert_equal(#prev_pile, 1, "get_previous_player_discard_pile returns correct pile")
assert_equal(prev_pile[1].id, card_for_prev.id, "get_previous_player_discard_pile has correct card")
```

**Step 5: Implement get_previous_player_discard_pile**

Add to `models/game_state.lua`:

```lua
function GameState:get_previous_player_discard_pile()
  local prev_player = self:get_previous_player()
  return self:get_cards_from_discard_pile(prev_player.id)
end
```

**Step 6: Run test to verify it passes**

```bash
lua tests/test_game_state_discard_piles.lua
```

Expected: PASS (12 tests)

**Step 7: Commit**

```bash
git add models/game_state.lua tests/test_game_state_discard_piles.lua
git commit -m "feat: add helper methods for previous player's discard pile

- get_previous_player(): Get player before current in turn order
- get_previous_player_discard_pile(): Get previous player's pile
- Handle wraparound (player 1's previous is player 4)
- Add tests for wraparound logic

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 5: Add LayoutCalculator Method for Discard Pile Spreading

**Files:**
- Modify: `utils/layout_calculator.lua`

**Step 1: Add calculate_discard_pile_positions function**

Add to end of `utils/layout_calculator.lua` (before `return LayoutCalculator`):

```lua
-- Calculate positions for cards in a discard pile with horizontal spreading
-- Returns: table mapping card.id -> {x, y, rotation, z_index}
function LayoutCalculator.calculate_discard_pile_positions(cards, base_x, base_y, rotation, card_scale)
  card_scale = card_scale or 1
  rotation = rotation or 0

  local positions = {}
  local overlap_offset = Constants.DISCARD_OVERLAP_OFFSET

  for i, card in ipairs(cards) do
    local is_top_card = (i == #cards)
    positions[card.id] = {
      x = base_x + (i - 1) * overlap_offset,
      y = base_y,
      rotation = rotation,
      z_index = i,  -- Higher index = rendered on top
      fully_visible = is_top_card
    }
  end

  return positions
end
```

**Step 2: Manual verification**

Run game to ensure no syntax errors:

```bash
love .
```

Expected: Game starts without errors

**Step 3: Commit**

```bash
git add utils/layout_calculator.lua
git commit -m "feat: add discard pile position calculation to LayoutCalculator

- calculate_discard_pile_positions(): Spread cards horizontally
- Returns positions with z_index for rendering order
- Uses DISCARD_OVERLAP_OFFSET constant for spacing

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 6: Add GameView Method to Render Discard Piles

**Files:**
- Modify: `views/game_view.lua`

**Step 1: Add get_discard_pile_anchor helper**

Add to `views/game_view.lua` before `return GameView`:

```lua
function GameView:get_discard_pile_anchor(position)
  if position == Constants.POSITIONS.BOTTOM then
    return Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 300, 0
  elseif position == Constants.POSITIONS.TOP then
    return Constants.SCREEN_WIDTH / 2, 300, 0
  elseif position == Constants.POSITIONS.LEFT then
    return 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  elseif position == Constants.POSITIONS.RIGHT then
    return Constants.SCREEN_WIDTH - 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  end
  return 0, 0, 0
end
```

**Step 2: Add draw_player_discard_pile method**

Add before `return GameView`:

```lua
function GameView:draw_player_discard_pile(game_state, player, card_render_state)
  local cards = game_state:get_cards_from_discard_pile(player.id)
  if #cards == 0 then
    return  -- No rendering for empty piles
  end

  -- Get anchor position based on player position
  local base_x, base_y, rotation = self:get_discard_pile_anchor(player.position)

  -- Calculate spread positions for all cards
  local positions = LayoutCalculator.calculate_discard_pile_positions(
    cards, base_x, base_y, rotation, Constants.CARD_SCALE
  )

  -- Render cards in z-index order (bottom to top)
  for i, card in ipairs(cards) do
    local pos = positions[card.id]
    self.card_renderer:drawCard(
      card, pos.x, pos.y, pos.rotation,
      Constants.CARD_SCALE, true  -- Always face up
    )
  end
end
```

**Step 3: Update GameView:draw to render discard piles**

Modify `GameView:draw()` to call the new method. Find the section after `self:drawDeck()` and `self:drawDiscardPile()`:

```lua
function GameView:draw(game_state, animation_state)
  love.graphics.clear(0.1, 0.4, 0.2)
  self:drawDeck(game_state)
  self:drawDiscardPile(game_state)  -- Keep old shared pile for now

  -- NEW: Draw each player's discard pile
  local card_render_state = animation_state.card_render_state
  for _, player in ipairs(game_state.players) do
    self:draw_player_discard_pile(game_state, player, card_render_state)
  end

  -- ... rest of draw method
```

**Step 4: Visual test**

Run game and manually discard a card:

```bash
love .
```

Expected: Card should appear in bottom player's discard pile area

**Step 5: Commit**

```bash
git add views/game_view.lua
git commit -m "feat: add per-player discard pile rendering

- draw_player_discard_pile(): Render cards with horizontal spread
- get_discard_pile_anchor(): Calculate base position per player
- Integrate into GameView:draw() to render all piles
- Cards always render face up in discard piles

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 7: Update GameController Discard Animation

**Files:**
- Modify: `controllers/game_controller.lua`

**Step 1: Add get_discard_pile_anchor to GameController**

Add before `return GameController`:

```lua
function GameController:get_discard_pile_anchor(position)
  if position == Constants.POSITIONS.BOTTOM then
    return Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 300, 0
  elseif position == Constants.POSITIONS.TOP then
    return Constants.SCREEN_WIDTH / 2, 300, 0
  elseif position == Constants.POSITIONS.LEFT then
    return 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  elseif position == Constants.POSITIONS.RIGHT then
    return Constants.SCREEN_WIDTH - 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  end
  return 0, 0, 0
end
```

**Step 2: Add calculate_discard_target_position**

Add before `return GameController`:

```lua
function GameController:calculate_discard_target_position(player, card)
  -- Get current discard pile to calculate where new card goes
  local current_pile = self.game_state:get_cards_from_discard_pile(player.id)
  local pile_size = #current_pile  -- Size BEFORE adding new card

  local base_x, base_y, rotation = self:get_discard_pile_anchor(player.position)
  local overlap_offset = Constants.DISCARD_OVERLAP_OFFSET

  -- New card position is at the end of the spread
  local target_x = base_x + pile_size * overlap_offset
  local target_y = base_y

  return target_x, target_y, rotation
end
```

**Step 3: Update startDiscardAnimation to use player-specific position**

Modify `GameController:startDiscardAnimation()`:

```lua
function GameController:startDiscardAnimation(card)
  self.animating = true
  self.animation_card = card
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.ANIMATING_DISCARD

  local current_player = self.game_state:getCurrentPlayer()
  current_player:removeCardFromHand(card)

  -- Calculate target in CURRENT player's discard pile
  local target_x, target_y, rotation = self:calculate_discard_target_position(current_player, card)

  -- Use CardRenderState
  local render_state = self.card_render_state:getState(card.id)
  render_state.face_up = true  -- Always face up in discard pile

  Flux.to(render_state, 0.25, { x = target_x, y = target_y, rotation = rotation })
    :oncomplete(function()
      self:onDiscardAnimationComplete(current_player, card)
    end)
end
```

**Step 4: Update onDiscardAnimationComplete to use new API**

Modify `GameController:onDiscardAnimationComplete()`:

```lua
function GameController:onDiscardAnimationComplete(player, card)
  self.game_state:add_to_discard(player.id, card)
  self:endTurn()
  self.animating = false
  self.animation_card = nil
end
```

**Step 5: Visual test**

Run game and discard a card:

```bash
love .
```

Expected: Card animates to player's discard pile, appears spread if multiple cards

**Step 6: Commit**

```bash
git add controllers/game_controller.lua
git commit -m "feat: update discard animation to use per-player piles

- calculate_discard_target_position(): Target player-specific pile
- Update startDiscardAnimation to animate to correct position
- Update onDiscardAnimationComplete to use add_to_discard(player_id, card)
- Cards animate to end of existing pile spread

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 8: Add Input Handling for Previous Player's Discard Pile

**Files:**
- Modify: `controllers/input_controller.lua`

**Step 1: Add get_discard_pile_anchor to InputController**

Add before `return InputController`:

```lua
function InputController:get_discard_pile_anchor(position)
  if position == Constants.POSITIONS.BOTTOM then
    return Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 300, 0
  elseif position == Constants.POSITIONS.TOP then
    return Constants.SCREEN_WIDTH / 2, 300, 0
  elseif position == Constants.POSITIONS.LEFT then
    return 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  elseif position == Constants.POSITIONS.RIGHT then
    return Constants.SCREEN_WIDTH - 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  end
  return 0, 0, 0
end
```

**Step 2: Add try_pick_from_previous_discard method**

Add before `return InputController`:

```lua
function InputController:try_pick_from_previous_discard(x, y)
  local game_state = self.game_controller.game_state
  local previous_pile = game_state:get_previous_player_discard_pile()

  if #previous_pile == 0 then
    return false  -- No cards to pick
  end

  -- Calculate top card position (only top card is clickable)
  local previous_player = game_state:get_previous_player()
  local base_x, base_y, rotation = self:get_discard_pile_anchor(previous_player.position)
  local overlap_offset = Constants.DISCARD_OVERLAP_OFFSET
  local top_card_index = #previous_pile

  local card_x = base_x + (top_card_index - 1) * overlap_offset
  local card_y = base_y

  -- Hit test on top card
  if LayoutCalculator.isPointInCard(x, y, card_x, card_y, Constants.CARD_SCALE, rotation) then
    local top_card = previous_pile[#previous_pile]

    -- TODO: Validate if card forms meld with current hand
    -- For now: allow any pick
    self.game_controller:pick_from_previous_discard(top_card)
    return true
  end

  return false
end
```

**Step 3: Update mousepressed to check previous discard first**

Modify `InputController:mousepressed()` CHOOSE_ACTION section:

```lua
if game_state.turn_substep == Constants.TURN_SUBSTEPS.CHOOSE_ACTION then
  -- Try picking from previous player's discard pile FIRST
  if self:try_pick_from_previous_discard(x, y) then
    return
  end

  -- Then try clicking deck (existing logic)
  local deck_x = Constants.DECK_X
  local deck_y = Constants.DECK_Y

  if LayoutCalculator.isPointInCard(x, y, deck_x, deck_y, Constants.CARD_SCALE, 0) then
    self.game_controller:drawCard()
  end
end
```

**Step 4: Commit**

```bash
git add controllers/input_controller.lua
git commit -m "feat: add click handling for previous player's discard pile

- try_pick_from_previous_discard(): Detect clicks on previous pile
- Only top card of previous player's pile is clickable
- Integrate into mousepressed CHOOSE_ACTION flow
- TODO: Add meld validation

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 9: Add GameController Method for Picking from Previous Discard

**Files:**
- Modify: `controllers/game_controller.lua`

**Step 1: Add pick_from_previous_discard method**

Add before `return GameController`:

```lua
function GameController:pick_from_previous_discard(card)
  local previous_player = self.game_state:get_previous_player()
  local taken_card = self.game_state:take_top_card_from_discard_pile(previous_player.id)

  if not taken_card then
    print("ERROR: Failed to take card from previous discard")
    return
  end

  -- Animate card from previous discard to current player's hand
  local current_player = self.game_state:getCurrentPlayer()
  local target_x, target_y, rotation = self:calculateCardTargetPosition(current_player)

  self:startDrawAnimation(taken_card, target_x, target_y, rotation)
  -- After animation: player must discard (same flow as drawing from deck)
end
```

**Step 2: Visual test**

Run game, let AI discard, then try clicking their discard pile:

```bash
love .
```

Expected: Card from AI's pile animates to your hand

**Step 3: Commit**

```bash
git add controllers/game_controller.lua
git commit -m "feat: add pick_from_previous_discard method

- pick_from_previous_discard(): Take card from previous player's pile
- Animate to current player's hand
- Same flow as drawing from deck (must discard after)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 10: Integration Test - Full Flow

**Step 1: Manual testing checklist**

Run game and verify:

```bash
love .
```

**Test scenarios:**
- [ ] Player 1 discards → card appears in player 1's pile
- [ ] AI players discard → cards appear in their respective piles
- [ ] Multiple discards → cards spread horizontally with overlap
- [ ] Click previous player's top card → card moves to your hand
- [ ] Can't click previous pile when empty
- [ ] Turn wraps around (Player 1's previous is Player 4)
- [ ] Cards always face up in discard piles
- [ ] Old shared discard pile still works (initial card)

**Step 2: Run all unit tests**

```bash
lua tests/test_game_state.lua
lua tests/test_game_state_discard_piles.lua
lua tests/test_hand_validator.lua
lua tests/test_player.lua
```

Expected: All tests pass

**Step 3: Document test results**

Create test log if all pass:

```bash
echo "Manual testing complete - all scenarios working" > test_results.txt
git add test_results.txt
git commit -m "test: verify separate discard piles integration

All manual test scenarios passing:
- Per-player discard animations
- Horizontal spreading with overlap
- Click handling for previous pile
- Turn order wraparound
- Face-up rendering

All unit tests passing (12 new + 68 existing = 80 total)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 11: Cleanup - Remove Code Duplication (Optional)

**Note:** This task addresses the code duplication of `get_discard_pile_anchor()` across three files. This is **optional** but recommended.

**Files:**
- Modify: `utils/layout_calculator.lua`
- Modify: `views/game_view.lua`
- Modify: `controllers/game_controller.lua`
- Modify: `controllers/input_controller.lua`

**Step 1: Move get_discard_pile_anchor to LayoutCalculator**

Add to `utils/layout_calculator.lua`:

```lua
function LayoutCalculator.get_discard_pile_anchor(position)
  if position == Constants.POSITIONS.BOTTOM then
    return Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 300, 0
  elseif position == Constants.POSITIONS.TOP then
    return Constants.SCREEN_WIDTH / 2, 300, 0
  elseif position == Constants.POSITIONS.LEFT then
    return 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  elseif position == Constants.POSITIONS.RIGHT then
    return Constants.SCREEN_WIDTH - 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  end
  return 0, 0, 0
end
```

**Step 2: Replace in GameView**

In `views/game_view.lua`, replace:
```lua
local base_x, base_y, rotation = self:get_discard_pile_anchor(player.position)
```

With:
```lua
local base_x, base_y, rotation = LayoutCalculator.get_discard_pile_anchor(player.position)
```

Then delete the `GameView:get_discard_pile_anchor` method.

**Step 3: Replace in GameController**

Same replacement in `controllers/game_controller.lua`, then delete the method.

**Step 4: Replace in InputController**

Same replacement in `controllers/input_controller.lua`, then delete the method.

**Step 5: Test**

```bash
love .
```

Expected: No behavior change

**Step 6: Commit**

```bash
git add utils/layout_calculator.lua views/game_view.lua controllers/game_controller.lua controllers/input_controller.lua
git commit -m "refactor: centralize get_discard_pile_anchor in LayoutCalculator

- Move duplicate method to LayoutCalculator (single source of truth)
- Update GameView, GameController, InputController to use it
- No behavior change, reduces code duplication

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Future Work (Not in This Plan)

**Items deferred to future tasks:**

1. **Remove initial shared discard card**
   - Modify game flow so all piles start empty
   - Remove `game_state.discard_pile` field
   - Update `handleDealing()` to not create initial card

2. **Add meld validation when picking from discard**
   - Implement `HandValidator:can_form_meld_with_discard(hand, discard_card)`
   - Only allow picking if it forms valid meld
   - Show visual feedback (highlight/disable) when not valid

3. **Visual feedback for clickable discard piles**
   - Highlight previous player's pile when it's your turn
   - Glow effect on top card when hoverable
   - Disable effect when pile is empty

4. **Pile size limit handling**
   - After ~15 cards, pile may overflow screen
   - Consider max visible cards with "..." indicator
   - Or implement scrolling/panning for large piles

5. **Full snake_case refactoring**
   - Convert all existing methods to snake_case
   - Update all callers across codebase
   - Breaking change - requires comprehensive testing

---

## Execution Complete

After finishing all tasks, run final verification:

```bash
# All unit tests
lua tests/test_game_state.lua && \
lua tests/test_game_state_discard_piles.lua && \
lua tests/test_hand_validator.lua && \
lua tests/test_player.lua

# Visual test
love .
```

**Expected:**
- 80 tests passing (12 new + 68 existing)
- Per-player discard piles rendering with horizontal spread
- Click interaction working on previous player's pile
- No regressions in existing gameplay

**Ready for:**
- Code review
- PR to main branch
- Future enhancements (meld validation, visual feedback, etc.)
