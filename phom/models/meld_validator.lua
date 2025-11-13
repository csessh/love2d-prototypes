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

  -- Check consecutive (no wrap-around, Ace is low only)
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
