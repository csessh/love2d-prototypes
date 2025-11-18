# Separate Discard Piles Design

**Date:** 2025-11-17
**Status:** Design Complete - Ready for Implementation
**Related:** Part of Phỏm card game feature development

## Overview

Replace the single shared discard pile with separate discard piles for each player. Cards in each pile spread horizontally with overlap, showing all discarded cards with the topmost card fully visible and interactive.

## Requirements

### Game Rules
- Each player has their own discard pile
- Current player can pick from **previous player's** discard pile (if it forms a meld)
- OR draw from deck and discard to **their own** discard pile
- Only the **top card** of previous player's pile is clickable

### Visual Requirements
- Cards spread horizontally with overlap
- All cards partially visible, top card fully visible
- Position: In front of each player (between center and player hand)
- Only top card is interactive

## Architecture: GameState-Managed Approach

**Rationale:** Keeps Player models clean and centralizes discard logic in GameState.

### Data Model

**GameState changes (`models/game_state.lua`):**

```lua
function GameState.new()
  return {
    -- ... existing fields ...
    deck = Deck.new(),
    discard_pile = {},  -- TEMPORARY: Keep for initial card (backwards compat)
    discard_piles = {},  -- NEW: { player_id = {card1, card2, ...}, ... }
  }
end
```

**Initialization:**

```lua
function GameState:deal_cards(count)
  -- ... existing dealing logic ...

  -- Initialize empty discard piles
  for _, player in ipairs(self.players) do
    self.discard_piles[player.id] = {}
  end
end
```

### API Methods (snake_case)

**New GameState methods:**

```lua
-- Add card to specific player's discard pile
function GameState:add_to_discard(player_id, card)
  table.insert(self.discard_piles[player_id], card)
end

-- Get all cards from a player's discard pile (for rendering)
function GameState:get_cards_from_discard_pile(player_id)
  return self.discard_piles[player_id] or {}
end

-- Remove and return top card from player's pile
function GameState:take_top_card_from_discard_pile(player_id)
  local pile = self.discard_piles[player_id]
  if #pile == 0 then return nil end
  return table.remove(pile)  -- Removes and returns last element
end

-- Helper: Get previous player's discard pile for draw action
function GameState:get_previous_player_discard_pile()
  local prev_player = self:get_previous_player()
  return self:get_cards_from_discard_pile(prev_player.id)
end

-- Helper: Get previous player in turn order
function GameState:get_previous_player()
  local prev_index = self.current_player_index - 1
  if prev_index < 1 then
    prev_index = #self.players  -- Wrap around
  end
  return self.players[prev_index]
end
```

**Refactoring Required:**

All existing GameState methods need snake_case conversion:
- `getCurrentPlayer()` → `get_current_player()`
- `isDeckEmpty()` → `is_deck_empty()`
- `checkWinCondition()` → `check_win_condition()`
- `calculateAllScores()` → `calculate_all_scores()`
- etc.

## Layout and Positioning

### Constants (`utils/constants.lua`)

```lua
Constants.DISCARD_OVERLAP_OFFSET = 30  -- Horizontal spread between cards

Constants.DISCARD_PILE_POSITIONS = {
  BOTTOM = { x = 640, y = 420 },  -- Above player hand
  TOP = { x = 640, y = 300 },     -- Below player cards
  LEFT = { x = 400, y = 360 },    -- Right of player hand
  RIGHT = { x = 880, y = 360 }    -- Left of player hand
}
```

### LayoutCalculator (`utils/layout_calculator.lua`)

**New function for horizontal spread:**

```lua
function LayoutCalculator.calculate_discard_pile_positions(cards, base_x, base_y, rotation, card_scale)
  -- cards: array of cards in the pile
  -- base_x, base_y: anchor position for the pile
  -- rotation: 0 (horizontal) or math.pi/2 (vertical)
  -- Returns: { [card.id] = {x, y, rotation, z_index}, ... }

  local positions = {}
  local overlap_offset = Constants.DISCARD_OVERLAP_OFFSET

  for i, card in ipairs(cards) do
    local is_top_card = (i == #cards)
    positions[card.id] = {
      x = base_x + (i - 1) * overlap_offset,
      y = base_y,
      rotation = rotation,
      z_index = i,  -- Rendering order (higher = on top)
      fully_visible = is_top_card
    }
  end

  return positions
end
```

**Position calculations by player:**

- **BOTTOM:** `x = SCREEN_WIDTH / 2`, `y = SCREEN_HEIGHT - 300`, `rotation = 0`
- **TOP:** `x = SCREEN_WIDTH / 2`, `y = 300`, `rotation = 0`
- **LEFT:** `x = 400`, `y = SCREEN_HEIGHT / 2`, `rotation = math.pi / 2`
- **RIGHT:** `x = SCREEN_WIDTH - 400`, `y = SCREEN_HEIGHT / 2`, `rotation = math.pi / 2`

## View Layer

### GameView (`views/game_view.lua`)

**Modified draw order:**

```lua
function GameView:draw(game_state, animation_state)
  love.graphics.clear(0.1, 0.4, 0.2)
  self:drawDeck(game_state)

  -- Draw each player's discard pile
  for _, player in ipairs(game_state.players) do
    self:draw_player_discard_pile(game_state, player, animation_state.card_render_state)
  end

  -- Draw player hands
  for _, player in ipairs(game_state.players) do
    self:drawPlayer(player, animation_state.card_render_state)
  end

  -- Animation card (rendered on top)
  if animation_state.animating and animation_state.animation_card then
    local card = animation_state.animation_card
    local render_state = animation_state.card_render_state:getState(card.id)
    self.card_renderer:drawCard(
      card, render_state.x, render_state.y, render_state.rotation,
      Constants.CARD_SCALE, render_state.face_up
    )
  end

  self:drawUI(game_state)
end
```

**New rendering method:**

```lua
function GameView:draw_player_discard_pile(game_state, player, card_render_state)
  local cards = game_state:get_cards_from_discard_pile(player.id)
  if #cards == 0 then return end  -- No rendering for empty piles

  -- Get anchor position
  local base_x, base_y, rotation = self:get_discard_pile_anchor(player.position)

  -- Calculate spread positions
  local positions = LayoutCalculator.calculate_discard_pile_positions(
    cards, base_x, base_y, rotation, Constants.CARD_SCALE
  )

  -- Render in z-index order (bottom to top)
  for i, card in ipairs(cards) do
    local pos = positions[card.id]
    self.card_renderer:drawCard(
      card, pos.x, pos.y, pos.rotation,
      Constants.CARD_SCALE, true  -- Always face up
    )
  end
end

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
end
```

## Animation

### GameController (`controllers/game_controller.lua`)

**Updated discard animation:**

```lua
function GameController:start_discard_animation(card)
  self.animating = true
  self.animation_card = card
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.ANIMATING_DISCARD

  local current_player = self.game_state:get_current_player()
  current_player:removeCardFromHand(card)

  -- Calculate target in CURRENT player's discard pile
  local target_x, target_y, rotation = self:calculate_discard_target_position(current_player, card)

  local render_state = self.card_render_state:getState(card.id)
  render_state.face_up = true  -- Always face up in discard

  Flux.to(render_state, Constants.ANIM_DISCARD_DURATION_S,
    { x = target_x, y = target_y, rotation = rotation }
  ):oncomplete(function()
    self:on_discard_animation_complete(current_player.id, card)
  end)
end

function GameController:calculate_discard_target_position(player, card)
  -- Get existing pile to calculate new card position
  local current_pile = self.game_state:get_cards_from_discard_pile(player.id)
  local pile_size = #current_pile  -- Size BEFORE adding new card

  local base_x, base_y, rotation = self:get_discard_pile_anchor(player.position)
  local overlap_offset = Constants.DISCARD_OVERLAP_OFFSET

  -- New card position at end of spread
  local target_x = base_x + pile_size * overlap_offset
  local target_y = base_y

  return target_x, target_y, rotation
end

function GameController:get_discard_pile_anchor(position)
  -- Same logic as GameView:get_discard_pile_anchor
  -- Consider moving to LayoutCalculator to avoid duplication
  if position == Constants.POSITIONS.BOTTOM then
    return Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 300, 0
  elseif position == Constants.POSITIONS.TOP then
    return Constants.SCREEN_WIDTH / 2, 300, 0
  elseif position == Constants.POSITIONS.LEFT then
    return 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  elseif position == Constants.POSITIONS.RIGHT then
    return Constants.SCREEN_WIDTH - 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  end
end

function GameController:on_discard_animation_complete(player_id, card)
  self.game_state:add_to_discard(player_id, card)
  self:endTurn()
  self.animating = false
  self.animation_card = nil
end
```

## Input Handling

### InputController (`controllers/input_controller.lua`)

**Updated click handling:**

```lua
function InputController:mousepressed(x, y, button)
  if button ~= 1 then return end

  local game_state = self.game_controller.game_state

  if game_state.current_state == Constants.STATES.PLAYER_TURN then
    if game_state.turn_substep == Constants.TURN_SUBSTEPS.CHOOSE_ACTION then
      -- Try picking from previous player's discard pile
      if self:try_pick_from_previous_discard(x, y) then
        return
      end

      -- Try clicking deck
      if self:is_point_in_deck(x, y) then
        self.game_controller:drawCard()
        return
      end
    elseif game_state.turn_substep == Constants.TURN_SUBSTEPS.DISCARD_PHASE then
      self:handle_discard_phase(x, y)
    end
  end
end

function InputController:try_pick_from_previous_discard(x, y)
  local game_state = self.game_controller.game_state
  local previous_pile = game_state:get_previous_player_discard_pile()

  if #previous_pile == 0 then
    return false  -- No cards to pick
  end

  -- Calculate top card position (only top card clickable)
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

function InputController:get_discard_pile_anchor(position)
  -- Same as GameController and GameView
  -- TODO: Move to LayoutCalculator
  if position == Constants.POSITIONS.BOTTOM then
    return Constants.SCREEN_WIDTH / 2, Constants.SCREEN_HEIGHT - 300, 0
  elseif position == Constants.POSITIONS.TOP then
    return Constants.SCREEN_WIDTH / 2, 300, 0
  elseif position == Constants.POSITIONS.LEFT then
    return 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  elseif position == Constants.POSITIONS.RIGHT then
    return Constants.SCREEN_WIDTH - 400, Constants.SCREEN_HEIGHT / 2, math.pi / 2
  end
end
```

**New GameController method:**

```lua
function GameController:pick_from_previous_discard(card)
  local previous_player = self.game_state:get_previous_player()
  local taken_card = self.game_state:take_top_card_from_discard_pile(previous_player.id)

  -- Animate from previous discard to current player's hand
  local current_player = self.game_state:get_current_player()
  local target_x, target_y, rotation = self:calculate_card_target_position(current_player)

  self:start_draw_animation(taken_card, target_x, target_y, rotation)
  -- Same flow as deck draw: player must discard after
end
```

## Edge Cases and Testing

### Empty Discard Piles
- Game starts with all piles empty (after future refactor)
- No placeholder rendering for empty piles
- Cannot click empty previous player's pile (returns false)

### Initial Discard (Temporary)
**Current implementation:** One shared initial card from dealing phase

**Temporary solution:**
- Keep `game_state.discard_pile` for initial card
- Render in center (existing behavior)
- First player can pick from it OR draw from deck
- After first turn, all discards go to per-player piles

**Future refactor:** Remove initial discard, all piles start empty

### Pile Growth
- Cards spread horizontally with 30px offset
- Z-index ensures correct rendering order
- **Potential issue:** After ~15 cards, pile may overflow screen
  - Consider max visible cards or scrolling (future enhancement)

### Turn Order Wraparound
- Player order: 1 → 2 → 3 → 4 → 1 (loops)
- `get_previous_player()` correctly handles wraparound:
  - Player 1's previous = Player 4

### Animation Timing
- Card animates to position based on **current pile size**
- Pile only updated after animation completes (`on_discard_animation_complete`)
- Prevents visual "pop" of card jumping to final position

## Code Duplication Note

**Issue:** `get_discard_pile_anchor()` duplicated across:
- GameView
- GameController
- InputController

**Solution (future refactor):**
Move to `LayoutCalculator.get_discard_pile_anchor(position)` as single source of truth.

## Implementation Checklist

- [ ] Update `constants.lua` with DISCARD_OVERLAP_OFFSET and positions
- [ ] Add `discard_piles` to GameState initialization
- [ ] Implement GameState methods (add_to_discard, get_cards_from_discard_pile, etc.)
- [ ] Add `calculate_discard_pile_positions()` to LayoutCalculator
- [ ] Replace GameView:drawDiscardPile() with draw_player_discard_pile()
- [ ] Update GameController discard animation to use player-specific positions
- [ ] Add InputController:try_pick_from_previous_discard()
- [ ] Add GameController:pick_from_previous_discard()
- [ ] Refactor all GameState methods to snake_case (breaking change)
- [ ] Test empty piles, wraparound, animation timing
- [ ] Update existing unit tests for new API

## Future Enhancements

1. **Remove initial discard card** - Start all piles empty
2. **Meld validation** - Only allow picking previous discard if it forms a meld
3. **Visual feedback** - Highlight previous player's pile when it's pickable
4. **Pile size limit** - Max visible cards with overflow handling
5. **Consolidate anchor position logic** - Move to LayoutCalculator

---

**Design Status:** Ready for implementation planning
