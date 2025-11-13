# Phỏm Game Improvements - Bugs & Features Design

**Date:** 2025-11-13
**Status:** Design Complete, Ready for Implementation

## Overview

This design addresses critical bugs and adds essential gameplay features to the Phỏm card game prototype.

**Bugs to Fix:**
1. Random seed issue - deck shuffle always produces same results
2. Hover detection - overlapping cards highlight wrong card

**Features to Add:**
1. Draw/discard animations with simple tweens
2. Turn action indicators with visual overlays
3. Interactive end game stage with manual hand formation

**Architecture Approach:** State-driven expansion of existing state machine

---

## Bug Fixes

### Bug 1: Random Seed Issue

**Problem:** Deck shuffle always produces the same card sequence because `math.random()` isn't seeded.

**Solution:**
```lua
-- In Deck:shuffle() or game initialization (love.load)
math.randomseed(os.time() + love.timer.getTime() * 1000)
```

**Location:** `models/deck.lua` - `Deck:shuffle()` method

**Why this works:**
- `os.time()` provides second-level randomness
- `love.timer.getTime()` adds sub-second precision
- Combination ensures different seed each launch

---

### Bug 2: Hover Detection for Overlapping Cards

**Problem:** When cards overlap (horizontal row layout), mouse hover highlights the leftmost (bottom) card instead of the topmost card under cursor.

**Root Cause:** Hover detection iterates cards left-to-right, so earlier cards in array get priority.

**Solution:** Reverse iteration order
```lua
-- In InputController:mousemoved()
-- OLD: for i = 1, #player.hand do
-- NEW: for i = #player.hand, 1, -1 do
  local card = player.hand[i]
  if isPointInCard(x, y, card.x, card.y) then
    setHoveredCard(card)
    return  -- Stop checking once topmost card found
  end
end
```

**Location:** `controllers/input_controller.lua` - `mousemoved()` method

**Why this works:** Rightmost cards (rendered last = on top visually) are checked first, giving them hover priority.

---

## State Machine Expansion

### New Animation Substates

**Existing:**
```
PLAYER_TURN:
├─ CHOOSE_ACTION
├─ FORM_MELD (not implemented)
├─ DISCARD_PHASE
└─ CHECK_WIN
```

**New with Animations:**
```
PLAYER_TURN:
├─ CHOOSE_ACTION          (show deck glow, wait for click)
├─ ANIMATING_DRAW         (NEW - card moves deck → hand)
├─ FORM_MELD              (select cards + discard for hand)
├─ DISCARD_PHASE          (show hand glow, wait for click)
├─ ANIMATING_DISCARD      (NEW - card moves hand → discard)
└─ CHECK_WIN              (check empty hand or empty deck)
```

Same substates apply to AI_TURN state.

### Animation State Flow

**Draw Action:**
1. User clicks deck (in CHOOSE_ACTION)
2. Transition to ANIMATING_DRAW
3. Disable input
4. Start flux tween: `deck_pos → hand_pos`, duration 0.3s
5. On animation complete:
   - Add card to player.hand
   - Update card position to final hand position
   - Transition to DISCARD_PHASE
   - Enable input

**Discard Action:**
1. User clicks hand card (in DISCARD_PHASE)
2. Transition to ANIMATING_DISCARD
3. Disable input
4. Start flux tween: `hand_pos → discard_pos`, duration 0.25s
5. On animation complete:
   - Remove card from player.hand
   - Add card to game_state.discard_pile
   - Transition to CHECK_WIN
   - Call endTurn() logic

### Implementation Details

**GameController Changes:**
```lua
GameController = {
  game_state = ...,
  animating = false,  -- NEW: track if animation in progress
  animation_callback = nil  -- NEW: function to call when animation completes
}

function GameController:startDrawAnimation(card)
  self.animating = true
  self.game_state.turn_substep = "ANIMATING_DRAW"

  -- Animate card position
  flux.to(card, 0.3, {x = target_x, y = target_y})
    :oncomplete(function()
      self:onDrawAnimationComplete(card)
    end)
end

function GameController:onDrawAnimationComplete(card)
  -- Add card to hand
  local player = self.game_state:getCurrentPlayer()
  player:addCardToHand(card)

  -- Transition state
  self.game_state.turn_substep = "DISCARD_PHASE"
  self.animating = false
end
```

**Input Blocking:**
```lua
-- In InputController:mousepressed()
if game_controller.animating then
  return  -- Ignore all input during animations
end
```

---

## Visual Overlays & Turn Indicators

### Deck Glow (CHOOSE_ACTION state)

**Effect:** Pulsing glow around deck to indicate "click here to draw"

```lua
-- In GameView:drawDeck()
if game_state.turn_substep == "CHOOSE_ACTION" and
   game_state:getCurrentPlayer().type == "human" then

  -- Draw pulsing glow
  local pulse = 0.5 + 0.5 * math.sin(love.timer.getTime() * 3)
  love.graphics.setColor(1, 1, 0, 0.3 * pulse)  -- Yellow glow
  love.graphics.circle("fill", deck_x, deck_y, 60)
  love.graphics.setColor(1, 1, 1)
end
```

### Hand Cards Highlight (DISCARD_PHASE state)

**Effect:** Subtle glow on all hand cards to indicate "click card to discard"

```lua
-- In GameView:drawBottomPlayer()
if game_state.turn_substep == "DISCARD_PHASE" and
   player.type == "human" then

  for _, card in ipairs(player.hand) do
    -- Draw glow behind card (before card render)
    love.graphics.setColor(0.5, 0.8, 1, 0.4)  -- Blue glow
    love.graphics.rectangle("fill", card.x - 5, card.y - 5,
                           card_width + 10, card_height + 10, 8)
    love.graphics.setColor(1, 1, 1)

    -- Then draw card normally
    card_renderer:drawCard(card, ...)
  end
end
```

### Text Indicator

**Location:** Top center of screen

```lua
-- In GameView:drawUI()
local message = ""
if game_state.current_state == "PLAYER_TURN" then
  if game_state.turn_substep == "CHOOSE_ACTION" then
    message = "Your turn: Draw a card"
  elseif game_state.turn_substep == "DISCARD_PHASE" then
    message = "Your turn: Discard a card"
  elseif game_state.turn_substep:match("ANIMATING") then
    message = "..."  -- Or nothing during animation
  end
end

love.graphics.printf(message, 0, 20, screen_width, "center")
```

---

## End Game Interactive Hand Formation

### Expanded ROUND_END State

```
ROUND_END substates:
├─ END_GAME_TURN_HUMAN      Player 1 forms hands
├─ END_GAME_TURN_AI_1       Player 2 forms hands
├─ END_GAME_TURN_AI_2       Player 3 forms hands
├─ END_GAME_TURN_AI_3       Player 4 forms hands
├─ REVEALING_ALL_HANDS      Show all hands (game + end game)
├─ CALCULATING_SCORES       Show score breakdown with animation
├─ SHOWING_WINNER           Highlight winner
└─ WAITING_FOR_RESTART      "Press Space to continue"
```

### Human Player Turn (END_GAME_TURN_HUMAN)

**UI Layout:**
```
┌─────────────────────────────────────┐
│  Game Over! Form hands to reduce    │
│  your score                          │
├─────────────────────────────────────┤
│  Your remaining cards:               │
│  [A♥] [5♦] [5♣] [5♠] [K♠] [Q♣]     │
│                                      │
│  Select 3+ cards to form a hand     │
│                                      │
│  [Confirm Hand] [Done]              │
├─────────────────────────────────────┤
│  Formed hands:                       │
│  Set: 5♦ 5♣ 5♠                      │
└─────────────────────────────────────┘
```

**Interaction Flow:**
1. Display remaining cards in hand (face-up, selectable)
2. Player clicks cards to select/deselect
3. Validate selection with HandValidator:
   - If valid (set or sequence): Green highlight + "Confirm Hand" button enabled
   - If invalid: Red highlight + "Confirm Hand" button disabled
4. Player clicks "Confirm Hand":
   - Remove selected cards from hand
   - Add to `formed_hands_endgame` list
   - Display formed hand below
   - Reset selection
5. Repeat until player clicks "Done" or no more valid hands possible
6. Transition to next player (AI_1)

**Data Structure:**
```lua
Player = {
  hand = {...},  -- Cards still in hand (loose)
  hands = {      -- Hands formed during game (from discard pile)
    {type="set", cards={...}, visible_card=Card},
    ...
  },
  formed_hands_endgame = {  -- NEW: Hands formed at end game
    {type="set", cards={...}},
    {type="sequence", cards={...}},
    ...
  }
}
```

### AI Player Turn (END_GAME_TURN_AI_*)

**Automatic Hand Formation:**

```lua
function AIController:formEndGameHands(player)
  local remaining = player.hand
  local formed = {}

  -- Greedy algorithm: Form largest valid hands first
  while true do
    local best_hand = findLargestValidHand(remaining)
    if not best_hand then break end

    table.insert(formed, best_hand)
    removeCardsFromHand(remaining, best_hand.cards)

    -- Animate (optional visual feedback)
    animateHandFormation(best_hand, player)
    wait(0.5)  -- Brief delay between hands
  end

  player.formed_hands_endgame = formed
end

function findLargestValidHand(cards)
  -- Try sequences of length 5, 4, 3
  for len = #cards, 3, -1 do
    for each combination of len cards do
      if HandValidator.isValidSequence(combo) or
         HandValidator.isValidSet(combo) then
        return {cards = combo, type = ...}
      end
    end
  end
  return nil
end
```

**Visual Feedback:**
- Display message: "AI Player [X] forming hands..." (1 second)
- Animate cards moving from hand to formed hands area (0.3s per hand)
- Show formed hands briefly before next player

### REVEALING_ALL_HANDS

**Display all formed hands** from both game play and end game phase:

```
┌─────────────────────────────────────┐
│  Player 1 (You):                    │
│    From game:                        │
│      7♥ 7♦ 7♣ (Set from discard)   │
│    End game:                         │
│      5♦ 5♣ 5♠ (Set)                │
│    Remaining: A♥ K♠                 │
├─────────────────────────────────────┤
│  Player 2 (AI):                     │
│    From game: (none)                │
│    End game:                         │
│      3♥ 4♥ 5♥ (Sequence)           │
│    Remaining: K♣ Q♦ 2♠             │
│  ... (Players 3, 4)                 │
└─────────────────────────────────────┘
```

**Animation:**
- Hands formed during game: Flip hidden cards face-up
- End game hands: Already visible
- Remaining cards: Flip AI cards face-up
- Animate each section appearing (0.5s delay between players)

### CALCULATING_SCORES

**Score = Sum of remaining (loose) cards only**

Formed hands don't count toward score.

```
Player 1: A♥(1) + K♠(13) = 14 pts
Player 2: K♣(13) + Q♦(12) + 2♠(2) = 27 pts
Player 3: ...
Player 4: ...
```

**Animation:**
- Count up from 0 to final score (0.5s per player)
- Highlight lowest score in green

### SHOWING_WINNER

**Visual Effects:**
- Winner's area: Golden glow/pulse effect
- Display "WINNER" text above winner
- Show ranking: "1st: Player 1 (14 pts)", "2nd: Player 3 (19 pts)", etc.
- Confetti or particle effect (optional)

**Duration:** Hold until user input

### WAITING_FOR_RESTART

**UI:**
```
Press SPACE to start new round
Press ESC to quit
```

**Actions:**
- Space: Reset game state, transition to MENU → DEALING
- ESC: Quit game

---

## Implementation Checklist

### Phase 1: Bug Fixes
- [ ] Add random seed to Deck:shuffle() or love.load()
- [ ] Reverse iteration in InputController hover detection
- [ ] Test: Verify different card shuffles each game
- [ ] Test: Verify hover on rightmost card works correctly

### Phase 2: Animation Substates
- [ ] Add ANIMATING_DRAW and ANIMATING_DISCARD to Constants.TURN_SUBSTEPS
- [ ] Add GameController.animating flag and callbacks
- [ ] Implement startDrawAnimation() and onDrawAnimationComplete()
- [ ] Implement startDiscardAnimation() and onDiscardAnimationComplete()
- [ ] Update InputController to block input when animating
- [ ] Test: Verify smooth draw/discard with input blocking

### Phase 3: Visual Overlays
- [ ] Add deck glow in GameView:drawDeck() for CHOOSE_ACTION
- [ ] Add hand cards glow in GameView:drawBottomPlayer() for DISCARD_PHASE
- [ ] Add text indicator at top of screen in GameView:drawUI()
- [ ] Test: Verify glows appear at correct times

### Phase 4: End Game Substates
- [ ] Add END_GAME_TURN_* substates to Constants.STATES
- [ ] Add REVEALING_ALL_HANDS, CALCULATING_SCORES, SHOWING_WINNER substates
- [ ] Add Player.formed_hands_endgame field
- [ ] Implement GameController:handleEndGameTurn()
- [ ] Test: Verify state transitions through all end game phases

### Phase 5: Human End Game UI
- [ ] Create end game UI overlay with card selection
- [ ] Implement card selection/deselection logic
- [ ] Add HandValidator integration for real-time validation
- [ ] Add "Confirm Hand" and "Done" buttons
- [ ] Update GameView to show formed hands list
- [ ] Test: Human can form multiple valid hands

### Phase 6: AI End Game Logic
- [ ] Implement findLargestValidHand() algorithm
- [ ] Implement AIController:formEndGameHands()
- [ ] Add animation for AI hand formation
- [ ] Test: AI forms optimal hands from remaining cards

### Phase 7: Reveal & Scoring
- [ ] Implement REVEALING_ALL_HANDS display logic
- [ ] Animate card flipping for hidden cards
- [ ] Implement CALCULATING_SCORES with count-up animation
- [ ] Implement SHOWING_WINNER with visual effects
- [ ] Add keyboard input for WAITING_FOR_RESTART
- [ ] Test: Full end game flow from round end to restart

---

## Testing Strategy

### Unit Tests
- `test_deck_randomness.lua` - Verify different shuffles
- `test_hover_detection.lua` - Verify topmost card hover priority
- `test_hand_formation_endgame.lua` - Verify AI and human hand formation logic

### Integration Tests
- Full game playthrough with animations enabled
- Verify input blocking during animations
- Verify end game flow: human forms hands → AI forms hands → reveal → scoring → winner

### Edge Cases
- End game with no possible hands to form
- End game with one player having 0 cards (already won)
- Hovering over single card vs overlapping cards
- Rapid clicking during animations (should be blocked)

---

## Future Enhancements (Out of Scope)

- Detailed animation paths (arcs, rotation)
- Sound effects for draw/discard/reveal
- Skip animation button
- Replay/undo functionality
- Save end game statistics
