# Phỏm Card Game Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a playable Phỏm card game prototype with 1 human vs 3 AI opponents using Love2D.

**Architecture:** MVC pattern with state machine for game flow, behavior tree for AI, flux library for animations.

**Tech Stack:** Love2D (Lua), flux tween library, card sprites

---

## Task 1: Project Configuration & Directory Structure

**Files:**
- Create: `conf.lua`
- Create: `main.lua`
- Create: `models/` directory
- Create: `controllers/` directory
- Create: `views/` directory
- Create: `assets/sprites/cards/` directory
- Create: `libraries/` directory
- Create: `utils/` directory

**Step 1: Create directory structure**

```bash
mkdir -p models controllers views assets/sprites/cards libraries utils
```

**Step 2: Create Love2D configuration**

Create `conf.lua`:
```lua
function love.conf(t)
  t.title = "Phỏm Card Game"
  t.version = "11.4"
  t.window.width = 1280
  t.window.height = 720
  t.window.resizable = false
end
```

**Step 3: Create minimal main.lua**

Create `main.lua`:
```lua
function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  print("Phỏm Card Game - Loading...")
end

function love.update(dt)
end

function love.draw()
  love.graphics.print("Phỏm Card Game", 10, 10)
end
```

**Step 4: Test the application runs**

Run: `love .` (from worktree directory)
Expected: Window opens with title, "Phỏm Card Game" text visible

**Step 5: Commit**

```bash
git add conf.lua main.lua
git commit -m "feat: initial Love2D project structure

Set up basic Love2D configuration and directory structure"
```

---

## Task 2: Download flux Tween Library

**Files:**
- Create: `libraries/flux.lua`

**Step 1: Download flux library**

Visit: https://github.com/rxi/flux
Download `flux.lua` to `libraries/flux.lua`

Or use curl:
```bash
curl -o libraries/flux.lua https://raw.githubusercontent.com/rxi/flux/master/flux.lua
```

**Step 2: Verify flux loads**

Modify `main.lua`:
```lua
local flux = require("libraries/flux")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  print("Phỏm Card Game - Loading...")
  print("Flux loaded:", flux ~= nil)
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.print("Phỏm Card Game", 10, 10)
end
```

**Step 3: Test flux loads without error**

Run: `love .`
Expected: Console shows "Flux loaded: true"

**Step 4: Commit**

```bash
git add libraries/flux.lua main.lua
git commit -m "feat: add flux animation library

Integrate flux for tween animations"
```

---

## Task 3: Constants Configuration

**Files:**
- Create: `utils/constants.lua`

**Step 1: Create constants file**

Create `utils/constants.lua`:
```lua
local Constants = {}

-- Screen dimensions
Constants.SCREEN_WIDTH = 1280
Constants.SCREEN_HEIGHT = 720

-- Card dimensions
Constants.CARD_WIDTH = 71
Constants.CARD_HEIGHT = 96

-- Card suits
Constants.SUITS = {"hearts", "diamonds", "clubs", "spades"}
Constants.SUIT_SYMBOLS = {
  hearts = "♥",
  diamonds = "♦",
  clubs = "♣",
  spades = "♠"
}

-- Card ranks (1-13, where 1=A, 11=J, 12=Q, 13=K)
-- Ace is LOWEST rank. A-2-3-4 valid, J-Q-K-A invalid (no wrap)
Constants.RANKS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
Constants.RANK_NAMES = {
  [1]="A", [2]="2", [3]="3", [4]="4", [5]="5", [6]="6",
  [7]="7", [8]="8", [9]="9", [10]="10",
  [11]="J", [12]="Q", [13]="K"
}

-- Card point values (Ace = 1 point)
Constants.CARD_POINTS = {
  [1]=1, [2]=2, [3]=3, [4]=4, [5]=5, [6]=6,
  [7]=7, [8]=8, [9]=9, [10]=10,
  [11]=11, [12]=12, [13]=13
}

-- Game states
Constants.STATES = {
  MENU = "MENU",
  DEALING = "DEALING",
  PLAYER_TURN = "PLAYER_TURN",
  AI_TURN = "AI_TURN",
  ROUND_END = "ROUND_END",
  GAME_OVER = "GAME_OVER"
}

-- Turn substeps
Constants.TURN_SUBSTEPS = {
  CHOOSE_ACTION = "CHOOSE_ACTION",
  FORM_MELD = "FORM_MELD",
  DISCARD_PHASE = "DISCARD_PHASE",
  CHECK_WIN = "CHECK_WIN"
}

-- Player positions
Constants.POSITIONS = {
  BOTTOM = "BOTTOM",  -- Human
  LEFT = "LEFT",      -- AI 1
  TOP = "TOP",        -- AI 2
  RIGHT = "RIGHT"     -- AI 3
}

-- Animation durations (seconds)
Constants.ANIM_DEAL = 0.3
Constants.ANIM_DRAW = 0.2
Constants.ANIM_DISCARD = 0.25
Constants.ANIM_MELD = 0.3

-- Fan layout
Constants.FAN_SPREAD_ANGLE = 30  -- degrees
Constants.FAN_RADIUS = 400

return Constants
```

**Step 2: Verify constants load**

Modify `main.lua`:
```lua
local flux = require("libraries/flux")
local Constants = require("utils/constants")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  print("Phỏm Card Game - Loading...")
  print("Flux loaded:", flux ~= nil)
  print("Constants loaded:", Constants ~= nil)
  print("Screen size:", Constants.SCREEN_WIDTH, "x", Constants.SCREEN_HEIGHT)
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.print("Phỏm Card Game", 10, 10)
end
```

**Step 3: Test constants load**

Run: `love .`
Expected: Console shows "Constants loaded: true" and screen dimensions

**Step 4: Commit**

```bash
git add utils/constants.lua main.lua
git commit -m "feat: add game constants configuration

Define card dimensions, game states, and config values"
```

---

## Task 4: Card Model

**Files:**
- Create: `models/card.lua`

**Step 1: Create Card model**

Create `models/card.lua`:
```lua
local Constants = require("utils/constants")

local Card = {}
Card.__index = Card

function Card.new(suit, rank)
  local instance = {
    suit = suit,
    rank = rank,
    id = suit .. "_" .. rank,
    x = 0,
    y = 0,
    rotation = 0,
    scale = 1,
    face_up = true
  }
  return setmetatable(instance, Card)
end

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

**Step 2: Test Card model manually**

Modify `main.lua` to test:
```lua
local flux = require("libraries/flux")
local Constants = require("utils/constants")
local Card = require("models/card")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  -- Test card creation
  local card = Card.new("hearts", 1)  -- Ace of Hearts
  print("Card created:", card)
  print("Point value:", card:getPointValue())
  print("Rank name:", card:getRankName())
  print("Suit symbol:", card:getSuitSymbol())
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.print("Phỏm Card Game", 10, 10)
end
```

**Step 3: Verify card creation**

Run: `love .`
Expected: Console shows "Card created: A♥", "Point value: 1", etc.

**Step 4: Revert main.lua test code**

```lua
local flux = require("libraries/flux")
local Constants = require("utils/constants")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  print("Phỏm Card Game - Loading...")
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.print("Phỏm Card Game", 10, 10)
end
```

**Step 5: Commit**

```bash
git add models/card.lua main.lua
git commit -m "feat: implement Card model

Add Card class with suit, rank, and point value methods"
```

---

## Task 5: Deck Model

**Files:**
- Create: `models/deck.lua`

**Step 1: Create Deck model**

Create `models/deck.lua`:
```lua
local Constants = require("utils/constants")
local Card = require("models/card")

local Deck = {}
Deck.__index = Deck

function Deck.new()
  local instance = {
    cards = {}
  }
  setmetatable(instance, Deck)
  instance:initialize()
  return instance
end

function Deck:initialize()
  self.cards = {}
  for _, suit in ipairs(Constants.SUITS) do
    for _, rank in ipairs(Constants.RANKS) do
      table.insert(self.cards, Card.new(suit, rank))
    end
  end
end

function Deck:shuffle()
  for i = #self.cards, 2, -1 do
    local j = math.random(i)
    self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
  end
end

function Deck:draw()
  if #self.cards == 0 then
    return nil
  end
  return table.remove(self.cards, 1)
end

function Deck:size()
  return #self.cards
end

function Deck:isEmpty()
  return #self.cards == 0
end

return Deck
```

**Step 2: Test Deck model**

Modify `main.lua`:
```lua
local flux = require("libraries/flux")
local Deck = require("models/deck")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  -- Test deck
  local deck = Deck.new()
  print("Deck size:", deck:size())

  deck:shuffle()
  print("After shuffle, size:", deck:size())

  local card1 = deck:draw()
  print("Drew card:", card1)
  print("Remaining:", deck:size())
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.print("Phỏm Card Game", 10, 10)
end
```

**Step 3: Verify deck operations**

Run: `love .`
Expected: "Deck size: 52", "After shuffle, size: 52", "Drew card: [some card]", "Remaining: 51"

**Step 4: Revert test code in main.lua**

```lua
local flux = require("libraries/flux")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  print("Phỏm Card Game - Loading...")
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.print("Phỏm Card Game", 10, 10)
end
```

**Step 5: Commit**

```bash
git add models/deck.lua main.lua
git commit -m "feat: implement Deck model

Add Deck class with shuffle, draw, and size operations"
```

---

## Task 6: MeldValidator Model

**Files:**
- Create: `models/meld_validator.lua`

**Step 1: Create MeldValidator**

Create `models/meld_validator.lua`:
```lua
local Constants = require("utils/constants")

local MeldValidator = {}

-- Check if cards form a valid set (3+ same rank, any suits)
function MeldValidator.isValidSet(cards)
  if #cards < 3 then
    return false
  end

  local first_rank = cards[1].rank
  for i = 2, #cards do
    if cards[i].rank ~= first_rank then
      return false
    end
  end

  return true
end

-- Check if cards form a valid sequence (3+ consecutive, same suit)
function MeldValidator.isValidSequence(cards)
  if #cards < 3 then
    return false
  end

  -- All must be same suit
  local first_suit = cards[1].suit
  for i = 2, #cards do
    if cards[i].suit ~= first_suit then
      return false
    end
  end

  -- Sort by rank
  local sorted = {}
  for _, card in ipairs(cards) do
    table.insert(sorted, card)
  end
  table.sort(sorted, function(a, b) return a.rank < b.rank end)

  -- Check consecutive (no wrap-around, Ace is high only)
  for i = 2, #sorted do
    if sorted[i].rank ~= sorted[i-1].rank + 1 then
      return false
    end
  end

  return true
end

-- Check if hand_cards + discard_card form valid meld
function MeldValidator.canFormMeld(hand_cards, discard_card)
  if not discard_card or #hand_cards < 2 then
    return false
  end

  local all_cards = {discard_card}
  for _, card in ipairs(hand_cards) do
    table.insert(all_cards, card)
  end

  return MeldValidator.isValidSet(all_cards) or MeldValidator.isValidSequence(all_cards)
end

-- Real-time validation for UI (returns meld type or nil)
function MeldValidator.validateMeldSelection(selected_cards, discard_card)
  if MeldValidator.canFormMeld(selected_cards, discard_card) then
    local all_cards = {discard_card}
    for _, card in ipairs(selected_cards) do
      table.insert(all_cards, card)
    end

    if MeldValidator.isValidSet(all_cards) then
      return "set"
    elseif MeldValidator.isValidSequence(all_cards) then
      return "sequence"
    end
  end

  return nil
end

return MeldValidator
```

**Step 2: Test MeldValidator**

Modify `main.lua`:
```lua
local flux = require("libraries/flux")
local Card = require("models/card")
local MeldValidator = require("models/meld_validator")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  -- Test valid set
  local set = {Card.new("hearts", 7), Card.new("diamonds", 7), Card.new("clubs", 7)}
  print("Valid set:", MeldValidator.isValidSet(set))

  -- Test valid sequence
  local seq = {Card.new("hearts", 6), Card.new("hearts", 7), Card.new("hearts", 8)}
  print("Valid sequence:", MeldValidator.isValidSequence(seq))

  -- Test invalid (Ace high wrap-around - should be invalid)
  local invalid = {Card.new("hearts", 13), Card.new("hearts", 1), Card.new("hearts", 2)}
  print("Invalid wrap K-A-2:", MeldValidator.isValidSequence(invalid))

  -- Test canFormMeld
  local hand = {Card.new("diamonds", 7), Card.new("clubs", 7)}
  local discard = Card.new("hearts", 7)
  print("Can form meld:", MeldValidator.canFormMeld(hand, discard))
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.print("Phỏm Card Game", 10, 10)
end
```

**Step 3: Verify validation logic**

Run: `love .`
Expected: "Valid set: true", "Valid sequence: true", "Invalid wrap: false", "Can form meld: true"

**Step 4: Revert test code**

```lua
local flux = require("libraries/flux")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  print("Phỏm Card Game - Loading...")
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.print("Phỏm Card Game", 10, 10)
end
```

**Step 5: Commit**

```bash
git add models/meld_validator.lua main.lua
git commit -m "feat: implement MeldValidator

Add validation for sets and sequences with Phỏm rules"
```

---

## Task 7: Player Model

**Files:**
- Create: `models/player.lua`

**Step 1: Create Player model**

Create `models/player.lua`:
```lua
local Constants = require("utils/constants")

local Player = {}
Player.__index = Player

function Player.new(id, player_type, position)
  local instance = {
    id = id,
    type = player_type,  -- "human" or "ai"
    position = position,  -- "BOTTOM", "LEFT", "TOP", "RIGHT"
    hand = {},
    melds = {},  -- {type="set"|"sequence", cards={}, visible_card=Card}
    meld_area_cards = {},  -- face-up discard cards taken
    score = 0
  }
  return setmetatable(instance, Player)
end

function Player:addCardToHand(card)
  table.insert(self.hand, card)
end

function Player:removeCardFromHand(card)
  for i, c in ipairs(self.hand) do
    if c.id == card.id then
      table.remove(self.hand, i)
      return true
    end
  end
  return false
end

function Player:hasCard(card)
  for _, c in ipairs(self.hand) do
    if c.id == card.id then
      return true
    end
  end
  return false
end

function Player:formMeld(meld_type, cards, visible_card)
  local meld = {
    type = meld_type,
    cards = cards,
    visible_card = visible_card
  }
  table.insert(self.melds, meld)
  table.insert(self.meld_area_cards, visible_card)

  -- Remove meld cards from hand (except visible card already removed)
  for _, card in ipairs(cards) do
    if card.id ~= visible_card.id then
      self:removeCardFromHand(card)
    end
  end
end

function Player:calculateScore()
  if #self.hand == 0 then
    return 0
  end

  local score = 0
  for _, card in ipairs(self.hand) do
    score = score + card:getPointValue()
  end
  return score
end

function Player:getHandSize()
  return #self.hand
end

function Player:isHandEmpty()
  return #self.hand == 0
end

return Player
```

**Step 2: Test Player model**

Modify `main.lua`:
```lua
local flux = require("libraries/flux")
local Card = require("models/card")
local Player = require("models/player")
local Constants = require("utils/constants")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  local player = Player.new(1, "human", Constants.POSITIONS.BOTTOM)
  print("Player created, hand size:", player:getHandSize())

  player:addCardToHand(Card.new("hearts", 1))  -- Ace = 1 pt
  player:addCardToHand(Card.new("spades", 13))  -- King = 13 pts
  print("After adding 2 cards, hand size:", player:getHandSize())
  print("Score:", player:calculateScore())  -- Should be 14
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.print("Phỏm Card Game", 10, 10)
end
```

**Step 3: Verify player operations**

Run: `love .`
Expected: "Player created, hand size: 0", "After adding 2 cards, hand size: 2", "Score: 14"

**Step 4: Revert test code**

**Step 5: Commit**

```bash
git add models/player.lua main.lua
git commit -m "feat: implement Player model

Add Player class with hand management and scoring"
```

---

## Task 8: GameState Model

**Files:**
- Create: `models/game_state.lua`

**Step 1: Create GameState model**

Create `models/game_state.lua`:
```lua
local Constants = require("utils/constants")
local Deck = require("models/deck")
local Player = require("models/player")

local GameState = {}
GameState.__index = GameState

function GameState.new()
  local instance = {
    deck = Deck.new(),
    discard_pile = {},
    players = {},
    current_player_index = 1,
    current_state = Constants.STATES.MENU,
    turn_substep = nil,
    selected_cards = {},
    round_number = 1,
    scores = {}
  }
  setmetatable(instance, GameState)
  instance:initializePlayers()
  return instance
end

function GameState:initializePlayers()
  self.players = {
    Player.new(1, "human", Constants.POSITIONS.BOTTOM),
    Player.new(2, "ai", Constants.POSITIONS.LEFT),
    Player.new(3, "ai", Constants.POSITIONS.TOP),
    Player.new(4, "ai", Constants.POSITIONS.RIGHT)
  }
end

function GameState:getCurrentPlayer()
  return self.players[self.current_player_index]
end

function GameState:nextPlayer()
  self.current_player_index = self.current_player_index % 4 + 1
end

function GameState:getTopDiscard()
  if #self.discard_pile == 0 then
    return nil
  end
  return self.discard_pile[#self.discard_pile]
end

function GameState:addToDiscard(card)
  table.insert(self.discard_pile, card)
end

function GameState:takeFromDiscard()
  if #self.discard_pile == 0 then
    return nil
  end
  return table.remove(self.discard_pile)
end

function GameState:isDeckEmpty()
  return self.deck:isEmpty()
end

function GameState:dealCards(cards_per_player)
  self.deck:shuffle()

  for i = 1, cards_per_player do
    for _, player in ipairs(self.players) do
      local card = self.deck:draw()
      if card then
        player:addCardToHand(card)
      end
    end
  end
end

function GameState:checkWinCondition()
  for _, player in ipairs(self.players) do
    if player:isHandEmpty() then
      return player
    end
  end
  return nil
end

function GameState:calculateAllScores()
  for _, player in ipairs(self.players) do
    self.scores[player.id] = player:calculateScore()
  end
end

return GameState
```

**Step 2: Test GameState**

Modify `main.lua`:
```lua
local flux = require("libraries/flux")
local GameState = require("models/game_state")

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  local game = GameState.new()
  print("Players created:", #game.players)
  print("Deck size:", game.deck:size())

  game:dealCards(9)  -- Deal 9 cards per player
  print("After dealing, deck size:", game.deck:size())
  print("Player 1 hand size:", game.players[1]:getHandSize())

  local current = game:getCurrentPlayer()
  print("Current player:", current.id, current.type)
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.print("Phỏm Card Game", 10, 10)
end
```

**Step 3: Verify game state**

Run: `love .`
Expected: "Players created: 4", "Deck size: 52", "After dealing, deck size: 16", "Player 1 hand size: 9", "Current player: 1 human"

**Step 4: Revert test code**

**Step 5: Commit**

```bash
git add models/game_state.lua main.lua
git commit -m "feat: implement GameState model

Add central game state with deck, players, and turn management"
```

---

## Task 9: Placeholder Card Sprites

**Files:**
- Create: `views/card_renderer.lua`

**Step 1: Create basic CardRenderer with placeholder graphics**

Create `views/card_renderer.lua`:
```lua
local Constants = require("utils/constants")

local CardRenderer = {}

function CardRenderer.new()
  local instance = {
    card_width = Constants.CARD_WIDTH,
    card_height = Constants.CARD_HEIGHT
  }
  return setmetatable(instance, {__index = CardRenderer})
end

function CardRenderer:drawCard(card, x, y, rotation, scale)
  rotation = rotation or 0
  scale = scale or 1

  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)
  love.graphics.scale(scale, scale)

  if card.face_up then
    self:drawFaceUp(card)
  else
    self:drawFaceDown()
  end

  love.graphics.pop()
end

function CardRenderer:drawFaceUp(card)
  -- White card background
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle("fill", -self.card_width/2, -self.card_height/2,
                          self.card_width, self.card_height, 5, 5)

  -- Black border
  love.graphics.setColor(0, 0, 0)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", -self.card_width/2, -self.card_height/2,
                          self.card_width, self.card_height, 5, 5)

  -- Determine color (red for hearts/diamonds, black for clubs/spades)
  if card.suit == "hearts" or card.suit == "diamonds" then
    love.graphics.setColor(0.8, 0, 0)
  else
    love.graphics.setColor(0, 0, 0)
  end

  -- Draw rank and suit
  local rank_text = card:getRankName()
  local suit_text = card:getSuitSymbol()
  love.graphics.print(rank_text, -self.card_width/2 + 5, -self.card_height/2 + 5)
  love.graphics.print(suit_text, -self.card_width/2 + 5, -self.card_height/2 + 25)

  -- Reset color
  love.graphics.setColor(1, 1, 1)
end

function CardRenderer:drawFaceDown()
  -- Blue card back
  love.graphics.setColor(0.2, 0.3, 0.6)
  love.graphics.rectangle("fill", -self.card_width/2, -self.card_height/2,
                          self.card_width, self.card_height, 5, 5)

  -- Border
  love.graphics.setColor(0, 0, 0)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", -self.card_width/2, -self.card_height/2,
                          self.card_width, self.card_height, 5, 5)

  -- Pattern
  love.graphics.setColor(0.3, 0.4, 0.7)
  for i = 0, 3 do
    love.graphics.line(-self.card_width/4 + i*15, -self.card_height/2,
                      -self.card_width/4 + i*15, self.card_height/2)
  end

  love.graphics.setColor(1, 1, 1)
end

return CardRenderer
```

**Step 2: Test card rendering**

Modify `main.lua`:
```lua
local flux = require("libraries/flux")
local Card = require("models/card")
local CardRenderer = require("views/card_renderer")

local renderer
local test_card

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  renderer = CardRenderer.new()
  test_card = Card.new("hearts", 1)
  test_card.x = 400
  test_card.y = 300
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  love.graphics.clear(0.2, 0.5, 0.2)
  renderer:drawCard(test_card, test_card.x, test_card.y, 0, 1)

  -- Draw face-down card
  local back_card = Card.new("spades", 2)
  back_card.face_up = false
  renderer:drawCard(back_card, 500, 300, 0, 1)
end
```

**Step 3: Verify rendering**

Run: `love .`
Expected: See white card with A♥ and blue card back side by side

**Step 4: Revert test code**

**Step 5: Commit**

```bash
git add views/card_renderer.lua main.lua
git commit -m "feat: implement CardRenderer with placeholder graphics

Add basic card rendering with face-up and face-down display"
```

---

## Task 10: GameView Layout

**Files:**
- Create: `views/game_view.lua`

**Step 1: Create GameView**

Create `views/game_view.lua`:
```lua
local Constants = require("utils/constants")
local CardRenderer = require("views/card_renderer")

local GameView = {}
GameView.__index = GameView

function GameView.new()
  local instance = {
    card_renderer = CardRenderer.new()
  }
  return setmetatable(instance, GameView)
end

function GameView:draw(game_state)
  -- Draw background
  love.graphics.clear(0.1, 0.4, 0.2)

  -- Draw deck
  self:drawDeck(game_state)

  -- Draw discard pile
  self:drawDiscardPile(game_state)

  -- Draw players
  for _, player in ipairs(game_state.players) do
    self:drawPlayer(player)
  end

  -- Draw UI
  self:drawUI(game_state)
end

function GameView:drawDeck(game_state)
  if not game_state.deck:isEmpty() then
    local deck_x = Constants.SCREEN_WIDTH / 2 - 100
    local deck_y = Constants.SCREEN_HEIGHT / 2

    local card = {face_up = false}
    self.card_renderer:drawCard(card, deck_x, deck_y, 0, 1)

    -- Draw count
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Deck: " .. game_state.deck:size(), deck_x - 30, deck_y + 60)
  end
end

function GameView:drawDiscardPile(game_state)
  local discard_x = Constants.SCREEN_WIDTH / 2 + 100
  local discard_y = Constants.SCREEN_HEIGHT / 2

  local top_card = game_state:getTopDiscard()
  if top_card then
    self.card_renderer:drawCard(top_card, discard_x, discard_y, 0, 1)
  else
    -- Empty discard placeholder
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", discard_x - Constants.CARD_WIDTH/2,
                           discard_y - Constants.CARD_HEIGHT/2,
                           Constants.CARD_WIDTH, Constants.CARD_HEIGHT, 5, 5)
    love.graphics.setColor(1, 1, 1)
  end

  love.graphics.print("Discard", discard_x - 30, discard_y + 60)
end

function GameView:drawPlayer(player)
  if player.position == Constants.POSITIONS.BOTTOM then
    self:drawBottomPlayer(player)
  elseif player.position == Constants.POSITIONS.LEFT then
    self:drawLeftPlayer(player)
  elseif player.position == Constants.POSITIONS.TOP then
    self:drawTopPlayer(player)
  elseif player.position == Constants.POSITIONS.RIGHT then
    self:drawRightPlayer(player)
  end
end

function GameView:drawBottomPlayer(player)
  local center_x = Constants.SCREEN_WIDTH / 2
  local center_y = Constants.SCREEN_HEIGHT - 150

  -- Draw hand as fan
  self:drawHandAsFan(player.hand, center_x, center_y, player.type == "human")

  -- Draw meld area
  local meld_x = 100
  local meld_y = Constants.SCREEN_HEIGHT - 100
  for i, card in ipairs(player.meld_area_cards) do
    self.card_renderer:drawCard(card, meld_x + (i-1) * 40, meld_y, 0, 0.6)
  end

  -- Player info
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("You - Cards: " .. player:getHandSize(), 20, Constants.SCREEN_HEIGHT - 30)
end

function GameView:drawLeftPlayer(player)
  local x = 100
  local y = Constants.SCREEN_HEIGHT / 2

  -- Draw face-down cards
  for i = 1, player:getHandSize() do
    local card = {face_up = false}
    self.card_renderer:drawCard(card, x + i * 15, y, 0, 0.8)
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.print("AI 1: " .. player:getHandSize(), x - 20, y - 80)
end

function GameView:drawTopPlayer(player)
  local center_x = Constants.SCREEN_WIDTH / 2
  local y = 100

  -- Draw face-down cards
  for i = 1, player:getHandSize() do
    local card = {face_up = false}
    self.card_renderer:drawCard(card, center_x + (i - player:getHandSize()/2) * 40, y, 0, 0.8)
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.print("AI 2: " .. player:getHandSize(), center_x - 30, y - 60)
end

function GameView:drawRightPlayer(player)
  local x = Constants.SCREEN_WIDTH - 100
  local y = Constants.SCREEN_HEIGHT / 2

  -- Draw face-down cards
  for i = 1, player:getHandSize() do
    local card = {face_up = false}
    self.card_renderer:drawCard(card, x - i * 15, y, 0, 0.8)
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.print("AI 3: " .. player:getHandSize(), x - 50, y - 80)
end

function GameView:drawHandAsFan(cards, center_x, center_y, face_up)
  if #cards == 0 then return end

  local fan_spread = Constants.FAN_SPREAD_ANGLE
  local spacing = fan_spread / math.max(1, #cards - 1)

  for i, card in ipairs(cards) do
    local angle_offset = -fan_spread/2 + (i-1) * spacing
    local angle_rad = math.rad(angle_offset)

    local x = center_x + math.sin(angle_rad) * 50
    local y = center_y - (1 - math.abs(angle_rad) * 2) * 20

    card.face_up = face_up
    self.card_renderer:drawCard(card, x, y, angle_rad, 1)
  end
end

function GameView:drawUI(game_state)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Round: " .. game_state.round_number, 10, 10)
  love.graphics.print("State: " .. game_state.current_state, 10, 30)
end

return GameView
```

**Step 2: Test GameView with GameState**

Modify `main.lua`:
```lua
local flux = require("libraries/flux")
local GameState = require("models/game_state")
local GameView = require("views/game_view")

local game_state
local game_view

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  game_state = GameState.new()
  game_state:dealCards(9)

  game_view = GameView.new()
end

function love.update(dt)
  flux.update(dt)
end

function love.draw()
  game_view:draw(game_state)
end
```

**Step 3: Verify layout**

Run: `love .`
Expected: See game table with deck, empty discard, 4 players positioned correctly with cards

**Step 4: Keep this as the main.lua for now**

**Step 5: Commit**

```bash
git add views/game_view.lua main.lua
git commit -m "feat: implement GameView with table layout

Add rendering for deck, discard pile, and 4 player positions"
```

---

## Task 11: GameController State Machine

**Files:**
- Create: `controllers/game_controller.lua`

**Step 1: Create GameController with state machine**

Create `controllers/game_controller.lua`:
```lua
local Constants = require("utils/constants")
local GameState = require("models/game_state")

local GameController = {}
GameController.__index = GameController

function GameController.new()
  local instance = {
    game_state = GameState.new(),
    animation_queue = {}
  }
  return setmetatable(instance, GameController)
end

function GameController:update(dt)
  -- Handle state machine
  if self.game_state.current_state == Constants.STATES.MENU then
    self:handleMenu()
  elseif self.game_state.current_state == Constants.STATES.DEALING then
    self:handleDealing()
  elseif self.game_state.current_state == Constants.STATES.PLAYER_TURN then
    self:handlePlayerTurn()
  elseif self.game_state.current_state == Constants.STATES.AI_TURN then
    self:handleAITurn()
  elseif self.game_state.current_state == Constants.STATES.ROUND_END then
    self:handleRoundEnd()
  elseif self.game_state.current_state == Constants.STATES.GAME_OVER then
    self:handleGameOver()
  end
end

function GameController:handleMenu()
  -- Auto-start for now
  self:startNewRound()
end

function GameController:startNewRound()
  self.game_state = GameState.new()
  self.game_state.current_state = Constants.STATES.DEALING
end

function GameController:handleDealing()
  -- Deal cards (no animation for now)
  self.game_state:dealCards(9)

  -- Add first card to discard pile
  local first_discard = self.game_state.deck:draw()
  if first_discard then
    self.game_state:addToDiscard(first_discard)
  end

  -- Move to first player turn
  self.game_state.current_state = Constants.STATES.PLAYER_TURN
  self.game_state.turn_substep = Constants.TURN_SUBSTEPS.CHOOSE_ACTION
end

function GameController:handlePlayerTurn()
  -- Input handled by InputController
  -- Just manage substeps here
end

function GameController:handleAITurn()
  -- AI logic handled by AIController
end

function GameController:handleRoundEnd()
  self.game_state:calculateAllScores()
  print("Round ended!")
  for _, player in ipairs(self.game_state.players) do
    print("Player " .. player.id .. " score:", self.game_state.scores[player.id])
  end
  self.game_state.current_state = Constants.STATES.GAME_OVER
end

function GameController:handleGameOver()
  -- Wait for restart
end

function GameController:drawCard()
  local card = self.game_state.deck:draw()
  if card then
    self.game_state:getCurrentPlayer():addCardToHand(card)
    self.game_state.turn_substep = Constants.TURN_SUBSTEPS.DISCARD_PHASE
  end
end

function GameController:discardCard(card)
  local current_player = self.game_state:getCurrentPlayer()
  if current_player:removeCardFromHand(card) then
    self.game_state:addToDiscard(card)
    self:endTurn()
  end
end

function GameController:endTurn()
  -- Check win condition
  local winner = self.game_state:checkWinCondition()
  if winner then
    self.game_state.current_state = Constants.STATES.ROUND_END
    return
  end

  -- Check if deck empty
  if self.game_state:isDeckEmpty() then
    self.game_state.current_state = Constants.STATES.ROUND_END
    return
  end

  -- Next player
  self.game_state:nextPlayer()

  local next_player = self.game_state:getCurrentPlayer()
  if next_player.type == "human" then
    self.game_state.current_state = Constants.STATES.PLAYER_TURN
    self.game_state.turn_substep = Constants.TURN_SUBSTEPS.CHOOSE_ACTION
  else
    self.game_state.current_state = Constants.STATES.AI_TURN
  end
end

return GameController
```

**Step 2: Integrate GameController into main.lua**

Modify `main.lua`:
```lua
local flux = require("libraries/flux")
local GameController = require("controllers/game_controller")
local GameView = require("views/game_view")

local game_controller
local game_view

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  game_controller = GameController.new()
  game_view = GameView.new()
end

function love.update(dt)
  flux.update(dt)
  game_controller:update(dt)
end

function love.draw()
  game_view:draw(game_controller.game_state)
end
```

**Step 3: Test state machine progression**

Run: `love .`
Expected: Game auto-starts, deals cards, shows "State: PLAYER_TURN" in UI

**Step 4: Commit**

```bash
git add controllers/game_controller.lua main.lua
git commit -m "feat: implement GameController state machine

Add game flow orchestration with state transitions"
```

---

## Task 12: InputController - Basic Mouse Handling

**Files:**
- Create: `controllers/input_controller.lua`

**Step 1: Create InputController**

Create `controllers/input_controller.lua`:
```lua
local Constants = require("utils/constants")

local InputController = {}
InputController.__index = InputController

function InputController.new(game_controller)
  local instance = {
    game_controller = game_controller,
    hovered_card = nil,
    selected_cards = {}
  }
  return setmetatable(instance, InputController)
end

function InputController:mousepressed(x, y, button)
  if button ~= 1 then return end  -- Only left click

  local game_state = self.game_controller.game_state

  if game_state.current_state == Constants.STATES.PLAYER_TURN then
    if game_state.turn_substep == Constants.TURN_SUBSTEPS.CHOOSE_ACTION then
      self:handleChooseAction(x, y)
    elseif game_state.turn_substep == Constants.TURN_SUBSTEPS.DISCARD_PHASE then
      self:handleDiscardPhase(x, y)
    end
  end
end

function InputController:handleChooseAction(x, y)
  local game_state = self.game_controller.game_state

  -- Check if clicked on deck
  local deck_x = Constants.SCREEN_WIDTH / 2 - 100
  local deck_y = Constants.SCREEN_HEIGHT / 2

  if self:isPointInCard(x, y, deck_x, deck_y) and not game_state:isDeckEmpty() then
    print("Clicked deck - drawing card")
    self.game_controller:drawCard()
    return
  end

  -- Check if clicked on hand card (for meld formation)
  -- TODO: Implement card selection for meld
end

function InputController:handleDiscardPhase(x, y)
  local game_state = self.game_controller.game_state
  local player = game_state:getCurrentPlayer()

  -- Check each card in hand
  local center_x = Constants.SCREEN_WIDTH / 2
  local center_y = Constants.SCREEN_HEIGHT - 150

  local fan_spread = Constants.FAN_SPREAD_ANGLE
  local spacing = fan_spread / math.max(1, #player.hand - 1)

  for i, card in ipairs(player.hand) do
    local angle_offset = -fan_spread/2 + (i-1) * spacing
    local angle_rad = math.rad(angle_offset)

    local card_x = center_x + math.sin(angle_rad) * 50
    local card_y = center_y - (1 - math.abs(angle_rad) * 2) * 20

    if self:isPointInCard(x, y, card_x, card_y) then
      print("Discarding card:", card)
      self.game_controller:discardCard(card)
      return
    end
  end
end

function InputController:isPointInCard(px, py, card_x, card_y)
  local half_w = Constants.CARD_WIDTH / 2
  local half_h = Constants.CARD_HEIGHT / 2

  return px >= card_x - half_w and px <= card_x + half_w and
         py >= card_y - half_h and py <= card_y + half_h
end

return InputController
```

**Step 2: Integrate InputController**

Modify `main.lua`:
```lua
local flux = require("libraries/flux")
local GameController = require("controllers/game_controller")
local InputController = require("controllers/input_controller")
local GameView = require("views/game_view")

local game_controller
local input_controller
local game_view

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")

  game_controller = GameController.new()
  input_controller = InputController.new(game_controller)
  game_view = GameView.new()
end

function love.update(dt)
  flux.update(dt)
  game_controller:update(dt)
end

function love.draw()
  game_view:draw(game_controller.game_state)
end

function love.mousepressed(x, y, button)
  input_controller:mousepressed(x, y, button)
end
```

**Step 3: Test basic interaction**

Run: `love .`
Expected: Can click deck to draw, then click a card in hand to discard

**Step 4: Commit**

```bash
git add controllers/input_controller.lua main.lua
git commit -m "feat: implement InputController for mouse input

Add deck drawing and card discarding functionality"
```

---

## Task 13: Basic AI Controller

**Files:**
- Create: `controllers/ai_controller.lua`

**Step 1: Create simple AI**

Create `controllers/ai_controller.lua`:
```lua
local Constants = require("utils/constants")
local MeldValidator = require("models/meld_validator")

local AIController = {}
AIController.__index = AIController

function AIController.new(game_controller)
  local instance = {
    game_controller = game_controller,
    think_timer = 0,
    think_duration = 1.0  -- AI waits 1 second before acting
  }
  return setmetatable(instance, AIController)
end

function AIController:update(dt)
  local game_state = self.game_controller.game_state

  if game_state.current_state == Constants.STATES.AI_TURN then
    self.think_timer = self.think_timer + dt

    if self.think_timer >= self.think_duration then
      self:makeMove()
      self.think_timer = 0
    end
  end
end

function AIController:makeMove()
  local game_state = self.game_controller.game_state
  local ai_player = game_state:getCurrentPlayer()

  -- Simple AI: just draw and discard
  -- TODO: Implement behavior tree

  -- Draw card
  local card = game_state.deck:draw()
  if card then
    ai_player:addCardToHand(card)
  end

  -- Discard highest point card (simple strategy)
  local highest_card = self:findHighestPointCard(ai_player.hand)
  if highest_card then
    ai_player:removeCardFromHand(highest_card)
    game_state:addToDiscard(highest_card)
  end

  self.game_controller:endTurn()
end

function AIController:findHighestPointCard(hand)
  if #hand == 0 then return nil end

  local highest = hand[1]
  for _, card in ipairs(hand) do
    if card:getPointValue() > highest:getPointValue() then
      highest = card
    end
  end

  return highest
end

return AIController
```

**Step 2: Integrate AI into GameController**

Modify `controllers/game_controller.lua`:
```lua
-- Add near top after requires
local AIController = require("controllers/ai_controller")

-- Modify GameController.new()
function GameController.new()
  local instance = {
    game_state = GameState.new(),
    animation_queue = {},
    ai_controller = nil  -- Will be set after creation
  }
  setmetatable(instance, GameController)
  instance.ai_controller = AIController.new(instance)
  return instance
end

-- Modify update method to include AI
function GameController:update(dt)
  -- Update AI
  self.ai_controller:update(dt)

  -- Handle state machine
  if self.game_state.current_state == Constants.STATES.MENU then
    self:handleMenu()
  elseif self.game_state.current_state == Constants.STATES.DEALING then
    self:handleDealing()
  elseif self.game_state.current_state == Constants.STATES.PLAYER_TURN then
    self:handlePlayerTurn()
  elseif self.game_state.current_state == Constants.STATES.AI_TURN then
    self:handleAITurn()
  elseif self.game_state.current_state == Constants.STATES.ROUND_END then
    self:handleRoundEnd()
  elseif self.game_state.current_state == Constants.STATES.GAME_OVER then
    self:handleGameOver()
  end
end
```

**Step 3: Test AI turns**

Run: `love .`
Expected: AI players take turns automatically after human player, discarding high-value cards

**Step 4: Commit**

```bash
git add controllers/ai_controller.lua controllers/game_controller.lua
git commit -m "feat: implement basic AI controller

Add simple AI that draws and discards highest-value cards"
```

---

## Session Progress Update - 2025-11-13

### Animation System Implementation (Completed)

**Tasks 1-13** from the original plan were completed in previous sessions. This session focused on implementing and debugging the animation system.

#### Completed Work:

**1. Card Draw/Discard Animation System**
- Implemented flux-based animation for card drawing from deck to player hands
- Implemented discard animation from hand to discard pile
- Added rotation animation for AI players (LEFT/RIGHT players rotate 90°)
- Cards animate smoothly with proper easing

**2. Animation State Management**
- Added `animating` flag and `animation_card` to GameController
- Created `ANIMATING_DRAW` and `ANIMATING_DISCARD` turn substeps
- Implemented animation completion callbacks
- Added proper state cleanup after animations

**3. Input Blocking During Animations**
- Block mouse input during active animations (both flag and substep checks)
- Block hover effects during animations
- Prevents race conditions and double-clicks

**4. Unified Draw/Discard Code Paths**
- Refactored so both human and AI players use same `GameController:drawCard()` and `discardCard()` methods
- Draw logic uses `getCurrentPlayer()` for consistency
- InputController delegates to GameController instead of duplicating logic

**5. AI Animation Timing Fix**
- AI now waits for draw animation to complete before discarding
- Added `waiting_for_animation` state to AIController
- AI chooses discard card AFTER draw completes (considers full hand)
- Proper turn flow: draw → animate → discard → animate → end turn

**6. Bug Fixes**
- Fixed: Cards staying face-down on discard pile (now flip to face_up)
- Fixed: Human player draw animation failing on subsequent turns (position calculation mismatch)
- Fixed: Card properties not being reset (hover_offset_y cleared on animation start)
- Fixed: Position calculations now match between GameView and animation targets

**7. All Player Positions Supported**
- BOTTOM (human): Cards at bottom, no rotation
- LEFT (AI): Cards on left side, 90° rotation
- TOP (AI): Cards at top, no rotation
- RIGHT (AI): Cards on right side, 90° rotation

#### Key Architecture Decisions:

1. **Single Source of Truth**: `GameController:drawCard()` handles all players via `getCurrentPlayer()`
2. **Animation-Driven State**: Turn substeps change when animations complete, not when they start
3. **Defensive State Checks**: Input blocking checks both `animating` flag AND turn substeps
4. **Consistent Positioning**: `calculateCardTargetPosition()` matches GameView rendering logic exactly

#### Files Modified:
- `phom/controllers/game_controller.lua`: Animation system, unified draw/discard
- `phom/controllers/input_controller.lua`: Input blocking, simplified deck click handling
- `phom/controllers/ai_controller.lua`: Animation-aware AI timing
- `phom/views/game_view.lua`: Store card positions/rotation for animations, render animation_card
- `phom/utils/constants.lua`: Accurate DECK_X/Y, DISCARD_X/Y positions

#### Commits:
- `7439be1`: Add animation state tracking fields
- `2311175`: Implement draw animation
- `e175bf5`: Block input during animations
- `7d5b000`, `93fa99b`: Fix animation card rendering
- `aa1db79`: Implement discard animation
- `f33271c`: Store card positions for accurate animations
- `a0abfbd`: Fix deck/discard position constants
- `1f49538`: Fix card teleporting (remove from hand before animating)
- `e235997`: Add AI player animations with rotation
- `e4c2ecf`: Ensure discarded cards are face-up
- `4a3f8af`: Clear card properties at animation start
- `0938bcd`: Fix human player draw animation position calculation
- `950c94d`: Unify draw/discard flow and fix AI animation timing

---

## Remaining Tasks Summary

The following tasks complete the implementation:

- **Task 14**: Card selection for meld formation (UI interaction)
- **Task 15**: Meld validation and formation logic
- **Task 16**: Advanced AI behavior tree
- **Task 17**: ~~Animation system with flux~~ ✅ **COMPLETED**
- **Task 18**: Card sprite integration (replace placeholders)
- **Task 19**: UI polish (buttons, highlights, feedback)
- **Task 20**: Round end screen and scoring display
- **Task 21**: Testing and bug fixes

Would you like me to continue with the detailed steps for these remaining tasks?
