# MVC Architecture Refactoring Plan

> **IMPORTANT**: This refactoring plan MUST be completed before resuming `2025-11-13-phom-card-game-implementation.md`

**Goal**: Eliminate MVC violations and establish clear separation of concerns between Models, Views, and Controllers.

**Rationale**: Current architecture has rendering state mixed into Models and Views mutating Model properties. This causes bugs, duplication, and maintenance issues.

**Estimated Time**: 2-3 hours

**Testing Strategy**: Run game after each task to ensure no regressions. All existing functionality must continue working.

---

## Pre-Refactor Checklist

- [ ] Verify current game runs without errors (`love .`)
- [ ] Document current behavior (draw card, discard card, AI turns work)
- [ ] Create refactoring branch: `git checkout -b refactor/mvc-separation`
- [ ] Commit any uncommitted changes

---

## Task 1: Create LayoutCalculator Utility

**Priority**: High (Prevents bugs from duplicated logic)

**Goal**: Centralize all card position calculations in a single source of truth.

**Problem**: Position formulas exist in 3 places with subtle differences:
- `game_controller.lua:144-189` - Animation target positions
- `game_view.lua:97-220` - Rendering positions
- `input_controller.lua:99-118` - Hover detection positions

**Solution**: Create `utils/layout_calculator.lua` with single implementation.

### Step 1: Create LayoutCalculator Module

**File**: `phom/utils/layout_calculator.lua`

```lua
local Constants = require("utils/constants")

local LayoutCalculator = {}

-- Calculate positions for all cards in a player's hand
-- Returns: table mapping card.id -> {x, y, rotation, index}
function LayoutCalculator.calculateHandPositions(player, card_scale)
  card_scale = card_scale or 1
  local positions = {}

  if player.position == Constants.POSITIONS.BOTTOM then
    positions = LayoutCalculator.calculateBottomHandPositions(player.hand, card_scale)
  elseif player.position == Constants.POSITIONS.LEFT then
    positions = LayoutCalculator.calculateLeftHandPositions(player.hand, card_scale)
  elseif player.position == Constants.POSITIONS.TOP then
    positions = LayoutCalculator.calculateTopHandPositions(player.hand, card_scale)
  elseif player.position == Constants.POSITIONS.RIGHT then
    positions = LayoutCalculator.calculateRightHandPositions(player.hand, card_scale)
  end

  return positions
end

function LayoutCalculator.calculateBottomHandPositions(hand, card_scale)
  local center_x = Constants.SCREEN_WIDTH / 2
  local center_y = Constants.SCREEN_HEIGHT - 70
  local card_spacing = Constants.CARD_WIDTH * card_scale
  local total_width = (#hand - 1) * card_spacing
  local start_x = center_x - total_width / 2

  local positions = {}
  for i, card in ipairs(hand) do
    positions[card.id] = {
      x = start_x + (i - 1) * card_spacing,
      y = center_y,
      rotation = 0,
      index = i
    }
  end

  return positions
end

function LayoutCalculator.calculateLeftHandPositions(hand, card_scale)
  local x = 150
  local center_y = Constants.SCREEN_HEIGHT / 2
  local card_spacing = Constants.CARD_WIDTH * card_scale  -- Width becomes vertical spacing when rotated
  local total_height = (#hand - 1) * card_spacing
  local start_y = center_y - total_height / 2

  local positions = {}
  for i, card in ipairs(hand) do
    positions[card.id] = {
      x = x,
      y = start_y + (i - 1) * card_spacing,
      rotation = math.pi / 2,
      index = i
    }
  end

  return positions
end

function LayoutCalculator.calculateTopHandPositions(hand, card_scale)
  local center_x = Constants.SCREEN_WIDTH / 2
  local y = 120
  local card_spacing = Constants.CARD_WIDTH * card_scale
  local total_width = (#hand - 1) * card_spacing
  local start_x = center_x - total_width / 2

  local positions = {}
  for i, card in ipairs(hand) do
    positions[card.id] = {
      x = start_x + (i - 1) * card_spacing,
      y = y,
      rotation = 0,
      index = i
    }
  end

  return positions
end

function LayoutCalculator.calculateRightHandPositions(hand, card_scale)
  local x = Constants.SCREEN_WIDTH - 150
  local center_y = Constants.SCREEN_HEIGHT / 2
  local card_spacing = Constants.CARD_WIDTH * card_scale
  local total_height = (#hand - 1) * card_spacing
  local start_y = center_y - total_height / 2

  local positions = {}
  for i, card in ipairs(hand) do
    positions[card.id] = {
      x = x,
      y = start_y + (i - 1) * card_spacing,
      rotation = math.pi / 2,
      index = i
    }
  end

  return positions
end

-- Calculate where the NEXT card should go (for animations)
-- This is the position after the card is added to the hand
function LayoutCalculator.calculateNextCardPosition(player, card_scale)
  card_scale = card_scale or 1
  local hand_size = #player.hand  -- Size AFTER card will be added

  if player.position == Constants.POSITIONS.BOTTOM then
    local center_x = Constants.SCREEN_WIDTH / 2
    local center_y = Constants.SCREEN_HEIGHT - 70
    local card_spacing = Constants.CARD_WIDTH * card_scale
    local total_width = hand_size * card_spacing  -- Use current size (includes new card)
    local start_x = center_x - total_width / 2
    local target_x = start_x + hand_size * card_spacing
    return target_x, center_y, 0

  elseif player.position == Constants.POSITIONS.LEFT then
    local x = 150
    local center_y = Constants.SCREEN_HEIGHT / 2
    local card_spacing = Constants.CARD_WIDTH * card_scale
    local total_height = hand_size * card_spacing
    local start_y = center_y - total_height / 2
    local target_y = start_y + hand_size * card_spacing
    return x, target_y, math.pi / 2

  elseif player.position == Constants.POSITIONS.TOP then
    local center_x = Constants.SCREEN_WIDTH / 2
    local y = 120
    local card_spacing = Constants.CARD_WIDTH * card_scale
    local total_width = hand_size * card_spacing
    local start_x = center_x - total_width / 2
    local target_x = start_x + hand_size * card_spacing
    return target_x, y, 0

  elseif player.position == Constants.POSITIONS.RIGHT then
    local x = Constants.SCREEN_WIDTH - 150
    local center_y = Constants.SCREEN_HEIGHT / 2
    local card_spacing = Constants.CARD_WIDTH * card_scale
    local total_height = hand_size * card_spacing
    local start_y = center_y - total_height / 2
    local target_y = start_y + hand_size * card_spacing
    return x, target_y, math.pi / 2
  end

  return 0, 0, 0
end

-- Helper: Check if point (px, py) is inside a card at position
function LayoutCalculator.isPointInCard(px, py, card_x, card_y, card_scale, rotation)
  card_scale = card_scale or 1
  rotation = rotation or 0

  -- For simplicity, ignore rotation for hit testing (good enough for now)
  -- TODO: Add proper rotated rectangle collision if needed

  local half_w = (Constants.CARD_WIDTH * card_scale) / 2
  local half_h = (Constants.CARD_HEIGHT * card_scale) / 2

  return px >= card_x - half_w and px <= card_x + half_w and
         py >= card_y - half_h and py <= card_y + half_h
end

return LayoutCalculator
```

### Step 2: Update GameController to Use LayoutCalculator

**File**: `phom/controllers/game_controller.lua`

**Changes**:

1. Add require at top:
```lua
local LayoutCalculator = require("utils/layout_calculator")
```

2. Replace `calculateCardTargetPosition()` method:
```lua
-- OLD METHOD (DELETE):
-- function GameController:calculateCardTargetPosition(player)
--   ... 45 lines of duplicated code ...
-- end

-- NEW METHOD (SIMPLER):
function GameController:calculateCardTargetPosition(player)
  -- Card scale must match GameView's CARD_SCALE (which is 2)
  -- TODO: Make this a constant instead of hardcoded
  local CARD_SCALE = 2
  return LayoutCalculator.calculateNextCardPosition(player, CARD_SCALE)
end
```

### Step 3: Update GameView to Use LayoutCalculator

**File**: `phom/views/game_view.lua`

**Changes**:

1. Add require at top:
```lua
local LayoutCalculator = require("utils/layout_calculator")
```

2. Replace `drawBottomPlayer()` to use LayoutCalculator:
```lua
function GameView:drawBottomPlayer(player)
  local positions = LayoutCalculator.calculateHandPositions(player, CARD_SCALE)

  for i, card in ipairs(player.hand) do
    local pos = positions[card.id]
    if pos then
      local x = pos.x
      local y = pos.y + (card.hover_offset_y or 0)  -- Keep hover offset

      -- Store position on card for animation system (temporary, will fix in Task 2)
      card.x = x
      card.y = y

      card.face_up = player.type == "human"
      self.card_renderer:drawCard(card, x, y, 0, CARD_SCALE)
    end
  end

  -- Draw hand area cards (existing code)
  -- ...
end
```

3. Update `drawLeftPlayer()`, `drawTopPlayer()`, `drawRightPlayer()` similarly.

### Step 4: Update InputController to Use LayoutCalculator

**File**: `phom/controllers/input_controller.lua`

**Changes**:

1. Add require at top:
```lua
local LayoutCalculator = require("utils/layout_calculator")
```

2. Replace position calculation in `updateHover()`:
```lua
function InputController:updateHover()
  local game_state = self.game_controller.game_state

  -- ... animation blocking checks ...

  local player = game_state:getCurrentPlayer()
  if player.type ~= "human" then
    self:clearHover()
    return
  end

  -- NEW: Use LayoutCalculator
  local CARD_SCALE = 2
  local positions = LayoutCalculator.calculateHandPositions(player, CARD_SCALE)

  -- Check cards in REVERSE order (rightmost/topmost first)
  local new_hovered_index = nil
  for i = #player.hand, 1, -1 do
    local card = player.hand[i]
    local pos = positions[card.id]
    if pos then
      local y = pos.y + (card.hover_offset_y or 0)

      if LayoutCalculator.isPointInCard(self.mouse_x, self.mouse_y, pos.x, y, CARD_SCALE) then
        new_hovered_index = i
        break
      end
    end
  end

  -- ... rest of hover logic ...
end
```

3. Replace position calculation in `handleDiscardPhase()`:
```lua
function InputController:handleDiscardPhase(x, y)
  local game_state = self.game_controller.game_state
  local player = game_state:getCurrentPlayer()

  -- NEW: Use LayoutCalculator
  local CARD_SCALE = 2
  local positions = LayoutCalculator.calculateHandPositions(player, CARD_SCALE)

  -- Check cards in REVERSE order (rightmost/topmost first)
  for i = #player.hand, 1, -1 do
    local card = player.hand[i]
    local pos = positions[card.id]
    if pos then
      local card_y = pos.y + (card.hover_offset_y or 0)

      if LayoutCalculator.isPointInCard(x, y, pos.x, card_y, CARD_SCALE) then
        print("Discarding card with animation:", card)
        self.game_controller:startDiscardAnimation(card)
        self:clearHover()
        return
      end
    end
  end
end
```

4. Delete `isPointInCard()` method (now in LayoutCalculator).

### Step 5: Test Layout Changes

**Testing**:
1. Run `love .` and verify game starts
2. Draw a card - verify animation goes to correct position
3. Hover over cards - verify hover effect works
4. Discard a card - verify click detection works
5. Verify all 4 player positions (play multiple rounds until human is in different positions)

**Expected**: No visual changes, but code is now centralized.

### Step 6: Commit

```bash
git add utils/layout_calculator.lua controllers/ views/
git commit -m "refactor: centralize card position calculations

Create LayoutCalculator utility to eliminate position logic duplication:
- Single source of truth for all hand position calculations
- Used by GameController (animations), GameView (rendering), InputController (input)
- Fixes formula inconsistencies that caused bugs

Eliminates 150+ lines of duplicated code across 3 files.

Part of MVC refactoring plan.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 2: Create CardRenderState System

**Priority**: High (Separates Model from View concerns)

**Goal**: Remove rendering properties (`x`, `y`, `rotation`, `scale`) from Card model.

**Problem**: Card model contains view-specific state, violating MVC separation.

**Solution**: Create a separate CardRenderState system to track visual properties.

### Step 1: Create CardRenderState Module

**File**: `phom/views/card_render_state.lua`

```lua
-- Manages rendering state for cards (separate from card data model)
local CardRenderState = {}
CardRenderState.__index = CardRenderState

function CardRenderState.new()
  local instance = {
    -- Map card.id -> {x, y, rotation, hover_offset_y, face_up}
    render_states = {}
  }
  return setmetatable(instance, CardRenderState)
end

function CardRenderState:getState(card_id)
  if not self.render_states[card_id] then
    self.render_states[card_id] = {
      x = 0,
      y = 0,
      rotation = 0,
      hover_offset_y = 0,
      face_up = true
    }
  end
  return self.render_states[card_id]
end

function CardRenderState:setState(card_id, x, y, rotation, hover_offset_y, face_up)
  local state = self:getState(card_id)
  state.x = x or state.x
  state.y = y or state.y
  state.rotation = rotation or state.rotation
  state.hover_offset_y = hover_offset_y or state.hover_offset_y
  state.face_up = (face_up ~= nil) and face_up or state.face_up
end

function CardRenderState:clearState(card_id)
  self.render_states[card_id] = nil
end

function CardRenderState:clearAll()
  self.render_states = {}
end

return CardRenderState
```

### Step 2: Add CardRenderState to GameController

**File**: `phom/controllers/game_controller.lua`

**Changes**:

1. Add require:
```lua
local CardRenderState = require("views/card_render_state")
```

2. Add to GameController.new():
```lua
function GameController.new()
  local instance = {
    game_state = GameState.new(),
    animation_queue = {},
    ai_controller = nil,
    animating = false,
    animation_card = nil,
    card_render_state = CardRenderState.new(),  -- NEW
  }
  setmetatable(instance, GameController)
  instance.ai_controller = AIController.new(instance)
  return instance
end
```

3. Update `startDrawAnimation()` to use CardRenderState:
```lua
function GameController:startDrawAnimation(card, target_x, target_y, rotation)
  print("=== START DRAW ANIMATION ===")
  print("Card:", card)
  print("From:", Constants.DECK_X, Constants.DECK_Y)
  print("To:", target_x, target_y)
  print("Rotation:", rotation or 0)

  self.animating = true
  self.animation_card = card
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.ANIMATING_DRAW

  -- NEW: Use CardRenderState instead of card properties
  local render_state = self.card_render_state:getState(card.id)
  render_state.x = Constants.DECK_X
  render_state.y = Constants.DECK_Y
  render_state.rotation = 0
  render_state.hover_offset_y = 0
  render_state.face_up = (self.game_state:getCurrentPlayer().type == "human")

  rotation = rotation or 0

  -- Animate the render state, not the card
  flux.to(render_state, 0.3, { x = target_x, y = target_y, rotation = rotation })
    :oncomplete(function()
      print("=== DRAW ANIMATION COMPLETE ===")
      self:onDrawAnimationComplete(card)
    end)
end
```

4. Update `startDiscardAnimation()`:
```lua
function GameController:startDiscardAnimation(card)
  self.animating = true
  self.animation_card = card
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.ANIMATING_DISCARD

  local player = self.game_state:getCurrentPlayer()
  player:removeCardFromHand(card)

  -- NEW: Use CardRenderState
  local render_state = self.card_render_state:getState(card.id)
  render_state.face_up = true
  -- render_state.x and render_state.y already set by GameView

  flux.to(render_state, 0.25, { x = Constants.DISCARD_X, y = Constants.DISCARD_Y, rotation = 0 })
    :oncomplete(function()
      self:onDiscardAnimationComplete(card)
    end)
end
```

### Step 3: Update GameView to Use CardRenderState

**File**: `phom/views/game_view.lua`

**Changes**:

1. Update `draw()` method signature to receive CardRenderState:
```lua
function GameView:draw(game_state, game_controller)
  love.graphics.clear(0.1, 0.4, 0.2)
  self:drawDeck(game_state)
  self:drawDiscardPile(game_state)

  local card_render_state = game_controller.card_render_state  -- NEW

  for _, player in ipairs(game_state.players) do
    self:drawPlayer(player, card_render_state)  -- Pass render state
  end

  -- Draw animating card on top of everything
  if game_controller and game_controller.animating and game_controller.animation_card then
    local card = game_controller.animation_card
    local render_state = card_render_state:getState(card.id)
    self.card_renderer:drawCard(card, render_state.x, render_state.y, render_state.rotation, CARD_SCALE)
  end

  self:drawUI(game_state)
end
```

2. Update `drawPlayer()`:
```lua
function GameView:drawPlayer(player, card_render_state)
  if player.position == Constants.POSITIONS.BOTTOM then
    self:drawBottomPlayer(player, card_render_state)
  elseif player.position == Constants.POSITIONS.LEFT then
    self:drawLeftPlayer(player, card_render_state)
  elseif player.position == Constants.POSITIONS.TOP then
    self:drawTopPlayer(player, card_render_state)
  elseif player.position == Constants.POSITIONS.RIGHT then
    self:drawRightPlayer(player, card_render_state)
  end
end
```

3. Update `drawBottomPlayer()`:
```lua
function GameView:drawBottomPlayer(player, card_render_state)
  local positions = LayoutCalculator.calculateHandPositions(player, CARD_SCALE)

  for i, card in ipairs(player.hand) do
    local pos = positions[card.id]
    if pos then
      local render_state = card_render_state:getState(card.id)

      -- Update render state (not card properties!)
      render_state.x = pos.x
      render_state.y = pos.y
      render_state.face_up = (player.type == "human")

      local y = pos.y + (render_state.hover_offset_y or 0)

      self.card_renderer:drawCard(card, pos.x, y, 0, CARD_SCALE)
    end
  end

  -- Draw hand area cards (existing code)
  -- ...
end
```

4. Update other player draw methods similarly.

### Step 4: Update InputController to Use CardRenderState

**File**: `phom/controllers/input_controller.lua`

**Changes**:

1. Update `updateHover()` to use CardRenderState:
```lua
function InputController:updateHover()
  -- ... existing checks ...

  local player = game_state:getCurrentPlayer()
  if player.type ~= "human" then
    self:clearHover()
    return
  end

  local CARD_SCALE = 2
  local positions = LayoutCalculator.calculateHandPositions(player, CARD_SCALE)
  local card_render_state = self.game_controller.card_render_state  -- NEW

  local new_hovered_index = nil
  for i = #player.hand, 1, -1 do
    local card = player.hand[i]
    local pos = positions[card.id]
    if pos then
      local render_state = card_render_state:getState(card.id)  -- NEW
      local y = pos.y + (render_state.hover_offset_y or 0)

      if LayoutCalculator.isPointInCard(self.mouse_x, self.mouse_y, pos.x, y, CARD_SCALE) then
        new_hovered_index = i
        break
      end
    end
  end

  -- Handle hover state changes
  if new_hovered_index ~= self.hovered_card_index then
    if self.hovered_card_index then
      local prev_card = player.hand[self.hovered_card_index]
      if prev_card then
        local prev_render_state = card_render_state:getState(prev_card.id)
        if prev_render_state.hover_offset_y then
          flux.to(prev_render_state, 0.1, { hover_offset_y = 0 })
        end
      end
    end

    self.hovered_card_index = new_hovered_index
    if new_hovered_index then
      local card = player.hand[new_hovered_index]
      local render_state = card_render_state:getState(card.id)
      if not render_state.hover_offset_y then
        render_state.hover_offset_y = 0
      end
      local hover_offset = -(Constants.CARD_HEIGHT * CARD_SCALE * 0.15)
      flux.to(render_state, 0.1, { hover_offset_y = hover_offset })
    end
  end
end
```

2. Update `clearHover()`:
```lua
function InputController:clearHover()
  if self.hovered_card_index then
    local game_state = self.game_controller.game_state
    local player = game_state:getCurrentPlayer()
    if player and player.hand[self.hovered_card_index] then
      local card = player.hand[self.hovered_card_index]
      local render_state = self.game_controller.card_render_state:getState(card.id)
      if render_state.hover_offset_y then
        flux.to(render_state, 0.1, { hover_offset_y = 0 })
      end
    end
    self.hovered_card_index = nil
  end
end
```

### Step 5: Remove Rendering Properties from Card Model

**File**: `phom/models/card.lua`

**Changes**:

```lua
local Constants = require("utils/constants")

local Card = {}
Card.__index = Card

function Card.new(suit, rank)
  local instance = {
    suit = suit,
    rank = rank,
    id = suit .. "_" .. rank,
    -- REMOVED: x, y, rotation, scale, face_up (now in CardRenderState)
  }
  return setmetatable(instance, Card)
end

-- Rest of methods unchanged
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
```

### Step 6: Test CardRenderState Changes

**Testing**:
1. Run `love .` and verify game starts
2. Draw card - verify animation still works
3. Hover over cards - verify hover animation works
4. Discard card - verify animation works
5. Play full round - verify no visual regressions

**Expected**: Game looks and behaves exactly the same, but Card model is now pure data.

### Step 7: Commit

```bash
git add models/card.lua views/card_render_state.lua controllers/ views/
git commit -m "refactor: separate card rendering state from model

Remove rendering properties (x, y, rotation, scale, face_up) from Card model.
Create CardRenderState system to manage visual properties separately.

Changes:
- Card model is now pure data (suit, rank, id only)
- CardRenderState tracks all rendering properties
- GameController animates render state, not card properties
- GameView reads/writes render state, not card properties
- InputController uses render state for hover effects

Benefits:
- Clean MVC separation (Model has no View concerns)
- Card model is now serializable without visual state
- Easier to test game logic without rendering

Part of MVC refactoring plan.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 3: Eliminate View Mutations

**Priority**: High (Views should be read-only)

**Goal**: Stop GameView from writing to any state during rendering.

**Problem**: GameView currently writes `card.x`, `card.y` during draw operations.

**Solution**: With CardRenderState in place (Task 2), this is mostly solved. Just verify and document.

### Step 1: Audit GameView for State Mutations

**Check these methods**:
- `drawBottomPlayer()`
- `drawLeftPlayer()`
- `drawTopPlayer()`
- `drawRightPlayer()`
- `drawDeck()`
- `drawDiscardPile()`

**Look for**:
- Writing to card properties
- Writing to player properties
- Writing to game_state properties

### Step 2: Document View Purity

Add comment to GameView:

**File**: `phom/views/game_view.lua`

```lua
local Constants = require("utils/constants")
local CardRenderer = require("views/card_renderer")
local LayoutCalculator = require("utils/layout_calculator")

local GameView = {}
GameView.__index = GameView

-- Card scale constant for consistent sizing
local CARD_SCALE = 2

-- MVC CONTRACT:
-- GameView is a PURE VIEW - it reads state but NEVER mutates it.
-- All rendering is read-only. All state changes happen in Controllers.
-- Exception: CardRenderState is mutated to track visual positions (acceptable view state).

function GameView.new()
  -- ...
end
```

### Step 3: Verify No Direct Model Mutations

Search for any remaining direct writes to card or player properties:

```bash
grep -n "card\\.x = " views/game_view.lua
grep -n "card\\.y = " views/game_view.lua
grep -n "card\\.rotation = " views/game_view.lua
grep -n "player\\." views/game_view.lua | grep " = "
```

**Expected**: Only writes to `render_state.*`, no writes to `card.*` or `player.*`.

### Step 4: Commit

```bash
git add views/game_view.lua
git commit -m "docs: document GameView purity and MVC contract

Add comments documenting that GameView is read-only.
Verify no direct mutations to Card or Player models during rendering.
Only CardRenderState (view-specific state) is mutated.

Part of MVC refactoring plan.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 4: Extract CARD_SCALE Constant

**Priority**: Medium (Reduces magic numbers)

**Goal**: Move hardcoded `CARD_SCALE = 2` to Constants file.

**Problem**: CARD_SCALE appears in multiple files as magic number.

**Solution**: Add to Constants and reference everywhere.

### Step 1: Add to Constants

**File**: `phom/utils/constants.lua`

```lua
-- Rendering scale factors
Constants.CARD_SCALE = 2  -- Cards are rendered at 2x their base size
Constants.MELD_AREA_SCALE = 0.8
Constants.DISCARD_AREA_SCALE = 0.8
Constants.MELD_CARD_SPACING_FACTOR = 0.6
```

### Step 2: Update Files Using CARD_SCALE

**Files to update**:
- `phom/views/game_view.lua` - Replace local `CARD_SCALE = 2`
- `phom/controllers/input_controller.lua` - Replace local `CARD_SCALE = 2`
- `phom/controllers/game_controller.lua` - Replace comment "which is 2"

**Change**:
```lua
-- OLD:
local CARD_SCALE = 2

-- NEW:
-- (Remove local definition, use Constants.CARD_SCALE everywhere)
```

### Step 3: Update LayoutCalculator

**File**: `phom/utils/layout_calculator.lua`

Methods should accept `card_scale` parameter and use it (already done in Task 1).

Callers pass `Constants.CARD_SCALE`:

```lua
local positions = LayoutCalculator.calculateHandPositions(player, Constants.CARD_SCALE)
```

### Step 4: Test

Run game and verify rendering looks identical.

### Step 5: Commit

```bash
git add utils/constants.lua views/ controllers/
git commit -m "refactor: extract CARD_SCALE to constants

Move hardcoded CARD_SCALE=2 from multiple files to Constants.
Reduces magic numbers and makes scale configurable.

Part of MVC refactoring plan.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 5: Clean Up View-Controller Coupling

**Priority**: Low (Minor improvement)

**Goal**: Reduce coupling between View and Controller.

**Problem**: GameView receives entire `game_controller` object just to access animation state.

**Solution**: Pass only needed animation state.

### Step 1: Create AnimationState Type

**File**: `phom/controllers/game_controller.lua`

Add method to get animation state:

```lua
function GameController:getAnimationState()
  return {
    animating = self.animating,
    animation_card = self.animation_card,
    card_render_state = self.card_render_state
  }
end
```

### Step 2: Update main.lua

**File**: `phom/main.lua`

```lua
function love.draw()
  -- OLD:
  -- game_view:draw(game_controller.game_state, game_controller)

  -- NEW:
  local animation_state = game_controller:getAnimationState()
  game_view:draw(game_controller.game_state, animation_state)
end
```

### Step 3: Update GameView

**File**: `phom/views/game_view.lua`

```lua
-- OLD signature:
-- function GameView:draw(game_state, game_controller)

-- NEW signature:
function GameView:draw(game_state, animation_state)
  love.graphics.clear(0.1, 0.4, 0.2)
  self:drawDeck(game_state)
  self:drawDiscardPile(game_state)

  local card_render_state = animation_state.card_render_state

  for _, player in ipairs(game_state.players) do
    self:drawPlayer(player, card_render_state)
  end

  -- Draw animating card on top of everything
  if animation_state.animating and animation_state.animation_card then
    local card = animation_state.animation_card
    local render_state = card_render_state:getState(card.id)
    self.card_renderer:drawCard(card, render_state.x, render_state.y, render_state.rotation, CARD_SCALE)
  end

  self:drawUI(game_state)
end
```

### Step 4: Test

Run game and verify it works.

### Step 5: Commit

```bash
git add main.lua views/game_view.lua controllers/game_controller.lua
git commit -m "refactor: reduce view-controller coupling

GameView now receives only animation state (not entire GameController).
Reduces coupling and makes View dependencies explicit.

Part of MVC refactoring plan.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Task 6: Add Architecture Documentation

**Priority**: Medium (Prevent future violations)

**Goal**: Document MVC architecture for future development.

### Step 1: Create Architecture Document

**File**: `phom/docs/architecture/mvc-architecture.md`

```markdown
# MVC Architecture - Phỏm Card Game

## Overview

This codebase follows the **Model-View-Controller (MVC)** pattern with strict separation of concerns.

## Directory Structure

```
phom/
├── models/          - Pure data and business logic
├── views/           - Rendering and visual presentation
├── controllers/     - Game flow orchestration and input handling
├── utils/           - Shared utilities and constants
└── libraries/       - Third-party libraries
```

## Model Layer (models/)

**Purpose**: Manage game state and business logic.

**Rules**:
- ✅ Store game data (cards, players, deck, game state)
- ✅ Implement game rules (scoring, validation, win conditions)
- ✅ Provide APIs for state queries and mutations
- ❌ NO rendering logic (no x, y, rotation, graphics)
- ❌ NO input handling (no mouse clicks, keyboard)
- ❌ NO controller references

**Files**:
- `card.lua` - Card data (suit, rank, id only)
- `deck.lua` - Deck operations (shuffle, draw)
- `player.lua` - Player state (hand, score)
- `game_state.lua` - Central game state
- `hand_validator.lua` - Meld validation rules

**Example** (Correct):
```lua
-- models/card.lua
function Card.new(suit, rank)
  return {
    suit = suit,
    rank = rank,
    id = suit .. "_" .. rank
    -- NO x, y, rotation here!
  }
end
```

## View Layer (views/)

**Purpose**: Render game state to screen.

**Rules**:
- ✅ Read game state and render it
- ✅ Calculate visual layouts and positions
- ✅ Use Love2D graphics API
- ❌ NO state mutation (read-only access to models)
- ❌ NO game logic (no win condition checks, scoring)
- ❌ NO input handling (no processing clicks)

**Files**:
- `game_view.lua` - Main game rendering
- `card_renderer.lua` - Card sprite rendering
- `card_render_state.lua` - Visual state tracking (x, y, rotation)

**Exception**: `CardRenderState` is mutated by Views to track visual positions. This is acceptable because it's view-specific state, not game state.

**Example** (Correct):
```lua
-- views/game_view.lua
function GameView:draw(game_state, animation_state)
  -- Read state, render to screen
  -- NO state.player.hand = ... mutations!
  for _, player in ipairs(game_state.players) do
    self:drawPlayer(player)
  end
end
```

## Controller Layer (controllers/)

**Purpose**: Orchestrate game flow and handle input.

**Rules**:
- ✅ Process user input (mouse, keyboard)
- ✅ Manage state transitions
- ✅ Orchestrate animations
- ✅ Call model methods to update game state
- ❌ NO direct rendering (use Views)
- ❌ NO business logic duplication (use Models)

**Files**:
- `game_controller.lua` - Game state machine and flow
- `input_controller.lua` - Mouse/keyboard input
- `ai_controller.lua` - AI decision making

**Example** (Correct):
```lua
-- controllers/game_controller.lua
function GameController:drawCard()
  local card = self.game_state.deck:draw()  -- ✅ Model method
  local player = self.game_state:getCurrentPlayer()
  player:addCardToHand(card)  -- ✅ Model method

  -- ✅ Controller orchestrates animation
  self:startDrawAnimation(card, target_x, target_y)
end
```

## Utility Layer (utils/)

**Purpose**: Shared utilities used by multiple layers.

**Files**:
- `constants.lua` - Game constants
- `layout_calculator.lua` - Position calculations (used by View and Controller)

**Rules**:
- ✅ Pure functions with no side effects
- ✅ Can be used by any layer
- ❌ NO state storage

## Key Design Decisions

### CardRenderState System

**Problem**: Cards need visual properties (x, y, rotation) for rendering and animation, but Card model should only contain game data.

**Solution**: Separate `CardRenderState` tracks visual properties:
- Card model: `{suit, rank, id}` (pure game data)
- CardRenderState: `{x, y, rotation, hover_offset_y}` (visual state)

**Usage**:
```lua
-- Controllers animate render state
local render_state = card_render_state:getState(card.id)
flux.to(render_state, 0.3, {x = target_x, y = target_y})

-- Views read render state
local render_state = card_render_state:getState(card.id)
card_renderer:drawCard(card, render_state.x, render_state.y)
```

### LayoutCalculator Utility

**Problem**: Card position calculations needed by Controller (animations), View (rendering), and InputController (click detection).

**Solution**: Centralize in `LayoutCalculator` utility:
```lua
local positions = LayoutCalculator.calculateHandPositions(player, scale)
```

Single source of truth prevents formula inconsistencies.

## Common Anti-Patterns to Avoid

### ❌ Rendering State in Models
```lua
-- BAD: Card model with rendering properties
function Card.new(suit, rank)
  return {suit = suit, rank = rank, x = 0, y = 0}  -- ❌
end
```

### ❌ Views Mutating Models
```lua
-- BAD: View writing to model
function GameView:draw(game_state)
  for _, card in ipairs(player.hand) do
    card.x = calculate_x()  -- ❌ View mutating model
  end
end
```

### ❌ Controllers with Business Logic
```lua
-- BAD: Controller duplicating scoring logic
function GameController:endTurn()
  local score = 0
  for _, card in ipairs(player.hand) do
    score = score + card.rank  -- ❌ Should be in Player:calculateScore()
  end
end
```

### ❌ Position Calculation Duplication
```lua
-- BAD: Same formula in multiple files
-- GameView.lua:
local x = center_x + (i - 1) * spacing

-- GameController.lua:
local x = center_x + (i - 1) * spacing  -- ❌ Duplication

-- GOOD: Use LayoutCalculator
local positions = LayoutCalculator.calculateHandPositions(player, scale)
```

## Refactoring Checklist

When adding new features, ensure:

- [ ] Models contain only game data and logic
- [ ] Views are read-only (no state mutations)
- [ ] Controllers orchestrate but don't implement business logic
- [ ] Position calculations use LayoutCalculator
- [ ] Visual state uses CardRenderState, not Card model
- [ ] No circular dependencies between layers
- [ ] Clear separation of concerns

## Testing Strategy

- **Models**: Unit tests for game logic (validation, scoring)
- **Views**: Visual inspection (render state correctly)
- **Controllers**: Integration tests (input → state change → output)

## Further Reading

- `docs/plans/2025-11-13-mvc-refactoring-plan.md` - This refactoring plan
- `docs/plans/2025-11-13-phom-card-game-implementation.md` - Feature implementation plan
```

### Step 2: Commit

```bash
git add docs/architecture/
git commit -m "docs: add MVC architecture documentation

Document architecture principles, layer responsibilities, and anti-patterns.
Provides guidelines for future development to maintain clean separation.

Part of MVC refactoring plan.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Post-Refactor Checklist

- [ ] All tests pass (if tests exist)
- [ ] Game runs without errors
- [ ] Visual behavior identical to pre-refactor
- [ ] All animations work (draw, discard, hover)
- [ ] Input handling works (click deck, discard cards)
- [ ] AI turns work correctly
- [ ] No console errors or warnings
- [ ] Code follows MVC principles
- [ ] Documentation is up to date

---

## Merge and Cleanup

### Step 1: Final Testing

Play through several full rounds:
1. Human player draws and discards
2. AI players take turns
3. Hover effects work
4. Round ends correctly
5. Game can be restarted

### Step 2: Merge to Main Branch

```bash
git checkout feature/phom-card-game
git merge refactor/mvc-separation

# If conflicts, resolve and commit
git mergetool
git commit -m "merge: integrate MVC refactoring"

# Delete refactoring branch
git branch -d refactor/mvc-separation
```

### Step 3: Update Implementation Plan

Mark refactoring as complete in the main plan:

**File**: `phom/docs/plans/2025-11-13-phom-card-game-implementation.md`

Add at the top:
```markdown
## MVC Refactoring (Completed 2025-11-XX)

**Status**: ✅ Completed

The architecture has been refactored to follow strict MVC separation:
- Card model no longer contains rendering properties
- CardRenderState system manages visual state
- LayoutCalculator provides single source of truth for positions
- Views are read-only (no model mutations)
- All position calculations centralized

See `docs/architecture/mvc-architecture.md` for details.

See `docs/plans/2025-11-13-mvc-refactoring-plan.md` for refactoring steps.

---
```

### Step 4: Final Commit

```bash
git add docs/plans/
git commit -m "docs: mark MVC refactoring as complete

All MVC violations addressed:
✅ Card model is pure data
✅ CardRenderState separates visual state
✅ LayoutCalculator centralizes position logic
✅ Views are read-only
✅ Architecture documented

Ready to resume feature development.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Summary

### What This Refactoring Accomplishes

1. **Clean Model Layer**: Card model is pure data (suit, rank, id only)
2. **Pure Views**: GameView is read-only, no state mutations
3. **Centralized Layout**: Single source of truth for positions
4. **Proper Separation**: Visual state separate from game state
5. **Maintainability**: No duplicated formulas, clear responsibilities
6. **Documentation**: Architecture principles documented for future work

### Code Quality Improvements

- **Before**: 150+ lines of duplicated position logic across 3 files
- **After**: Single LayoutCalculator module
- **Before**: Card model mixed with rendering concerns
- **After**: Clean separation via CardRenderState
- **Before**: Views mutate models during rendering
- **After**: Views are pure/read-only

### Time Estimate

- Task 1 (LayoutCalculator): 45-60 minutes
- Task 2 (CardRenderState): 60-90 minutes
- Task 3 (Verify Purity): 15 minutes
- Task 4 (Extract Constant): 10 minutes
- Task 5 (Reduce Coupling): 20 minutes
- Task 6 (Documentation): 30 minutes
- **Total**: 3-4 hours

### Next Steps After Refactoring

Resume feature development from `2025-11-13-phom-card-game-implementation.md`:
- Task 14: Animated Dealing Phase
- Task 15: Card Drag-and-Drop Reordering
- Task 16: Keyboard Shortcuts
- Task 17: Player Meld Area and Individual Discard Piles
- ... and beyond

---

**End of MVC Refactoring Plan**
