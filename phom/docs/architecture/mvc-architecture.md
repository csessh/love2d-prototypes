# MVC Architecture Documentation

## Overview

This codebase follows the Model-View-Controller (MVC) architectural pattern to maintain clean separation of concerns between game logic, rendering, and user interaction.

## Core Principles

### Models (models/)
- **Responsibility**: Game state, business logic, and data structures
- **Dependencies**: Only other models and utilities
- **Rules**:
  - NO rendering properties (x, y, rotation, scale)
  - NO view dependencies
  - NO controller dependencies
  - Pure data and game logic only

### Views (views/)
- **Responsibility**: Rendering and visual presentation
- **Dependencies**: Models (read-only), utilities, CardRenderState
- **Rules**:
  - NEVER mutate model data
  - Read game state, but don't change it
  - Can mutate view-specific state (CardRenderState)
  - No game logic or state transitions

### Controllers (controllers/)
- **Responsibility**: Orchestration, state transitions, user input handling
- **Dependencies**: Models, views, utilities, animation system
- **Rules**:
  - Coordinate between models and views
  - Handle state transitions
  - Manage animations
  - Process user input

## Directory Structure

```
phom/
├── models/              # Game state and business logic
│   ├── card.lua         # Card data (rank, suit, id)
│   ├── deck.lua         # Deck operations
│   ├── game_state.lua   # Game state management
│   ├── meld.lua         # Meld validation
│   └── player.lua       # Player state
├── views/               # Rendering layer
│   ├── game_view.lua    # Main view orchestrator
│   ├── card_renderer.lua # Card drawing
│   └── card_render_state.lua # Rendering state management
├── controllers/         # Orchestration and input
│   ├── game_controller.lua   # Game flow orchestration
│   ├── input_controller.lua  # User input handling
│   └── ai_controller.lua     # AI logic
└── utils/               # Shared utilities
    ├── constants.lua    # Game constants
    └── layout_calculator.lua # Position calculations
```

## Key Design Decisions

### 1. CardRenderState (views/card_render_state.lua)

**Problem**: Card model had rendering properties (x, y, rotation, hover_offset_y, face_up) mixed with game data (rank, suit).

**Solution**: Separate rendering state from game data.

```lua
-- CardRenderState tracks visual properties per card ID
card_render_state:get_state(card.id) -- Returns {x, y, rotation, hover_offset_y, face_up}
```

**Benefits**:
- Card model contains only game data
- Animations modify rendering state, not card data
- Views can have temporary visual state without polluting models

**Temporary Workaround**: `card.face_up` is still set temporarily for CardRenderer compatibility. This will be removed once CardRenderer accepts face_up as a parameter.

### 2. LayoutCalculator (utils/layout_calculator.lua)

**Problem**: Position calculations duplicated across GameView, InputController, and GameController (150+ lines).

**Solution**: Centralized position calculation utility.

```lua
-- Single source of truth for card positions
LayoutCalculator.calculate_hand_positions(player, card_scale)
LayoutCalculator.calculate_next_card_position(player, card_scale)
LayoutCalculator.is_point_in_card(x, y, card_x, card_y, scale)
```

**Benefits**:
- Eliminates duplication
- Single place to fix position bugs
- Consistent positioning across all systems

**Implementation Detail**: Uses `Constants.CARD_WIDTH` for spacing (NOT `Constants.CARD_WIDTH * card_scale`) to maintain correct card spacing.

### 3. View-Controller Coupling Reduction

**Problem**: GameView received entire GameController, creating tight coupling.

**Solution**: Pass minimal animation state object.

```lua
-- main.lua
function love.draw()
  local animation_state = game_controller:get_animation_state()
  game_view:draw(game_controller.game_state, animation_state)
end

-- GameController
function GameController:get_animation_state()
  return {
    animating = self.animating,
    animation_card = self.animation_card,
    card_render_state = self.card_render_state,
  }
end
```

**Benefits**:
- Views only receive data they need
- Clear interface contract
- Easier to test and modify

## Common Anti-Patterns to Avoid

### ❌ DON'T: Add rendering properties to models
```lua
-- BAD: Card model with rendering state
card.x = 100
card.y = 200
card.rotation = math.pi / 2
```

### ✅ DO: Use CardRenderState for rendering properties
```lua
-- GOOD: Rendering state separate from card data
local render_state = card_render_state:get_state(card.id)
render_state.x = 100
render_state.y = 200
render_state.rotation = math.pi / 2
```

### ❌ DON'T: Mutate models in views
```lua
-- BAD: GameView changing game state
function GameView:draw_player(player)
  player.hand[1].face_up = true  -- NEVER do this!
end
```

### ✅ DO: Read models, mutate rendering state only
```lua
-- GOOD: Only update rendering state
function GameView:draw_player(player, card_render_state)
  local render_state = card_render_state:get_state(card.id)
  render_state.face_up = true  -- OK: view-specific state
end
```

### ❌ DON'T: Duplicate position calculations
```lua
-- BAD: Position logic scattered everywhere
local x = Constants.SCREEN_WIDTH / 2 - (#cards * Constants.CARD_WIDTH) / 2
```

### ✅ DO: Use LayoutCalculator
```lua
-- GOOD: Centralized position logic
local positions = LayoutCalculator.calculate_hand_positions(player, card_scale)
```

### ❌ DON'T: Pass entire controllers to views
```lua
-- BAD: View has access to everything
function GameView:draw(game_state, game_controller)
  game_controller:draw_card()  -- Views shouldn't call controller methods!
end
```

### ✅ DO: Pass minimal required state
```lua
-- GOOD: View only receives data it needs
function GameView:draw(game_state, animation_state)
  if animation_state.animating then
    -- Only read state, never call controller methods
  end
end
```

## Refactoring Checklist

When adding new features, ensure:

- [ ] Models contain only game data and logic
- [ ] No rendering properties (x, y, rotation, scale) in models
- [ ] Views read state but never mutate models
- [ ] Position calculations use LayoutCalculator
- [ ] Rendering state uses CardRenderState
- [ ] Controllers orchestrate, don't contain business logic
- [ ] Views receive minimal state, not entire controllers
- [ ] Animation targets CardRenderState, not card properties

## Constants Naming Convention

- Use `snake_case` for methods and variables
- Use `PascalCase` for classes
- Use `UPPER_CASE` for constants

## Animation System

All animations use the Flux library and target CardRenderState:

```lua
-- Animate rendering state, not card properties
local render_state = card_render_state:get_state(card.id)
Flux.to(render_state, Constants.ANIM_DRAW_DURATION_S, {
  x = target_x,
  y = target_y,
  rotation = target_rotation
})
```

## Testing Considerations

When writing tests:
- Models should be testable without any view dependencies
- Views should render correctly with mock game state
- Controllers should orchestrate without being tightly coupled to specific views

## Future Improvements

1. **Remove card.face_up workaround**: Update CardRenderer to accept face_up as parameter
2. **Extract animation system**: Consider creating AnimationController for better separation
3. **Event system**: Consider pub/sub pattern for decoupling state changes from reactions
4. **State machine**: Formalize game state transitions with explicit state machine

---

Last updated: 2025-11-18
Refactoring completed in commit: e11642a
