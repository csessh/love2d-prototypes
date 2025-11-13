# Phỏm Game Bugs & Features Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix critical bugs and add animations, turn indicators, and interactive end game hand formation

**Architecture:** State-driven expansion of existing state machine with animation substates and end game flow

**Tech Stack:** Love2D, Lua, flux (tween library), existing MVC architecture

---

## Implementation Progress

**Status:** In Progress (3/27 tasks completed)

### Completed Tasks ✅

- **Task 1: Fix Random Seed Bug** - Commit: `b3c5de3`
  - Added RNG seeding to `love.load()` (moved from Deck:shuffle() after code review)
  - Ensures different card sequences each game

- **Task 2: Fix Hover Detection for Overlapping Cards** - Commit: `3977ca9`
  - Reversed iteration order in hover detection
  - Rightmost (topmost) card now highlights correctly

- **Task 3: Add Animation Substates to Constants** - Commit: `ce81bef`
  - Added ANIMATING_DRAW and ANIMATING_DISCARD to TURN_SUBSTEPS
  - Foundation for animation system

### In Progress 🔄

- **Task 4: Add GameController Animation State** - Started, needs completion

### Pending ⏳

- Tasks 5-27: Animation implementation, visual indicators, end game flow

---

## Task 1: Fix Random Seed Bug

**Files:**
- Modify: `models/deck.lua:1-20`

**Step 1: Locate Deck:shuffle() method**

Read the file to see current implementation:

```bash
# Read to understand current shuffle implementation
```

Expected: shuffle() uses math.random() without seed

**Step 2: Add random seed to Deck:shuffle()**

In `models/deck.lua`, add seeding at the start of shuffle():

```lua
function Deck:shuffle()
  -- Seed random number generator with time
  math.randomseed(os.time() + (love and love.timer.getTime() * 1000 or 0))

  -- Fisher-Yates shuffle
  for i = #self.cards, 2, -1 do
    local j = math.random(i)
    self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
  end
end
```

**Step 3: Test shuffle produces different results**

Run the game multiple times:

```bash
love .
```

Expected: Different card distributions each run

**Step 4: Verify with manual test**

Add temporary debug output in main.lua love.load() after dealing:

```lua
-- Temporary debug: print first 5 cards
for i = 1, 5 do
  local card = game_controller.game_state.players[1].hand[i]
  print(i, card.suit, card.rank)
end
```

Run twice, verify different output each time.

**Step 5: Remove debug output**

Remove the temporary print statements.

**Step 6: Commit**

```bash
git add models/deck.lua
git commit -m "fix: seed random number generator in Deck:shuffle()

Deck shuffle now produces different card sequences each game."
```

---

## Task 2: Fix Hover Detection for Overlapping Cards

**Files:**
- Modify: `controllers/input_controller.lua:80-110`

**Step 1: Locate mousemoved() hover detection logic**

Read the file to find the hover detection loop:

```bash
# Read input_controller.lua to find hover logic
```

Expected: Loop iterates `for i = 1, #player.hand do`

**Step 2: Reverse iteration order**

Change the loop to iterate backwards:

```lua
function InputController:mousemoved(x, y, dx, dy)
  local game_state = self.game_controller.game_state

  if game_state.current_state ~= Constants.STATES.PLAYER_TURN then
    self:clearHover()
    return
  end

  local player = game_state:getCurrentPlayer()
  if player.type ~= "human" then return end

  -- Check cards in REVERSE order (rightmost/topmost first)
  for i = #player.hand, 1, -1 do
    local card = player.hand[i]
    if self:isPointInCard(x, y, card.x, card.y) then
      self:setHoveredCard(card)
      return  -- Stop once topmost card found
    end
  end

  self:clearHover()
end
```

**Step 3: Test hover detection**

Run the game:

```bash
love .
```

Test: Hover over overlapping cards in hand
Expected: Rightmost (top) card highlights, not leftmost

**Step 4: Commit**

```bash
git add controllers/input_controller.lua
git commit -m "fix: hover detection prioritizes topmost card

Reverse iteration ensures rightmost overlapping card highlights first."
```

---

## Task 3: Add Animation Substates to Constants

**Files:**
- Modify: `utils/constants.lua:25-40`

**Step 1: Read current TURN_SUBSTEPS**

Read constants.lua to see existing substates.

**Step 2: Add animation substates**

Add new substates to TURN_SUBSTEPS:

```lua
Constants.TURN_SUBSTEPS = {
  CHOOSE_ACTION = "CHOOSE_ACTION",
  ANIMATING_DRAW = "ANIMATING_DRAW",  -- NEW
  FORM_HAND = "FORM_HAND",
  DISCARD_PHASE = "DISCARD_PHASE",
  ANIMATING_DISCARD = "ANIMATING_DISCARD",  -- NEW
  CHECK_WIN = "CHECK_WIN"
}
```

**Step 3: Commit**

```bash
git add utils/constants.lua
git commit -m "feat: add animation substates to turn flow

Add ANIMATING_DRAW and ANIMATING_DISCARD substates."
```

---

## Task 4: Add GameController Animation State

**Files:**
- Modify: `controllers/game_controller.lua:1-30`

**Step 1: Read GameController constructor**

Read game_controller.lua to see current fields.

**Step 2: Add animation tracking fields**

Add fields in GameController.new():

```lua
function GameController.new()
  local instance = {
    game_state = GameState.new(),
    ai_controller = AIController.new(nil),  -- Set reference later
    ai_think_timer = 0,
    animating = false,  -- NEW: track if animation in progress
    animation_card = nil  -- NEW: card being animated
  }

  local self = setmetatable(instance, GameController)
  self.ai_controller.game_controller = self

  return self
end
```

**Step 3: Commit**

```bash
git add controllers/game_controller.lua
git commit -m "feat: add animation state tracking to GameController

Add animating flag and animation_card field."
```

---

## Task 5: Implement Draw Animation

**Files:**
- Modify: `controllers/game_controller.lua:100-150`
- Modify: `controllers/input_controller.lua:30-60`

**Step 1: Add startDrawAnimation() method**

Add to GameController:

```lua
function GameController:startDrawAnimation(card, target_x, target_y)
  self.animating = true
  self.animation_card = card
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.ANIMATING_DRAW

  -- Position card at deck location
  card.x = Constants.DECK_X
  card.y = Constants.DECK_Y

  -- Animate to hand position
  flux.to(card, 0.3, {x = target_x, y = target_y})
    :oncomplete(function()
      self:onDrawAnimationComplete(card)
    end)
end

function GameController:onDrawAnimationComplete(card)
  -- Add card to player's hand
  local player = self.game_state:getCurrentPlayer()
  player:addCardToHand(card)

  -- Transition to discard phase
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.DISCARD_PHASE
  self.animating = false
  self.animation_card = nil
end
```

**Step 2: Update InputController deck click**

Modify InputController:mousepressed() deck click handler:

```lua
-- In mousepressed(), find deck click handling
if button == 1 and game_state.turn_substep == Constants.TURN_SUBSTEPS.CHOOSE_ACTION then
  -- Check if clicked on deck
  if self:isPointInRect(x, y, Constants.DECK_X, Constants.DECK_Y,
                        Constants.CARD_WIDTH * 2, Constants.CARD_HEIGHT * 2) then

    local card = game_state.deck:draw()
    if card then
      card.face_up = true

      -- Calculate target position in hand
      local player = game_state:getCurrentPlayer()
      local hand_size = #player.hand
      local start_x = Constants.SCREEN_WIDTH / 2 - ((hand_size + 1) * Constants.CARD_WIDTH * 2) / 2
      local target_x = start_x + hand_size * Constants.CARD_WIDTH * 2
      local target_y = Constants.SCREEN_HEIGHT - Constants.CARD_HEIGHT * 2 - 20

      -- Start animation
      self.game_controller:startDrawAnimation(card, target_x, target_y)
    end
  end
end
```

**Step 3: Test draw animation**

Run the game:

```bash
love .
```

Test: Click deck to draw
Expected: Card animates from deck to hand smoothly (0.3s)

**Step 4: Commit**

```bash
git add controllers/game_controller.lua controllers/input_controller.lua
git commit -m "feat: implement draw animation

Card smoothly animates from deck to hand with flux tween."
```

---

## Task 6: Block Input During Animation

**Files:**
- Modify: `controllers/input_controller.lua:1-20`

**Step 1: Add animation check to mousepressed()**

At the start of mousepressed():

```lua
function InputController:mousepressed(x, y, button)
  -- Block input during animations
  if self.game_controller.animating then
    return
  end

  -- ... rest of existing code
end
```

**Step 2: Add animation check to mousemoved()**

At the start of mousemoved():

```lua
function InputController:mousemoved(x, y, dx, dy)
  -- Block hover during animations
  if self.game_controller.animating then
    self:clearHover()
    return
  end

  -- ... rest of existing code
end
```

**Step 3: Test input blocking**

Run the game:

```bash
love .
```

Test: Click deck, try clicking cards during animation
Expected: No response until animation completes

**Step 4: Commit**

```bash
git add controllers/input_controller.lua
git commit -m "feat: block input during card animations

Prevent clicks and hover effects while animating."
```

---

## Task 7: Implement Discard Animation

**Files:**
- Modify: `controllers/game_controller.lua:150-200`
- Modify: `controllers/input_controller.lua:60-90`

**Step 1: Add startDiscardAnimation() method**

Add to GameController:

```lua
function GameController:startDiscardAnimation(card)
  self.animating = true
  self.animation_card = card
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.ANIMATING_DISCARD

  local start_x = card.x
  local start_y = card.y

  -- Animate to discard pile position
  flux.to(card, 0.25, {x = Constants.DISCARD_X, y = Constants.DISCARD_Y})
    :oncomplete(function()
      self:onDiscardAnimationComplete(card)
    end)
end

function GameController:onDiscardAnimationComplete(card)
  local player = self.game_state:getCurrentPlayer()

  -- Remove from hand
  player:removeCardFromHand(card)

  -- Add to discard pile
  self.game_state:addToDiscard(card)

  -- End turn
  self:endTurn()

  self.animating = false
  self.animation_card = nil
end
```

**Step 2: Update InputController card discard**

Modify InputController:mousepressed() discard handling:

```lua
-- In mousepressed(), find discard phase card click
if button == 1 and game_state.turn_substep == Constants.TURN_SUBSTEPS.DISCARD_PHASE then
  local player = game_state:getCurrentPlayer()

  if player.type == "human" then
    -- Check if clicked on any card in hand
    for i = #player.hand, 1, -1 do
      local card = player.hand[i]
      if self:isPointInCard(x, y, card.x, card.y) then
        -- Start discard animation
        self.game_controller:startDiscardAnimation(card)
        return
      end
    end
  end
end
```

**Step 3: Test discard animation**

Run the game:

```bash
love .
```

Test: Draw card, then discard a card
Expected: Card animates from hand to discard pile (0.25s)

**Step 4: Commit**

```bash
git add controllers/game_controller.lua controllers/input_controller.lua
git commit -m "feat: implement discard animation

Card smoothly animates from hand to discard pile."
```

---

## Task 8: Add Deck Glow Visual Indicator

**Files:**
- Modify: `views/game_view.lua:150-200`

**Step 1: Read current drawDeck() method**

Read game_view.lua to find deck rendering.

**Step 2: Add pulsing glow effect**

Modify drawDeck() method:

```lua
function GameView:drawDeck(game_state)
  local deck_x = Constants.DECK_X
  local deck_y = Constants.DECK_Y

  -- Draw glow if it's human player's turn to choose action
  if game_state.turn_substep == Constants.TURN_SUBSTEPS.CHOOSE_ACTION and
     game_state:getCurrentPlayer().type == "human" then

    -- Pulsing glow effect
    local pulse = 0.5 + 0.5 * math.sin(love.timer.getTime() * 3)
    love.graphics.setColor(1, 1, 0, 0.3 * pulse)  -- Yellow glow
    love.graphics.circle("fill", deck_x + Constants.CARD_WIDTH,
                         deck_y + Constants.CARD_HEIGHT, 70)
    love.graphics.setColor(1, 1, 1)  -- Reset color
  end

  -- Draw deck (existing code)
  if #game_state.deck.cards > 0 then
    self.card_renderer:drawCardBack(deck_x, deck_y, 0, 2)

    -- Draw card count
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(#game_state.deck.cards,
                        deck_x, deck_y + Constants.CARD_HEIGHT * 2 + 5,
                        Constants.CARD_WIDTH * 2, "center")
    love.graphics.setColor(1, 1, 1)
  end
end
```

**Step 3: Test deck glow**

Run the game:

```bash
love .
```

Test: Observe deck during your turn
Expected: Yellow pulsing glow around deck during CHOOSE_ACTION

**Step 4: Commit**

```bash
git add views/game_view.lua
git commit -m "feat: add pulsing glow to deck during player turn

Yellow glow indicates when player should draw card."
```

---

## Task 9: Add Hand Cards Glow Indicator

**Files:**
- Modify: `views/game_view.lua:250-300`

**Step 1: Read current drawBottomPlayer() method**

Read game_view.lua to find human player hand rendering.

**Step 2: Add card glow during discard phase**

Modify drawBottomPlayer() method:

```lua
function GameView:drawBottomPlayer(player, game_state)
  local CARD_SCALE = 2
  local start_x = Constants.SCREEN_WIDTH / 2 - (#player.hand * Constants.CARD_WIDTH * CARD_SCALE) / 2
  local y = Constants.SCREEN_HEIGHT - Constants.CARD_HEIGHT * CARD_SCALE - 20

  for i, card in ipairs(player.hand) do
    local x = start_x + (i - 1) * Constants.CARD_WIDTH * CARD_SCALE
    card.x = x
    card.y = y + (card.hover_offset_y or 0)

    -- Draw glow if in discard phase
    if game_state.turn_substep == Constants.TURN_SUBSTEPS.DISCARD_PHASE and
       player.type == "human" then
      love.graphics.setColor(0.5, 0.8, 1, 0.4)  -- Blue glow
      love.graphics.rectangle("fill",
                              x - 5,
                              y + (card.hover_offset_y or 0) - 5,
                              Constants.CARD_WIDTH * CARD_SCALE + 10,
                              Constants.CARD_HEIGHT * CARD_SCALE + 10,
                              8)
      love.graphics.setColor(1, 1, 1)
    end

    -- Draw card
    self.card_renderer:drawCard(card, x, y + (card.hover_offset_y or 0), 0, CARD_SCALE)
  end
end
```

**Step 3: Test hand cards glow**

Run the game:

```bash
love .
```

Test: Draw a card, observe hand during discard phase
Expected: Blue glow around all hand cards during DISCARD_PHASE

**Step 4: Commit**

```bash
git add views/game_view.lua
git commit -m "feat: add glow to hand cards during discard phase

Blue glow indicates when player should discard card."
```

---

## Task 10: Add Text Turn Indicator

**Files:**
- Modify: `views/game_view.lua:50-100`

**Step 1: Locate main draw() method**

Read game_view.lua to find where UI elements are drawn.

**Step 2: Add drawUI() method**

Add new method to GameView:

```lua
function GameView:drawUI(game_state)
  local message = ""

  if game_state.current_state == Constants.STATES.PLAYER_TURN then
    if game_state.turn_substep == Constants.TURN_SUBSTEPS.CHOOSE_ACTION then
      message = "Your turn: Draw a card"
    elseif game_state.turn_substep == Constants.TURN_SUBSTEPS.DISCARD_PHASE then
      message = "Your turn: Discard a card"
    elseif game_state.turn_substep:match("ANIMATING") then
      message = "..."
    end
  elseif game_state.current_state:match("AI_TURN") then
    message = "AI Player thinking..."
  end

  if message ~= "" then
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf(message, 0, 20, Constants.SCREEN_WIDTH, "center")
    love.graphics.setFont(love.graphics.newFont(12))  -- Reset font
  end
end
```

**Step 3: Call drawUI() from main draw()**

Add call in GameView:draw():

```lua
function GameView:draw(game_state)
  love.graphics.clear(0.2, 0.5, 0.3, 1)  -- Green table

  -- Draw UI text indicator
  self:drawUI(game_state)

  -- ... rest of existing draw calls
  self:drawDeck(game_state)
  self:drawDiscardPile(game_state)
  -- etc.
end
```

**Step 4: Test text indicator**

Run the game:

```bash
love .
```

Test: Observe top of screen during different turn phases
Expected: Text changes between "Draw a card" and "Discard a card"

**Step 5: Commit**

```bash
git add views/game_view.lua
git commit -m "feat: add text turn indicator at top of screen

Display current turn instruction to player."
```

---

## Task 11: Add End Game Substates to Constants

**Files:**
- Modify: `utils/constants.lua:15-30`

**Step 1: Read current STATES**

Read constants.lua to see existing game states.

**Step 2: Add end game substates**

Modify or expand STATES:

```lua
Constants.STATES = {
  MENU = "MENU",
  DEALING = "DEALING",
  PLAYER_TURN = "PLAYER_TURN",
  AI_TURN_1 = "AI_TURN_1",
  AI_TURN_2 = "AI_TURN_2",
  AI_TURN_3 = "AI_TURN_3",
  ROUND_END = "ROUND_END",
  GAME_OVER = "GAME_OVER"
}

-- NEW: End game substates for ROUND_END
Constants.END_GAME_SUBSTEPS = {
  END_GAME_TURN_HUMAN = "END_GAME_TURN_HUMAN",
  END_GAME_TURN_AI_1 = "END_GAME_TURN_AI_1",
  END_GAME_TURN_AI_2 = "END_GAME_TURN_AI_2",
  END_GAME_TURN_AI_3 = "END_GAME_TURN_AI_3",
  REVEALING_ALL_HANDS = "REVEALING_ALL_HANDS",
  CALCULATING_SCORES = "CALCULATING_SCORES",
  SHOWING_WINNER = "SHOWING_WINNER",
  WAITING_FOR_RESTART = "WAITING_FOR_RESTART"
}
```

**Step 3: Commit**

```bash
git add utils/constants.lua
git commit -m "feat: add end game substates for round end flow

Add substates for hand formation, reveal, scoring, winner."
```

---

## Task 12: Add formed_hands_endgame Field to Player

**Files:**
- Modify: `models/player.lua:1-25`

**Step 1: Read Player constructor**

Read player.lua to see current fields.

**Step 2: Add formed_hands_endgame field**

Add to Player.new():

```lua
function Player.new(id, player_type, position)
  local instance = {
    id = id,
    type = player_type,
    position = position,
    hand = {},
    hands = {},
    hand_area_cards = {},
    formed_hands_endgame = {},  -- NEW: hands formed at end game
    score = 0
  }
  return setmetatable(instance, Player)
end
```

**Step 3: Commit**

```bash
git add models/player.lua
git commit -m "feat: add formed_hands_endgame field to Player

Track hands formed during end game phase."
```

---

## Task 13: Initialize End Game Flow in GameController

**Files:**
- Modify: `controllers/game_controller.lua:200-250`

**Step 1: Find round end logic**

Read game_controller.lua to find where ROUND_END state is entered.

**Step 2: Add end game initialization**

When transitioning to ROUND_END, set first end game substep:

```lua
function GameController:checkRoundEnd()
  -- Check if someone emptied hand
  for _, player in ipairs(self.game_state.players) do
    if #player.hand == 0 then
      self.game_state.current_state = Constants.STATES.ROUND_END
      self.game_state.end_game_substep = Constants.END_GAME_SUBSTEPS.END_GAME_TURN_HUMAN
      return true
    end
  end

  -- Check if deck is empty
  if #self.game_state.deck.cards == 0 then
    self.game_state.current_state = Constants.STATES.ROUND_END
    self.game_state.end_game_substep = Constants.END_GAME_SUBSTEPS.END_GAME_TURN_HUMAN
    return true
  end

  return false
end
```

**Step 3: Add end_game_substep field to GameState**

Modify `models/game_state.lua`:

```lua
function GameState.new()
  local instance = {
    deck = Deck.new(),
    discard_pile = {},
    players = {},
    current_player_index = 1,
    current_state = Constants.STATES.MENU,
    turn_substep = Constants.TURN_SUBSTEPS.CHOOSE_ACTION,
    end_game_substep = nil,  -- NEW: track end game phase
    selected_cards = {},
    round_number = 1
  }
  return setmetatable(instance, GameState)
end
```

**Step 4: Commit**

```bash
git add controllers/game_controller.lua models/game_state.lua
git commit -m "feat: initialize end game flow on round end

Set END_GAME_TURN_HUMAN as first substep when round ends."
```

---

## Task 14: Create End Game UI State Tracking

**Files:**
- Create: `views/end_game_ui.lua`

**Step 1: Create EndGameUI module**

Create new file with selection tracking:

```lua
local Constants = require("utils/constants")
local HandValidator = require("utils/hand_validator")

local EndGameUI = {}
EndGameUI.__index = EndGameUI

function EndGameUI.new()
  local instance = {
    selected_cards = {},  -- Cards selected for current hand
    is_valid_hand = false,
    hand_type = nil,  -- "set" or "sequence"
    confirm_button = {
      x = Constants.SCREEN_WIDTH / 2 - 100,
      y = Constants.SCREEN_HEIGHT - 100,
      width = 100,
      height = 40,
      enabled = false
    },
    done_button = {
      x = Constants.SCREEN_WIDTH / 2 + 20,
      y = Constants.SCREEN_HEIGHT - 100,
      width = 100,
      height = 40,
      enabled = true
    }
  }
  return setmetatable(instance, EndGameUI)
end

function EndGameUI:toggleCardSelection(card)
  -- Check if card is already selected
  for i, selected_card in ipairs(self.selected_cards) do
    if selected_card.id == card.id then
      -- Deselect
      table.remove(self.selected_cards, i)
      card.selected = false
      self:validateSelection()
      return
    end
  end

  -- Select card
  table.insert(self.selected_cards, card)
  card.selected = true
  self:validateSelection()
end

function EndGameUI:validateSelection()
  if #self.selected_cards >= 3 then
    if HandValidator.isValidSet(self.selected_cards) then
      self.is_valid_hand = true
      self.hand_type = "set"
      self.confirm_button.enabled = true
      return
    elseif HandValidator.isValidSequence(self.selected_cards) then
      self.is_valid_hand = true
      self.hand_type = "sequence"
      self.confirm_button.enabled = true
      return
    end
  end

  self.is_valid_hand = false
  self.hand_type = nil
  self.confirm_button.enabled = false
end

function EndGameUI:clearSelection()
  for _, card in ipairs(self.selected_cards) do
    card.selected = false
  end
  self.selected_cards = {}
  self.is_valid_hand = false
  self.hand_type = nil
  self.confirm_button.enabled = false
end

function EndGameUI:isPointInButton(x, y, button)
  return x >= button.x and x <= button.x + button.width and
         y >= button.y and y <= button.y + button.height
end

return EndGameUI
```

**Step 2: Commit**

```bash
git add views/end_game_ui.lua
git commit -m "feat: create EndGameUI for hand selection tracking

Add card selection, validation, and button state management."
```

---

## Task 15: Draw End Game UI

**Files:**
- Modify: `views/game_view.lua:400-500`

**Step 1: Require EndGameUI in main.lua**

Add to main.lua:

```lua
local EndGameUI = require("views/end_game_ui")

local end_game_ui

function love.load()
  -- ... existing code
  end_game_ui = EndGameUI.new()
end
```

**Step 2: Add drawEndGameUI() method to GameView**

Add method:

```lua
function GameView:drawEndGameUI(player, end_game_ui)
  -- Draw overlay background
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", 100, 100, Constants.SCREEN_WIDTH - 200, Constants.SCREEN_HEIGHT - 200)
  love.graphics.setColor(1, 1, 1)

  -- Draw title
  love.graphics.setFont(love.graphics.newFont(28))
  love.graphics.printf("Game Over! Form hands to reduce your score",
                       100, 120, Constants.SCREEN_WIDTH - 200, "center")
  love.graphics.setFont(love.graphics.newFont(16))

  -- Draw remaining cards
  love.graphics.printf("Your remaining cards:", 120, 180, 400, "left")

  local card_x = 120
  local card_y = 220

  for _, card in ipairs(player.hand) do
    -- Highlight if selected
    if card.selected then
      if end_game_ui.is_valid_hand then
        love.graphics.setColor(0, 1, 0, 0.5)  -- Green
      else
        love.graphics.setColor(1, 0, 0, 0.5)  -- Red
      end
      love.graphics.rectangle("fill", card_x - 5, card_y - 5,
                              Constants.CARD_WIDTH * 1.5 + 10,
                              Constants.CARD_HEIGHT * 1.5 + 10, 8)
      love.graphics.setColor(1, 1, 1)
    end

    self.card_renderer:drawCard(card, card_x, card_y, 0, 1.5)
    card.x = card_x
    card.y = card_y
    card_x = card_x + Constants.CARD_WIDTH * 1.5 + 10
  end

  -- Draw instruction
  love.graphics.printf("Select 3+ cards to form a hand",
                       120, card_y + Constants.CARD_HEIGHT * 1.5 + 20, 400, "left")

  -- Draw buttons
  self:drawButton(end_game_ui.confirm_button, "Confirm Hand")
  self:drawButton(end_game_ui.done_button, "Done")

  -- Draw formed hands
  love.graphics.printf("Formed hands:", 120, card_y + 200, 400, "left")

  local formed_y = card_y + 230
  for i, hand in ipairs(player.formed_hands_endgame) do
    local hand_str = hand.type .. ": "
    for j, card in ipairs(hand.cards) do
      hand_str = hand_str .. Constants.RANK_NAMES[card.rank] .. "♥ "
    end
    love.graphics.print(hand_str, 140, formed_y)
    formed_y = formed_y + 25
  end
end

function GameView:drawButton(button, text)
  if button.enabled then
    love.graphics.setColor(0.2, 0.6, 1)
  else
    love.graphics.setColor(0.3, 0.3, 0.3)
  end
  love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 5)

  love.graphics.setColor(1, 1, 1)
  love.graphics.printf(text, button.x, button.y + 12, button.width, "center")
end
```

**Step 3: Call drawEndGameUI() from main draw**

In GameView:draw():

```lua
function GameView:draw(game_state, end_game_ui)
  -- ... existing rendering

  -- Draw end game UI if in end game turn
  if game_state.end_game_substep == Constants.END_GAME_SUBSTEPS.END_GAME_TURN_HUMAN then
    self:drawEndGameUI(game_state.players[1], end_game_ui)
  end
end
```

**Step 4: Update love.draw() in main.lua**

Pass end_game_ui:

```lua
function love.draw()
  game_view:draw(game_controller.game_state, end_game_ui)
end
```

**Step 5: Test end game UI rendering**

Temporarily force end game state in love.load():

```lua
-- Temporary test: force end game
game_controller.game_state.current_state = Constants.STATES.ROUND_END
game_controller.game_state.end_game_substep = Constants.END_GAME_SUBSTEPS.END_GAME_TURN_HUMAN
```

Run:

```bash
love .
```

Expected: See end game overlay with cards and buttons

**Step 6: Remove temporary test code**

**Step 7: Commit**

```bash
git add views/game_view.lua main.lua
git commit -m "feat: render end game UI for hand formation

Draw overlay with cards, selection, and buttons."
```

---

## Task 16: Handle End Game Card Selection Input

**Files:**
- Modify: `controllers/input_controller.lua:150-200`

**Step 1: Add end game input handling**

In InputController, add method:

```lua
function InputController:handleEndGameInput(x, y, button, end_game_ui)
  local game_state = self.game_controller.game_state

  if game_state.end_game_substep ~= Constants.END_GAME_SUBSTEPS.END_GAME_TURN_HUMAN then
    return false
  end

  local player = game_state.players[1]

  -- Check card clicks
  for _, card in ipairs(player.hand) do
    if self:isPointInCard(x, y, card.x, card.y) then
      end_game_ui:toggleCardSelection(card)
      return true
    end
  end

  -- Check Confirm Hand button
  if end_game_ui:isPointInButton(x, y, end_game_ui.confirm_button) and
     end_game_ui.confirm_button.enabled then
    self:confirmEndGameHand(end_game_ui, player)
    return true
  end

  -- Check Done button
  if end_game_ui:isPointInButton(x, y, end_game_ui.done_button) then
    self:finishEndGameTurn()
    return true
  end

  return false
end

function InputController:confirmEndGameHand(end_game_ui, player)
  -- Create hand object
  local hand = {
    type = end_game_ui.hand_type,
    cards = {}
  }

  -- Copy selected cards to hand
  for _, card in ipairs(end_game_ui.selected_cards) do
    table.insert(hand.cards, card)
  end

  -- Add to formed hands
  table.insert(player.formed_hands_endgame, hand)

  -- Remove cards from player's hand
  for _, card in ipairs(end_game_ui.selected_cards) do
    player:removeCardFromHand(card)
  end

  -- Clear selection
  end_game_ui:clearSelection()
end

function InputController:finishEndGameTurn()
  -- Transition to next player's end game turn
  self.game_controller:advanceEndGameTurn()
end
```

**Step 2: Update main mousepressed() to call end game handler**

In main.lua:

```lua
function love.mousepressed(x, y, button)
  -- Try end game input first
  if input_controller:handleEndGameInput(x, y, button, end_game_ui) then
    return
  end

  -- Normal input handling
  input_controller:mousepressed(x, y, button)
end
```

**Step 3: Test card selection**

Force end game state, run:

```bash
love .
```

Test: Click cards to select/deselect
Expected: Cards highlight green (valid) or red (invalid)

Test: Click Confirm Hand with valid selection
Expected: Hand moves to formed hands list, cards removed

Test: Click Done
Expected: (will error for now, we'll implement advanceEndGameTurn next)

**Step 4: Commit**

```bash
git add controllers/input_controller.lua main.lua
git commit -m "feat: handle end game card selection input

Allow selecting cards, confirming hands, and finishing turn."
```

---

## Task 17: Implement End Game Turn Advancement

**Files:**
- Modify: `controllers/game_controller.lua:300-350`

**Step 1: Add advanceEndGameTurn() method**

Add to GameController:

```lua
function GameController:advanceEndGameTurn()
  local substep = self.game_state.end_game_substep

  if substep == Constants.END_GAME_SUBSTEPS.END_GAME_TURN_HUMAN then
    self.game_state.end_game_substep = Constants.END_GAME_SUBSTEPS.END_GAME_TURN_AI_1
    self.end_game_timer = 1.5  -- AI think time

  elseif substep == Constants.END_GAME_SUBSTEPS.END_GAME_TURN_AI_1 then
    self.game_state.end_game_substep = Constants.END_GAME_SUBSTEPS.END_GAME_TURN_AI_2
    self.end_game_timer = 1.5

  elseif substep == Constants.END_GAME_SUBSTEPS.END_GAME_TURN_AI_2 then
    self.game_state.end_game_substep = Constants.END_GAME_SUBSTEPS.END_GAME_TURN_AI_3
    self.end_game_timer = 1.5

  elseif substep == Constants.END_GAME_SUBSTEPS.END_GAME_TURN_AI_3 then
    self.game_state.end_game_substep = Constants.END_GAME_SUBSTEPS.REVEALING_ALL_HANDS
    self.end_game_timer = 2.0  -- Reveal delay

  elseif substep == Constants.END_GAME_SUBSTEPS.REVEALING_ALL_HANDS then
    self.game_state.end_game_substep = Constants.END_GAME_SUBSTEPS.CALCULATING_SCORES
    self.end_game_timer = 1.5

  elseif substep == Constants.END_GAME_SUBSTEPS.CALCULATING_SCORES then
    self.game_state.end_game_substep = Constants.END_GAME_SUBSTEPS.SHOWING_WINNER
    self.end_game_timer = 3.0  -- Show winner

  elseif substep == Constants.END_GAME_SUBSTEPS.SHOWING_WINNER then
    self.game_state.end_game_substep = Constants.END_GAME_SUBSTEPS.WAITING_FOR_RESTART
  end
end
```

**Step 2: Add end_game_timer to GameController**

In GameController.new():

```lua
function GameController.new()
  local instance = {
    game_state = GameState.new(),
    ai_controller = AIController.new(nil),
    ai_think_timer = 0,
    animating = false,
    animation_card = nil,
    end_game_timer = 0  -- NEW: timer for end game phases
  }
  -- ...
end
```

**Step 3: Update GameController:update() to handle end game timer**

In update() method:

```lua
function GameController:update(dt)
  -- ... existing code

  -- Handle end game progression
  if self.game_state.current_state == Constants.STATES.ROUND_END then
    if self.end_game_timer > 0 then
      self.end_game_timer = self.end_game_timer - dt
      if self.end_game_timer <= 0 then
        self:processEndGamePhase()
      end
    end
  end
end

function GameController:processEndGamePhase()
  local substep = self.game_state.end_game_substep

  -- Handle AI turns
  if substep == Constants.END_GAME_SUBSTEPS.END_GAME_TURN_AI_1 then
    self.ai_controller:formEndGameHands(self.game_state.players[2])
    self:advanceEndGameTurn()

  elseif substep == Constants.END_GAME_SUBSTEPS.END_GAME_TURN_AI_2 then
    self.ai_controller:formEndGameHands(self.game_state.players[3])
    self:advanceEndGameTurn()

  elseif substep == Constants.END_GAME_SUBSTEPS.END_GAME_TURN_AI_3 then
    self.ai_controller:formEndGameHands(self.game_state.players[4])
    self:advanceEndGameTurn()

  elseif substep == Constants.END_GAME_SUBSTEPS.REVEALING_ALL_HANDS then
    self:advanceEndGameTurn()

  elseif substep == Constants.END_GAME_SUBSTEPS.CALCULATING_SCORES then
    self:calculateFinalScores()
    self:advanceEndGameTurn()

  elseif substep == Constants.END_GAME_SUBSTEPS.SHOWING_WINNER then
    self:advanceEndGameTurn()
  end
end
```

**Step 4: Commit**

```bash
git add controllers/game_controller.lua
git commit -m "feat: implement end game turn advancement

Progress through all end game phases with timers."
```

---

## Task 18: Implement AI End Game Hand Formation

**Files:**
- Modify: `controllers/ai_controller.lua:100-200`

**Step 1: Add findLargestValidHand() helper**

Add to AIController:

```lua
function AIController:findLargestValidHand(cards)
  local HandValidator = require("utils/hand_validator")

  -- Try from largest to smallest (down to 3 cards)
  for len = #cards, 3, -1 do
    -- Generate all combinations of len cards
    local combinations = self:generateCombinations(cards, len)

    for _, combo in ipairs(combinations) do
      if HandValidator.isValidSet(combo) or HandValidator.isValidSequence(combo) then
        -- Determine type
        local hand_type = HandValidator.isValidSet(combo) and "set" or "sequence"
        return {cards = combo, type = hand_type}
      end
    end
  end

  return nil
end

function AIController:generateCombinations(cards, k)
  local combinations = {}

  local function helper(start, current)
    if #current == k then
      local combo = {}
      for _, card in ipairs(current) do
        table.insert(combo, card)
      end
      table.insert(combinations, combo)
      return
    end

    for i = start, #cards do
      table.insert(current, cards[i])
      helper(i + 1, current)
      table.remove(current)
    end
  end

  helper(1, {})
  return combinations
end
```

**Step 2: Add formEndGameHands() method**

Add to AIController:

```lua
function AIController:formEndGameHands(player)
  local remaining = {}
  for _, card in ipairs(player.hand) do
    table.insert(remaining, card)
  end

  while true do
    local best_hand = self:findLargestValidHand(remaining)
    if not best_hand then
      break
    end

    -- Add to formed hands
    table.insert(player.formed_hands_endgame, best_hand)

    -- Remove cards from remaining
    for _, formed_card in ipairs(best_hand.cards) do
      for i, card in ipairs(remaining) do
        if card.id == formed_card.id then
          table.remove(remaining, i)
          break
        end
      end
    end
  end

  -- Update player's hand to only remaining cards
  player.hand = remaining
end
```

**Step 3: Test AI hand formation**

Force AI end game turn, add debug output:

```lua
-- In processEndGamePhase() after formEndGameHands()
print("AI Player " .. player.id .. " formed " .. #player.formed_hands_endgame .. " hands")
```

Run:

```bash
love .
```

Expected: AI forms optimal hands from remaining cards

**Step 4: Remove debug output**

**Step 5: Commit**

```bash
git add controllers/ai_controller.lua
git commit -m "feat: implement AI end game hand formation

AI greedily forms largest valid hands from remaining cards."
```

---

## Task 19: Implement Score Calculation

**Files:**
- Modify: `controllers/game_controller.lua:400-450`

**Step 1: Add calculateFinalScores() method**

Add to GameController:

```lua
function GameController:calculateFinalScores()
  for _, player in ipairs(self.game_state.players) do
    local score = 0

    -- Only count remaining cards in hand (loose cards)
    for _, card in ipairs(player.hand) do
      score = score + Constants.CARD_POINTS[card.rank]
    end

    player.score = score
  end

  -- Find winner (lowest score)
  local winner = self.game_state.players[1]
  for _, player in ipairs(self.game_state.players) do
    if player.score < winner.score then
      winner = player
    end
  end

  self.game_state.winner = winner
end
```

**Step 2: Add winner field to GameState**

In GameState.new():

```lua
function GameState.new()
  local instance = {
    -- ... existing fields
    winner = nil  -- NEW: winning player
  }
  return setmetatable(instance, GameState)
end
```

**Step 3: Test score calculation**

Add debug output in calculateFinalScores():

```lua
for _, player in ipairs(self.game_state.players) do
  print("Player " .. player.id .. " score: " .. player.score)
end
print("Winner: Player " .. self.game_state.winner.id)
```

Force end game and verify scores are calculated correctly.

**Step 4: Remove debug output**

**Step 5: Commit**

```bash
git add controllers/game_controller.lua models/game_state.lua
git commit -m "feat: implement final score calculation

Calculate scores from loose cards and determine winner."
```

---

## Task 20: Draw Reveal All Hands Screen

**Files:**
- Modify: `views/game_view.lua:600-700`

**Step 1: Add drawRevealAllHands() method**

Add to GameView:

```lua
function GameView:drawRevealAllHands(game_state)
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.rectangle("fill", 50, 50, Constants.SCREEN_WIDTH - 100, Constants.SCREEN_HEIGHT - 100)
  love.graphics.setColor(1, 1, 1)

  love.graphics.setFont(love.graphics.newFont(24))
  love.graphics.printf("All Hands Revealed", 50, 70, Constants.SCREEN_WIDTH - 100, "center")
  love.graphics.setFont(love.graphics.newFont(14))

  local y = 120

  for _, player in ipairs(game_state.players) do
    local player_name = player.type == "human" and "Player 1 (You)" or "Player " .. player.id .. " (AI)"
    love.graphics.print(player_name .. ":", 70, y)
    y = y + 25

    -- From game hands
    if #player.hands > 0 then
      love.graphics.print("  From game:", 90, y)
      y = y + 20
      for _, hand in ipairs(player.hands) do
        local hand_str = "    " .. hand.type .. ": "
        for _, card in ipairs(hand.cards or {hand.visible_card}) do
          hand_str = hand_str .. Constants.RANK_NAMES[card.rank] ..
                     self:getSuitSymbol(card.suit) .. " "
        end
        love.graphics.print(hand_str, 90, y)
        y = y + 20
      end
    end

    -- End game hands
    if #player.formed_hands_endgame > 0 then
      love.graphics.print("  End game:", 90, y)
      y = y + 20
      for _, hand in ipairs(player.formed_hands_endgame) do
        local hand_str = "    " .. hand.type .. ": "
        for _, card in ipairs(hand.cards) do
          hand_str = hand_str .. Constants.RANK_NAMES[card.rank] ..
                     self:getSuitSymbol(card.suit) .. " "
        end
        love.graphics.print(hand_str, 90, y)
        y = y + 20
      end
    end

    -- Remaining cards
    local remaining_str = "  Remaining: "
    for _, card in ipairs(player.hand) do
      remaining_str = remaining_str .. Constants.RANK_NAMES[card.rank] ..
                      self:getSuitSymbol(card.suit) .. " "
    end
    love.graphics.print(remaining_str, 90, y)
    y = y + 35
  end
end

function GameView:getSuitSymbol(suit)
  local symbols = {
    hearts = "♥",
    diamonds = "♦",
    clubs = "♣",
    spades = "♠"
  }
  return symbols[suit] or suit
end
```

**Step 2: Call from draw() when in REVEALING_ALL_HANDS**

In GameView:draw():

```lua
function GameView:draw(game_state, end_game_ui)
  -- ... existing rendering

  -- Draw reveal screen
  if game_state.end_game_substep == Constants.END_GAME_SUBSTEPS.REVEALING_ALL_HANDS then
    self:drawRevealAllHands(game_state)
  end
end
```

**Step 3: Test reveal screen**

Force REVEALING_ALL_HANDS state with some test hands, run:

```bash
love .
```

Expected: See all players' hands listed (game hands and end game hands)

**Step 4: Commit**

```bash
git add views/game_view.lua
git commit -m "feat: draw reveal all hands screen

Show all formed hands and remaining cards for all players."
```

---

## Task 21: Draw Calculating Scores Screen

**Files:**
- Modify: `views/game_view.lua:700-750`

**Step 1: Add drawCalculatingScores() method**

Add to GameView:

```lua
function GameView:drawCalculatingScores(game_state)
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.rectangle("fill", 50, 50, Constants.SCREEN_WIDTH - 100, Constants.SCREEN_HEIGHT - 100)
  love.graphics.setColor(1, 1, 1)

  love.graphics.setFont(love.graphics.newFont(28))
  love.graphics.printf("Final Scores", 50, 100, Constants.SCREEN_WIDTH - 100, "center")
  love.graphics.setFont(love.graphics.newFont(18))

  local y = 200

  for _, player in ipairs(game_state.players) do
    local player_name = player.type == "human" and "Player 1 (You)" or "Player " .. player.id

    -- Highlight lowest score in green
    if game_state.winner and player.id == game_state.winner.id then
      love.graphics.setColor(0, 1, 0)
    else
      love.graphics.setColor(1, 1, 1)
    end

    local score_str = player_name .. ": " .. player.score .. " pts"
    love.graphics.printf(score_str, 100, y, Constants.SCREEN_WIDTH - 200, "center")

    y = y + 40
  end

  love.graphics.setColor(1, 1, 1)
end
```

**Step 2: Call from draw() when in CALCULATING_SCORES**

In GameView:draw():

```lua
function GameView:draw(game_state, end_game_ui)
  -- ... existing rendering

  -- Draw scores screen
  if game_state.end_game_substep == Constants.END_GAME_SUBSTEPS.CALCULATING_SCORES then
    self:drawCalculatingScores(game_state)
  end
end
```

**Step 3: Test scores screen**

Force CALCULATING_SCORES state, run:

```bash
love .
```

Expected: See all players' scores, winner highlighted in green

**Step 4: Commit**

```bash
git add views/game_view.lua
git commit -m "feat: draw calculating scores screen

Display final scores with winner highlighted in green."
```

---

## Task 22: Draw Winner Screen

**Files:**
- Modify: `views/game_view.lua:750-850`

**Step 1: Add drawShowingWinner() method**

Add to GameView:

```lua
function GameView:drawShowingWinner(game_state)
  love.graphics.setColor(0, 0, 0, 0.9)
  love.graphics.rectangle("fill", 0, 0, Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)

  -- Pulsing glow effect
  local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 2)
  love.graphics.setColor(1, 0.843, 0, pulse)  -- Golden glow

  love.graphics.setFont(love.graphics.newFont(48))
  love.graphics.printf("WINNER!", 0, 150, Constants.SCREEN_WIDTH, "center")

  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(love.graphics.newFont(32))

  local winner = game_state.winner
  local winner_name = winner.type == "human" and "You Win!" or "Player " .. winner.id
  love.graphics.printf(winner_name, 0, 220, Constants.SCREEN_WIDTH, "center")

  love.graphics.setFont(love.graphics.newFont(24))
  love.graphics.printf(winner.score .. " points", 0, 270, Constants.SCREEN_WIDTH, "center")

  -- Rankings
  love.graphics.setFont(love.graphics.newFont(18))
  love.graphics.printf("Final Rankings:", 0, 350, Constants.SCREEN_WIDTH, "center")

  -- Sort players by score
  local sorted_players = {}
  for _, player in ipairs(game_state.players) do
    table.insert(sorted_players, player)
  end
  table.sort(sorted_players, function(a, b) return a.score < b.score end)

  local y = 390
  for i, player in ipairs(sorted_players) do
    local name = player.type == "human" and "Player 1 (You)" or "Player " .. player.id
    local rank_str = i .. ". " .. name .. " - " .. player.score .. " pts"
    love.graphics.printf(rank_str, 0, y, Constants.SCREEN_WIDTH, "center")
    y = y + 30
  end

  love.graphics.setColor(1, 1, 1)
end
```

**Step 2: Call from draw() when in SHOWING_WINNER**

In GameView:draw():

```lua
function GameView:draw(game_state, end_game_ui)
  -- ... existing rendering

  -- Draw winner screen
  if game_state.end_game_substep == Constants.END_GAME_SUBSTEPS.SHOWING_WINNER then
    self:drawShowingWinner(game_state)
  end
end
```

**Step 3: Test winner screen**

Force SHOWING_WINNER state with calculated scores, run:

```bash
love .
```

Expected: See pulsing "WINNER!" with rankings

**Step 4: Commit**

```bash
git add views/game_view.lua
git commit -m "feat: draw winner screen with rankings

Display winner with golden glow and full rankings."
```

---

## Task 23: Draw Waiting for Restart Screen

**Files:**
- Modify: `views/game_view.lua:850-900`

**Step 1: Add drawWaitingForRestart() method**

Add to GameView:

```lua
function GameView:drawWaitingForRestart(game_state)
  -- Keep winner screen visible, add restart prompt
  self:drawShowingWinner(game_state)

  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(love.graphics.newFont(20))
  love.graphics.printf("Press SPACE to start new round",
                       0, Constants.SCREEN_HEIGHT - 100,
                       Constants.SCREEN_WIDTH, "center")
  love.graphics.printf("Press ESC to quit",
                       0, Constants.SCREEN_HEIGHT - 60,
                       Constants.SCREEN_WIDTH, "center")
end
```

**Step 2: Call from draw() when in WAITING_FOR_RESTART**

In GameView:draw():

```lua
function GameView:draw(game_state, end_game_ui)
  -- ... existing rendering

  -- Draw restart prompt
  if game_state.end_game_substep == Constants.END_GAME_SUBSTEPS.WAITING_FOR_RESTART then
    self:drawWaitingForRestart(game_state)
  end
end
```

**Step 3: Commit**

```bash
git add views/game_view.lua
git commit -m "feat: draw waiting for restart screen

Add SPACE/ESC prompt over winner screen."
```

---

## Task 24: Handle Restart Input

**Files:**
- Modify: `main.lua:50-80`
- Modify: `controllers/game_controller.lua:500-550`

**Step 1: Add love.keypressed() callback**

In main.lua, add:

```lua
function love.keypressed(key)
  local game_state = game_controller.game_state

  if game_state.end_game_substep == Constants.END_GAME_SUBSTEPS.WAITING_FOR_RESTART then
    if key == "space" then
      game_controller:restartGame()
    elseif key == "escape" then
      love.event.quit()
    end
  end
end
```

**Step 2: Add restartGame() method to GameController**

Add to GameController:

```lua
function GameController:restartGame()
  -- Reset game state
  self.game_state = GameState.new()

  -- Create players
  for i = 1, 4 do
    local player_type = (i == 1) and "human" or "ai"
    local position = ({"bottom", "left", "top", "right"})[i]
    local player = Player.new(i, player_type, position)
    self.game_state:addPlayer(player)
  end

  -- Deal cards
  self.game_state:dealCards()

  -- Start first turn
  self.game_state.current_state = Constants.STATES.PLAYER_TURN
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.CHOOSE_ACTION

  -- Reset timers
  self.ai_think_timer = 0
  self.end_game_timer = 0
  self.animating = false
  self.animation_card = nil
end
```

**Step 3: Test restart**

Play through a full game to end, press SPACE:

```bash
love .
```

Expected: New game starts with fresh cards

Test: Press ESC at restart screen
Expected: Game quits

**Step 4: Commit**

```bash
git add main.lua controllers/game_controller.lua
git commit -m "feat: handle restart and quit input

SPACE restarts game, ESC quits from end screen."
```

---

## Task 25: Test Full End Game Flow

**Files:**
- Create: `tests/test_end_game_flow.md` (manual test script)

**Step 1: Create manual test script**

Create file documenting test procedure:

```markdown
# End Game Flow Manual Test

## Setup
1. Run: `love .`
2. Play until round ends (empty deck or empty hand)

## Test Steps

### Human End Game Turn
- [ ] End game UI appears with overlay
- [ ] Can click cards to select/deselect
- [ ] Invalid selections show red highlight
- [ ] Valid sets (3+ same rank) show green highlight
- [ ] Valid sequences (3+ consecutive, same suit) show green highlight
- [ ] Confirm Hand button only enabled when valid
- [ ] Confirmed hands appear in "Formed hands" list
- [ ] Cards removed from hand after confirming
- [ ] Can form multiple hands
- [ ] Done button transitions to AI turn

### AI End Game Turns
- [ ] Each AI player gets turn (1.5s delay)
- [ ] AI forms optimal hands from remaining cards
- [ ] Progression: AI_1 → AI_2 → AI_3 → Reveal

### Revealing All Hands
- [ ] Shows all players' hands (game + end game)
- [ ] Displays remaining loose cards
- [ ] Displays for 2 seconds

### Calculating Scores
- [ ] Shows scores for all players
- [ ] Scores calculated from loose cards only
- [ ] Lowest score highlighted in green
- [ ] Displays for 1.5 seconds

### Showing Winner
- [ ] "WINNER!" text with golden glow
- [ ] Winner name displayed
- [ ] Rankings shown (1st, 2nd, 3rd, 4th)
- [ ] Pulsing animation effect

### Waiting for Restart
- [ ] SPACE prompt displayed
- [ ] ESC prompt displayed
- [ ] SPACE starts new game
- [ ] ESC quits game

## Edge Cases
- [ ] No possible hands to form (all loose cards)
- [ ] Player with 0 cards (already won)
- [ ] All players have same score (tie)

## Pass Criteria
All checkboxes checked without errors or crashes.
```

**Step 2: Execute manual test**

Run through the test script:

```bash
love .
```

Work through each test step, checking off items.

**Step 3: Fix any issues found**

If bugs discovered, create fix commits.

**Step 4: Commit test documentation**

```bash
git add tests/test_end_game_flow.md
git commit -m "test: add manual end game flow test script

Document test procedure for full end game flow."
```

---

## Task 26: Update Design Doc with Implementation Notes

**Files:**
- Modify: `docs/plans/2025-11-13-bugs-and-features-design.md`

**Step 1: Add implementation notes section**

At end of design doc, add:

```markdown
## Implementation Notes

**Date Implemented:** 2025-11-13
**Total Tasks:** 26
**Implementation Time:** ~3-4 hours

### Key Decisions Made During Implementation

1. **Animation Blocking:** Input blocked during all animations to prevent race conditions
2. **End Game UI:** Modal overlay approach with card selection validation
3. **AI Hand Formation:** Greedy algorithm (largest first) provides good results
4. **Score Display:** Progressive reveal (reveal → calculate → winner) creates drama
5. **Restart Flow:** Simple SPACE/ESC input at end screen

### Files Modified/Created

**Modified:**
- `models/deck.lua` - Random seed
- `controllers/input_controller.lua` - Hover fix, animation blocking, end game input
- `controllers/game_controller.lua` - Animation methods, end game progression
- `controllers/ai_controller.lua` - End game hand formation
- `views/game_view.lua` - Visual indicators, end game screens
- `utils/constants.lua` - Animation and end game substates
- `models/game_state.lua` - End game tracking
- `models/player.lua` - formed_hands_endgame field
- `main.lua` - End game UI integration, keypressed

**Created:**
- `views/end_game_ui.lua` - Card selection state management
- `tests/test_end_game_flow.md` - Manual test script

### Known Issues / Future Work

- Animation paths are simple linear tweens (could add arcs)
- No sound effects yet
- End game hands always visible to player (no hidden info)
- AI hand formation could be smarter (evaluate point reduction)
```

**Step 2: Mark all checklist items complete**

Update Implementation Checklist section to mark all items ✅

**Step 3: Commit**

```bash
git add docs/plans/2025-11-13-bugs-and-features-design.md
git commit -m "docs: add implementation notes to design doc

Document implementation decisions and file changes."
```

---

## Task 27: Update README

**Files:**
- Modify: `README.md`

**Step 1: Read current README**

Review current state.

**Step 2: Update Implementation Status section**

Update "Implementation Status" section:

```markdown
## Implementation Status

✅ **Core Gameplay Complete** (Tasks 1-13)
- All models implemented and tested
- Full game flow with state machine
- Mouse controls with hover effects
- Simple AI opponents (draw and discard highest-value cards)

✅ **Bug Fixes** (2025-11-13)
- Fixed random seed issue - different shuffles each game
- Fixed hover detection - topmost card highlights correctly

✅ **Animation System** (2025-11-13)
- Draw animation: Card animates from deck to hand
- Discard animation: Card animates from hand to discard pile
- Input blocking during animations

✅ **Turn Indicators** (2025-11-13)
- Deck glow during draw phase (pulsing yellow)
- Hand cards glow during discard phase (blue highlight)
- Text indicator at top of screen

✅ **Interactive End Game** (2025-11-13)
- Turn-based hand formation for all players
- Human player UI with card selection and validation
- AI automatic hand formation algorithm
- Reveal sequence showing all hands
- Score calculation and winner display
- Restart with SPACE, quit with ESC

⏳ **Future Enhancements**
- Advanced AI with behavior trees
- Sound effects
- Multiple difficulty levels
- Save/load game state
```

**Step 3: Update Features section**

Update top "Features" list:

```markdown
## Features

- **1 Human vs 3 AI opponents**
- **Complete game rules** - Sets, sequences, scoring, win conditions
- **Mouse controls** - Click to draw and discard, hover effects on cards
- **Smooth animations** - Card movement with flux tween library
- **Visual turn indicators** - Glowing deck/cards, text prompts
- **Interactive end game** - Form hands to minimize score
- **MVC architecture** - Clean separation of models, views, and controllers
```

**Step 4: Commit**

```bash
git add README.md
git commit -m "docs: update README with new features

Document animations, indicators, and end game system."
```

---

## Final Task: Verification Run

**Step 1: Full game playthrough test**

Run the complete game:

```bash
love .
```

**Test checklist:**
- [ ] Game starts with different card shuffles
- [ ] Hover highlights correct (topmost) card
- [ ] Draw animation smooth (deck → hand)
- [ ] Discard animation smooth (hand → discard)
- [ ] Deck glows during draw phase
- [ ] Hand cards glow during discard phase
- [ ] Text indicator updates correctly
- [ ] End game UI appears when round ends
- [ ] Can form valid hands
- [ ] AI forms hands automatically
- [ ] Reveal screen shows all hands
- [ ] Scores calculated correctly
- [ ] Winner displayed with rankings
- [ ] SPACE restarts game
- [ ] ESC quits game

**Step 2: Verify all commits made**

Check git log:

```bash
git log --oneline
```

Expected: ~27 commits covering all tasks

**Step 3: Final summary commit**

```bash
git commit --allow-empty -m "feat: complete bugs and features implementation

Implemented:
- Bug fixes: random seed, hover detection
- Animations: draw and discard with input blocking
- Turn indicators: visual glows and text prompts
- End game: interactive hand formation with scoring

All 26 implementation tasks completed.
Fully tested and verified."
```

---

## Success Criteria

Implementation is complete when:

1. ✅ Both bugs fixed (random seed, hover detection)
2. ✅ Animations working smoothly with input blocking
3. ✅ Visual indicators guide player actions
4. ✅ Full end game flow functional (human + AI)
5. ✅ Score calculation and winner display working
6. ✅ Restart/quit functionality working
7. ✅ All manual tests pass
8. ✅ Documentation updated

**Estimated Time:** 3-4 hours for experienced developer

**Testing Focus:** End game flow is most complex, requires thorough testing
