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

-- Card ranks (2-14, where 11=J, 12=Q, 13=K, 14=A)
Constants.RANKS = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}
Constants.RANK_NAMES = {
  [2]="2", [3]="3", [4]="4", [5]="5", [6]="6",
  [7]="7", [8]="8", [9]="9", [10]="10",
  [11]="J", [12]="Q", [13]="K", [14]="A"
}

-- Card point values
Constants.CARD_POINTS = {
  [2]=2, [3]=3, [4]=4, [5]=5, [6]=6,
  [7]=7, [8]=8, [9]=9, [10]=10,
  [11]=11, [12]=12, [13]=13, [14]=1  -- Ace = 1
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
