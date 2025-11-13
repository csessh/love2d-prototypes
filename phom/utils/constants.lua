local Constants = {}

-- Screen dimensions
Constants.SCREEN_WIDTH = 1280
Constants.SCREEN_HEIGHT = 720

-- Card dimensions
Constants.CARD_WIDTH = 71
Constants.CARD_HEIGHT = 96

-- Deck and discard pile positions
Constants.DECK_X = 400
Constants.DECK_Y = 300
Constants.DISCARD_X = 800
Constants.DISCARD_Y = 300

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
  ANIMATING_DRAW = "ANIMATING_DRAW",
  FORM_MELD = "FORM_MELD",
  DISCARD_PHASE = "DISCARD_PHASE",
  ANIMATING_DISCARD = "ANIMATING_DISCARD",
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
