# Phỏm Card Game

A playable prototype of Phỏm, a Vietnamese card game for 4 players, built with Love2D and Lua.

## Features

- **1 Human vs 3 AI opponents**
- **Complete game rules** - Sets, sequences, scoring, win conditions
- **Mouse controls** - Click to draw and discard, hover effects on cards
- **Smooth animations** - Hover effects using flux tween library
- **MVC architecture** - Clean separation of models, views, and controllers

## How to Play

### Running the Game

```bash
love .
```

Or from the repository root:
```bash
love phom
```

### Controls

- **Mouse**: Click deck to draw a card, click cards in your hand to discard
- **Hover**: Mouse over your cards to see them raise up

### Game Rules

**Goal**: Be the first to empty your hand, or have the lowest score when the deck runs out.

**Turn Structure**:
1. **Draw**: Click the deck to draw a card
2. **Discard**: Click a card in your hand to discard it

**Card Values** (for scoring):
- Ace = 1 point (lowest rank)
- 2-10 = Face value
- Jack = 11, Queen = 12, King = 13

**Valid Hands** (not yet implemented in UI):
- **Sets**: 3+ cards of same rank (e.g., 7♥ 7♦ 7♣)
- **Sequences**: 3+ consecutive cards, same suit (e.g., 6♥ 7♥ 8♥)
  - Ace is lowest: A-2-3-4 is valid
  - No wrap-around: J-Q-K-A is invalid

**Win Conditions**:
- Empty your hand = Instant win (0 points)
- Deck runs out = Lowest score wins

## Project Structure

```
phom/
├── models/              # Game logic
│   ├── card.lua         # Card with rank and suit
│   ├── deck.lua         # 52-card deck
│   ├── hand_validator.lua  # Validates sets and sequences
│   ├── player.lua       # Player with hand management
│   └── game_state.lua   # Central game state
├── views/               # Rendering
│   ├── card_renderer.lua   # Loads and draws card images
│   └── game_view.lua    # Main game table layout
├── controllers/         # Game flow
│   ├── game_controller.lua  # State machine
│   ├── input_controller.lua # Mouse handling
│   └── ai_controller.lua    # AI opponents
├── utils/
│   └── constants.lua    # Game configuration
├── libraries/
│   └── flux.lua         # Animation library
├── assets/sprites/cards/   # Card images
└── tests/               # Test files
```

## Development

### Architecture

- **MVC Pattern**: Models handle logic, Views handle rendering, Controllers handle flow
- **State Machine**: MENU → DEALING → PLAYER_TURN → AI_TURN → ROUND_END → GAME_OVER
- **Individual Card Images**: Each card is a separate PNG file (card_<suit>_<value>.png)

### Key Design Decisions

1. **Ace is Lowest**: Rank 1 (not 14), valid in A-2-3-4 sequences
2. **Terminology**: "Meld" renamed to "Hand" throughout codebase
3. **Horizontal Layout**: Player cards in a row at bottom (not fan layout)
4. **2x Card Scale**: All cards rendered at 2x size for visibility

### Testing

Run tests from the phom directory:

```bash
lua tests/test_hand_validator.lua
lua tests/test_player.lua
lua tests/test_game_state.lua
```

## Implementation Status

✅ **Core Gameplay Complete** (Tasks 1-13)
- All models implemented and tested
- Full game flow with state machine
- Mouse controls with hover effects
- Simple AI opponents (draw and discard highest-value cards)

⏳ **Future Enhancements**
- Hand formation UI (selecting cards to form sets/sequences)
- Advanced AI with behavior trees
- Card movement animations
- Sound effects
- Multiple difficulty levels

## Documentation

See `docs/plans/` for detailed design and implementation documentation.

## License

MIT
