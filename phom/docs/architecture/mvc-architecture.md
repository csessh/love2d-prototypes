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
  local card = self.game_state.deck:draw()
  local player = self.game_state:getCurrentPlayer()
  player:addCardToHand(card)
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
  return {suit = suit, rank = rank, x = 0, y = 0}
end
```

### ❌ Views Mutating Models
```lua
-- BAD: View writing to model
function GameView:draw(game_state)
  for _, card in ipairs(player.hand) do
    card.x = calculate_x()
  end
end
```

### ❌ Controllers with Business Logic
```lua
-- BAD: Controller duplicating scoring logic
function GameController:endTurn()
  local score = 0
  for _, card in ipairs(player.hand) do
    score = score + card.rank
  end
end
```

### ❌ Position Calculation Duplication
```lua
-- BAD: Same formula in multiple files
-- GameView.lua:
local x = center_x + (i - 1) * spacing

-- GameController.lua:
local x = center_x + (i - 1) * spacing

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
