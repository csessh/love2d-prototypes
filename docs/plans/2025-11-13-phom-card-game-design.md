# Phỏm Card Game - Design Document

**Date:** 2025-11-13
**Project:** Phỏm Card Game Prototype
**Framework:** Love2D + Lua

## Project Overview

A playable prototype of Phỏm, a Vietnamese card game for 4 players. This implementation features 1 human player vs 3 AI opponents with rule-based strategy using behavior trees.

**Key Features:**
- MVC architecture with state machine for game flow
- Basic card sprites with fan-out hand layout
- Smooth animations using flux tween library
- Rule-based AI with point-minimization strategy
- Complete Phỏm rules implementation

## Game Rules Summary

### Setup
- Standard 52-card deck
- 4 players (1 human, 3 AI)
- Cards dealt to all players at start

### Turn Structure

Each turn consists of:

1. **Choose Action** (pick one):
   - **Draw from Deck**: Take top card from deck → go to discard phase
   - **Form Meld**: Take top discard card + form valid meld with hand cards

2. **Discard Phase**:
   - Must discard one card from hand (if hand not empty)
   - Discard goes to top of discard pile

### Meld Rules

**Valid Meld Types:**
- **Sets**: 3+ cards of same rank, any suits (e.g., 7♥ 7♦ 7♣)
- **Sequences**: 3+ consecutive ranks, same suit (e.g., 6♥ 7♥ 8♥)
  - Ace is HIGH only (Q-K-A valid, A-2-3 invalid)
  - No wrap-around sequences

**Meld Formation:**
- When forming meld, only the discard card is placed face-up in player's meld area
- Cards from hand used in meld are hidden until game end
- This creates hidden information gameplay

### Scoring System

**Card Point Values:**
- Ace = 1 point
- 2-10 = Face value
- Jack = 11 points
- Queen = 12 points
- King = 13 points

**Round End Conditions:**

1. **Immediate Win**: Player empties hand completely (0 points)
2. **Deck Empty**: When deck runs out, finish current turn then count points
   - Only cards in hand count (melds don't count)
   - Lowest score wins

## Architecture

### High-Level Structure

**MVC + State Machine Hybrid:**

- **Model Layer**: Game logic, data structures (GameState, Player, Card, Deck, MeldValidator)
- **View Layer**: Rendering (CardRenderer, GameView, UIElements)
- **Controller Layer**: Game flow orchestration (GameController with state machine, InputController, AIController)

### State Machine

```
MENU
  ↓
DEALING (animate cards being dealt)
  ↓
PLAYER_TURN
  ├─ CHOOSE_ACTION (waiting for draw/meld decision)
  ├─ FORM_MELD (selecting cards to form meld)
  ├─ DISCARD_PHASE (selecting card to discard)
  └─ CHECK_WIN (check if hand empty)
  ↓
AI_TURN_1 (same substates)
  ↓
AI_TURN_2
  ↓
AI_TURN_3
  ↓
(loop back to PLAYER_TURN or...)
  ↓
ROUND_END (someone emptied hand or deck empty)
  ↓
GAME_OVER (show scores)
```

## Data Models

### Card
```lua
Card = {
  suit = "hearts" | "diamonds" | "clubs" | "spades",
  rank = 2..14 (11=J, 12=Q, 13=K, 14=A),
  id = unique_id
}
```

### Player
```lua
Player = {
  id = 1..4,
  type = "human" | "ai",
  hand = {Card, ...},
  melds = {
    {type="set"|"sequence", cards={Card, ...}, visible_card=Card},
    ...
  },
  meld_area_cards = {Card, ...}  -- face-up discard cards
}
```

### GameState
```lua
GameState = {
  deck = {Card, ...},
  discard_pile = {Card, ...},
  players = {Player × 4},
  current_player_index = 1..4,
  current_state = "MENU" | "DEALING" | "PLAYER_TURN" | ...,
  turn_substep = "CHOOSE_ACTION" | "DISCARD_PHASE" | ...,
  selected_cards = {Card, ...},  -- UI tracking
  round_number = integer,
  scores = {player_id -> score}
}
```

### MeldValidator

**Functions:**
- `isValidSet(cards)` - Check if 3+ cards, all same rank
- `isValidSequence(cards)` - Check if 3+ consecutive ranks, same suit, Ace high only
- `canFormMeld(hand_cards, discard_card)` - Validate meld with discard
- `validateMeldSelection(selected_cards, discard_card)` - Real-time UI validation

## AI System

### Behavior Tree Structure

```
ROOT (Selector - try until one succeeds)
├─ Can Win Immediately? (Sequence)
│  ├─ Check if any meld empties hand completely
│  └─ Execute: Form that meld (instant win, 0 points)
│
├─ Can Form High-Value Meld? (Sequence)
│  ├─ Check if discard card forms meld with hand
│  ├─ Evaluate: Does meld reduce points significantly?
│  │   (Prioritize melds containing K, Q, J, 10)
│  └─ Execute: Take discard and form meld
│
├─ Should Draw from Deck? (Sequence)
│  ├─ Check: Discard card doesn't help reduce points
│  └─ Execute: Draw from deck
│
└─ Fallback
   └─ Execute: Draw from deck (safe default)
```

### AI Decision Functions

**findWinningMeld(hand, discard)**
- Returns meld that empties hand completely
- Instant win condition

**findBestMeldByPoints(hand, discard)**
- Returns meld with highest point reduction
- Prioritizes high-value cards (K=13, Q=12, J=11)

**evaluateMeldPointValue(meld)**
- Sums point values of all cards in meld
- Higher value = better meld to form

**chooseDiscardCard(hand)**
- Calculate "danger value" = points × isolation factor
- Priority 1: Discard isolated high cards (K, Q, J with no meld potential)
- Priority 2: Discard cards unlikely to form melds
- Avoid: Cards that could complete sequences or sets

**Example:**
```
Hand: K♠ Q♥ 7♣ 7♦ 5♠ 4♠ 3♠ A♥

Best discard: K♠ (13 points, isolated, no meld potential)
Second best: Q♥ (12 points, isolated)
Keep: 7♣ 7♦ (pair, potential set)
Keep: 5♠ 4♠ 3♠ (sequence potential)
Keep: A♥ (only 1 point, cheap to hold)
```

## View Layer

### Screen Layout

```
┌─────────────────────────────────────────┐
│  AI Player 2 (top)                      │
│  [Meld Area] [Hand: fan of face-down]  │
│                                         │
│ AI P1 (left)    [DECK] [DISCARD]  AI P3│
│ [Meld] [Fan]     back   7♥         [Fan]│
│                                    [Meld]│
│                                         │
│         Human Player (bottom)           │
│    [Meld Area: visible cards]          │
│  [Hand: fan of face-up cards]          │
│  Score: 0  |  Status: Your Turn        │
└─────────────────────────────────────────┘
```

### Card Rendering

**Sprites:**
- Card sprite images from `assets/sprites/cards/`
- Card back sprite for face-down cards
- Naming: `card_<suit>_<rank>.png` or sprite sheet

**Fan Layout Algorithm:**
```lua
function layoutHandAsFan(cards, center_x, center_y, is_face_up)
  local card_count = #cards
  local fan_spread_angle = 30  -- degrees total spread
  local card_spacing = fan_spread_angle / math.max(1, card_count - 1)

  for i, card in ipairs(cards) do
    local angle_offset = -fan_spread_angle/2 + (i-1) * card_spacing
    local angle_rad = math.rad(angle_offset)

    card.x = center_x + math.sin(angle_rad) * 50
    card.y = center_y - (1 - math.abs(angle_rad) * 2) * 20
    card.rotation = angle_rad
    card.face_up = is_face_up
  end
end
```

### Visual States

- **Normal**: Default sprite rendering
- **Selected**: Move up 20px, yellow glow/outline
- **Valid Meld**: Green tint overlay (rgba: 0, 1, 0, 0.3)
- **Invalid Meld**: Red tint overlay (rgba: 1, 0, 0, 0.3)
- **Hovering**: Scale 1.1x, slight upward movement

### Animation System

**Using flux tween library:**

```lua
-- Card dealing
flux.to(card, 0.3, {x = target_x, y = target_y})
  :ease("quartout")
  :oncomplete(dealNextCard)

-- Card draw from deck
flux.to(card, 0.2, {x = hand_x, y = hand_y, rotation = fan_angle})

-- Discard animation
flux.to(card, 0.25, {x = discard_x, y = discard_y})
  :ease("quadinout")

-- Meld formation
flux.to(card, 0.3, {x = meld_area_x, y = meld_area_y, scale = 1.1})
  :ease("backinout")
```

**Animation Queue:**
- Animations block game state progression
- Ensures smooth visual flow
- Example: Deal all cards → Wait for completion → Enable player input

## User Interactions

### Meld Formation Flow

1. Player clicks cards in hand to select/deselect
2. System validates continuously: selected cards + top discard card
3. Visual feedback:
   - Green highlight = valid meld
   - Red highlight = invalid meld
4. "Confirm Meld" button enabled only when valid
5. On confirm:
   - Discard card moves to player's meld area (face-up)
   - Selected cards removed from hand (hidden)
   - Proceed to discard phase (unless hand empty)

### Input Controls

**Mouse:**
- Click deck → Draw card (when in CHOOSE_ACTION)
- Click card in hand → Select/deselect for meld
- Click "Confirm Meld" → Form meld (when valid and in CHOOSE_ACTION)
- Click card in hand → Discard (when in DISCARD_PHASE)

**Keyboard (optional):**
- ESC → Pause/menu
- Numbers 1-9 → Quick select cards

## Project Structure

```
phom-card-game/
├── main.lua                    (Love2D entry point)
├── conf.lua                    (Love2D configuration)
├── libraries/
│   └── flux.lua               (Tween animation library)
├── models/
│   ├── card.lua               (Card data structure)
│   ├── deck.lua               (Deck management)
│   ├── player.lua             (Player model)
│   ├── game_state.lua         (GameState model)
│   └── meld_validator.lua     (Meld validation logic)
├── controllers/
│   ├── game_controller.lua    (State machine & orchestration)
│   ├── input_controller.lua   (Human player input)
│   └── ai_controller.lua      (AI behavior tree)
├── views/
│   ├── card_renderer.lua      (Card sprite rendering)
│   ├── game_view.lua          (Main view coordinator)
│   └── ui_elements.lua        (Buttons, text, panels)
├── assets/
│   ├── sprites/
│   │   ├── cards/             (Card sprite images)
│   │   └── card_back.png      (Card back sprite)
│   └── sounds/                (Future: audio files)
└── utils/
    └── constants.lua          (Game constants, config)
```

## Implementation Notes

### Module Dependencies
- **Models**: No dependencies (pure data/logic)
- **Controllers**: Depend on Models
- **Views**: Depend on Models (read-only)
- **main.lua**: Wires everything together

### Love2D Callbacks
```lua
function love.load()
  -- Initialize game controller, load assets
end

function love.update(dt)
  -- Update flux tweens, game controller
end

function love.draw()
  -- Call game_view to render everything
end

function love.mousepressed(x, y, button)
  -- Forward to input_controller
end
```

## Development Phases

### Phase 1: Core Models
- Card, Deck, Player data structures
- MeldValidator logic
- GameState management

### Phase 2: Basic Rendering
- Load card sprites
- Implement CardRenderer
- Basic table layout (no animations)

### Phase 3: Game Flow
- GameController with state machine
- Turn management
- Win condition checking

### Phase 4: Player Input
- InputController for mouse clicks
- Card selection UI
- Meld formation interface

### Phase 5: AI Implementation
- Basic AI behavior tree
- AI decision functions
- AI discard strategy

### Phase 6: Animations & Polish
- Flux integration
- Card movement animations
- Visual feedback (highlights, tints)

### Phase 7: Testing & Refinement
- Playtest full games
- Balance AI difficulty
- Bug fixes and edge cases

## Future Enhancements (Out of Scope)

- Sound effects
- Multiple AI difficulty levels
- Save/load game state
- Statistics tracking
- Network multiplayer
- Alternative rule variants
