# Session Notes - Phỏm Card Game Development

## Current Session Summary (2025-11-13)

### What We Did Today

1. **Reviewed MVC Architecture** ✅
   - Identified violations and anti-patterns
   - Found rendering state mixed into Models
   - Found Views mutating Models during draw
   - Found duplicated position logic across 3 files

2. **Created Task 17 in Feature Plan** ✅
   - Added "Player Meld Area and Individual Discard Piles"
   - Individual discard piles per player
   - Meld area visualization
   - Cards spread horizontally (not stacked)

3. **Created MVC Refactoring Plan** ✅
   - **CRITICAL**: Must be executed BEFORE resuming feature work
   - 6 tasks to clean up architecture
   - Estimated 3-4 hours
   - See: `docs/plans/2025-11-13-mvc-refactoring-plan.md`

---

## NEXT SESSION: Start Here! 🎯

### Step 1: Execute MVC Refactoring (PRIORITY 1)

**File**: `docs/plans/2025-11-13-mvc-refactoring-plan.md`

**Tasks**:
1. ✅ Create LayoutCalculator utility
2. ✅ Create CardRenderState system
3. ✅ Eliminate View mutations
4. ✅ Extract CARD_SCALE constant
5. ✅ Clean up View-Controller coupling
6. ✅ Add architecture documentation

**Time**: 3-4 hours

**Why First**: Prevents technical debt from accumulating. Clean foundation for future features.

### Step 2: Resume Feature Development (AFTER Refactoring)

**File**: `docs/plans/2025-11-13-phom-card-game-implementation.md`

**Next Features** (in order):
- Task 14: Animated Dealing Phase
- Task 15: Card Drag-and-Drop Reordering
- Task 16: Keyboard Shortcuts
- Task 17: Player Meld Area and Individual Discard Piles

---

## Project Status

### Completed Features ✅

- ✅ Basic game setup (Models, Views, Controllers)
- ✅ Card rendering with placeholders
- ✅ 4-player layout (BOTTOM, LEFT, TOP, RIGHT)
- ✅ Draw/discard animations with flux
- ✅ Human player input (click deck, discard cards)
- ✅ AI player turns (simple strategy)
- ✅ Hover effects on cards
- ✅ Turn indicators
- ✅ Random starting player
- ✅ Deck empty handling
- ✅ Win condition detection

### Known Issues ⚠️

1. **RNG Predictability** (Deferred)
   - `math.random()` may produce same sequence
   - Needs proper entropy solution
   - Not blocking feature work

2. **MVC Violations** (Addressed in refactoring plan)
   - Card model contains rendering properties
   - Views mutate models during draw
   - Position logic duplicated

### Technical Debt

- [ ] MVC refactoring (planned - see above)
- [ ] Add unit tests for game logic
- [ ] Replace placeholder card sprites
- [ ] Optimize rendering performance

---

## Architecture Overview

### Current Structure
```
phom/
├── models/          - Game data and logic
├── views/           - Rendering
├── controllers/     - Input and flow
├── utils/           - Shared utilities
└── libraries/       - Third-party (flux)
```

### Key Components

**Models**:
- `card.lua` - Card data (CURRENTLY: has x, y - TO FIX)
- `deck.lua` - Deck operations
- `player.lua` - Player state
- `game_state.lua` - Central game state
- `hand_validator.lua` - Meld validation

**Views**:
- `game_view.lua` - Main rendering (CURRENTLY: mutates cards - TO FIX)
- `card_renderer.lua` - Card sprites

**Controllers**:
- `game_controller.lua` - State machine
- `input_controller.lua` - User input
- `ai_controller.lua` - AI logic

**Utils**:
- `constants.lua` - Game constants

---

## Development Workflow

### Running the Game
```bash
cd /home/csessh/Documents/Love2D/phom
love .
```

### Git Workflow
```bash
# Current branch
git branch  # Should show: feature/phom-card-game

# Commit changes
git add <files>
git commit -m "type: description"

# View history
git log --oneline -10
```

### Commit Message Format
```
type: short description

Longer explanation if needed.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types**: feat, fix, refactor, docs, test, chore

---

## Testing Checklist

After any code changes:

- [ ] Game starts without errors
- [ ] Can draw card from deck
- [ ] Can discard card from hand
- [ ] Draw animation works
- [ ] Discard animation works
- [ ] Hover effect works
- [ ] AI players take turns
- [ ] Turn indicator shows correct player
- [ ] Game ends when deck empty
- [ ] No console errors

---

## Quick Reference

### File Paths
- Main game loop: `phom/main.lua`
- Game state: `phom/models/game_state.lua`
- Main view: `phom/views/game_view.lua`
- Game controller: `phom/controllers/game_controller.lua`
- Constants: `phom/utils/constants.lua`

### Important Constants
- `CARD_WIDTH = 71`
- `CARD_HEIGHT = 96`
- `CARD_SCALE = 2` (rendering scale)
- `SCREEN_WIDTH = 1280`
- `SCREEN_HEIGHT = 720`
- `DECK_X = 559, DECK_Y = 360`
- `DISCARD_X = 721, DISCARD_Y = 360`

### Game States
- `MENU` → `DEALING` → `PLAYER_TURN` / `AI_TURN` → `ROUND_END` → `GAME_OVER`

### Turn Substeps
- `CHOOSE_ACTION` → `ANIMATING_DRAW` → `DISCARD_PHASE` → `ANIMATING_DISCARD` → (next turn)

---

## Documentation Files

- `docs/plans/2025-11-13-mvc-refactoring-plan.md` - **READ THIS FIRST**
- `docs/plans/2025-11-13-phom-card-game-implementation.md` - Feature roadmap
- `docs/SESSION_NOTES.md` - This file

---

## Questions for Next Session

1. After MVC refactoring, should we proceed with Task 14 (Animated Dealing) or Task 17 (Meld Area) first?
2. Do we want to add unit tests before or after implementing more features?
3. Should we consider adding a simple menu screen before continuing?

---

**Last Updated**: 2025-11-13
**Current Branch**: `feature/phom-card-game`
**Next Action**: Execute MVC refactoring plan
