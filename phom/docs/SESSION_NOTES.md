# Session Notes - Phỏm Card Game Development

## Current Session Summary (2025-11-17)

### What We Did Today

1. **Completed MVC Refactoring** ✅
   - All 6 tasks completed successfully
   - Created LayoutCalculator utility (centralized position calculations)
   - Created CardRenderState system (separated visual from game state)
   - Eliminated View mutations of Models
   - Extracted CARD_SCALE constant
   - Cleaned up View-Controller coupling
   - Added comprehensive architecture documentation

2. **Fixed Card Rendering Bug** ✅
   - Issue: Cards in discard pile rendering face down
   - Root cause: CardRenderer checking `card.face_up` (removed in MVC refactor)
   - Solution: Added `face_up` parameter to CardRenderer:drawCard()
   - Updated all drawCard() calls to pass face_up value
   - Removed obsolete `card.face_up` assignments

3. **Card Spacing Adjustment** ✅
   - Adjusted card spacing to have 5px overlap
   - Modified LayoutCalculator to use `Constants.CARD_WIDTH * card_scale - 5`

4. **Testing** ✅
   - All 68 unit tests passing (22 GameState + 23 HandValidator + 23 Player)
   - No regressions introduced

### Branch Status
- **Current Branch**: `refactor/mvc-separation`
- **Commits**: 7 commits (6 MVC tasks + 1 spacing adjustment + face_up fix)
- **Tests**: 68/68 passing
- **Ready For**: Visual testing and PR creation

---

## NEXT SESSION: Start Here! 🎯

### Step 1: Visual Testing and Card Spacing

The MVC refactoring is complete. Before creating the PR:

1. **Visual Test** the game:
   ```bash
   cd /home/tdo/Documents/love2d/phom
   love .
   ```

2. **Verify**:
   - ✅ Discard pile cards render face up
   - ✅ Human player cards render face up
   - ✅ AI player cards render face down
   - ⏳ Card spacing is appropriate (currently 5px overlap with scale=2)
   - ⏳ No visual glitches or regressions

3. **Adjust CARD_SCALE if needed**:
   - User identified that CARD_SCALE=2 may be causing cards to be too spread out
   - Consider changing to CARD_SCALE=1 in `utils/constants.lua`

### Step 2: Finalize and Merge MVC Refactoring

Once visual testing is complete:

1. **Create Pull Request**:
   ```bash
   # Already pushed to origin/refactor/mvc-separation
   # Create PR at: https://github.com/csessh/love2d-prototypes/pull/new/refactor/mvc-separation
   ```

2. **Merge to main**

### Step 3: Resume Feature Development

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

1. **Card Spacing with CARD_SCALE=2** (Investigating)
   - Cards may be too spread out with current scale
   - 5px overlap with scale=2 results in 137px spacing
   - User debugging to determine if scale should be 1 instead of 2

2. **RNG Predictability** (Deferred)
   - `math.random()` may produce same sequence
   - Needs proper entropy solution
   - Not blocking feature work

### Technical Debt

- [x] MVC refactoring - **COMPLETED** ✅
  - CardRenderState separates visual from game state
  - LayoutCalculator centralizes position logic
  - Views are now read-only
  - Models contain only game data
- [x] Unit tests for game logic - **COMPLETED** ✅ (68 tests passing)
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
- `card.lua` - Card data (suit, rank, id only - pure data) ✅
- `deck.lua` - Deck operations
- `player.lua` - Player state
- `game_state.lua` - Central game state
- `hand_validator.lua` - Meld validation

**Views**:
- `game_view.lua` - Main rendering (read-only) ✅
- `card_renderer.lua` - Card sprites
- `card_render_state.lua` - Visual state tracking (x, y, rotation, face_up) ✅

**Controllers**:
- `game_controller.lua` - State machine
- `input_controller.lua` - User input
- `ai_controller.lua` - AI logic

**Utils**:
- `constants.lua` - Game constants (includes CARD_SCALE)
- `layout_calculator.lua` - Position calculations (single source of truth) ✅

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

- `docs/architecture/mvc-architecture.md` - **MVC Architecture Guide** ✅
- `docs/plans/2025-11-13-mvc-refactoring-plan.md` - MVC Refactoring Plan (COMPLETED)
- `docs/plans/2025-11-13-phom-card-game-implementation.md` - Feature roadmap
- `docs/SESSION_NOTES.md` - This file

---

## Questions for Next Session

1. Should we change CARD_SCALE from 2 to 1 to reduce card spacing?
2. After fixing spacing, should we proceed with Task 14 (Animated Dealing) or Task 17 (Meld Area) first?
3. Should we consider adding a simple menu screen before continuing with features?

---

**Last Updated**: 2025-11-17
**Current Branch**: `refactor/mvc-separation`
**Next Action**: Visual test and adjust CARD_SCALE if needed, then merge PR
