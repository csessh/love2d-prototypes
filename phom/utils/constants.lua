local Constants = {}

Constants.SCREEN_WIDTH = 1280
Constants.SCREEN_HEIGHT = 720

Constants.CARD_WIDTH = 71
Constants.CARD_HEIGHT = 96
Constants.CARD_SCALE = 2

local spacing = 20
local total_width = (Constants.CARD_WIDTH * Constants.CARD_SCALE * 2) + spacing

Constants.DRAW_PILE_X = Constants.SCREEN_WIDTH / 2
  - total_width / 2
  + (Constants.CARD_WIDTH * Constants.CARD_SCALE / 2)
Constants.DRAW_PILE_Y = Constants.SCREEN_HEIGHT / 2

Constants.DISCARD_PILE_X = Constants.SCREEN_WIDTH / 2
  + total_width / 2
  - (Constants.CARD_WIDTH * Constants.CARD_SCALE / 2)
Constants.DISCARD_PILE_Y = Constants.SCREEN_HEIGHT / 2

Constants.SUITS = { "hearts", "diamonds", "clubs", "spades" }
Constants.SUIT_SYMBOLS = {
  hearts = "♥",
  diamonds = "♦",
  clubs = "♣",
  spades = "♠",
}

-- Card ranks (1-13, where 1=A, 11=J, 12=Q, 13=K)
-- Ace is LOWEST rank. A-2-3-4 valid, J-Q-K-A invalid (no wrap)
Constants.RANKS = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 }
Constants.RANK_NAMES = {
  [1] = "A",
  [2] = "2",
  [3] = "3",
  [4] = "4",
  [5] = "5",
  [6] = "6",
  [7] = "7",
  [8] = "8",
  [9] = "9",
  [10] = "10",
  [11] = "J",
  [12] = "Q",
  [13] = "K",
}

Constants.CARD_POINTS = {
  [1] = 1, -- Ace
  [2] = 2,
  [3] = 3,
  [4] = 4,
  [5] = 5,
  [6] = 6,
  [7] = 7,
  [8] = 8,
  [9] = 9,
  [10] = 10,
  [11] = 11,
  [12] = 12,
  [13] = 13,
}

Constants.STATES = {
  MENU = "MENU",
  DEALING = "DEALING",
  PLAYER_TURN = "PLAYER_TURN",
  AI_TURN = "AI_TURN",
  ROUND_END = "ROUND_END",
  GAME_OVER = "GAME_OVER",
}

Constants.TURN_SUBSTEPS = {
  CHOOSE_ACTION = "CHOOSE_ACTION",
  ANIMATING_DRAW = "ANIMATING_DRAW",
  FORM_MELD = "FORM_MELD",
  DISCARD_PHASE = "DISCARD_PHASE",
  ANIMATING_DISCARD = "ANIMATING_DISCARD",
  CHECK_WIN = "CHECK_WIN",
}

Constants.POSITIONS = {
  BOTTOM = "BOTTOM",
  LEFT = "LEFT",
  TOP = "TOP",
  RIGHT = "RIGHT",
}

Constants.MAX_PLAYER_COUNT = 4
Constants.ANIM_DEAL_DURATION_S = 0.3
Constants.ANIM_DRAW_DURATION_S = 0.33
Constants.ANIM_DISCARD_DURATION_S = 0.25

-- Discard pile configuration
Constants.DISCARD_OVERLAP_OFFSET = 30  -- Horizontal spacing between cards in pile

-- Discard pile anchor positions (base position for each player's pile)
Constants.DISCARD_PILE_POSITIONS = {
  BOTTOM = { x = 640, y = 420 },  -- Above player hand
  TOP = { x = 640, y = 300 },     -- Below player cards
  LEFT = { x = 400, y = 360 },    -- Right of player hand
  RIGHT = { x = 880, y = 360 }    -- Left of player hand
}
Constants.ANIM_MELD_DURATION_S = 0.3

return Constants
