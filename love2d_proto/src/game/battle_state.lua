local Tile = require("src.game.tile")
local PatternMatcher = require("src.game.pattern_matcher")
local Scorer = require("src.game.scorer")

local BattleState = {}
BattleState.__index = BattleState

function BattleState.new(target_score, seed)
    local self = setmetatable({}, BattleState)
    self.max_turns = 4
    self.target_score = target_score or 300
    self.total_score = 0
    self.current_turn = 1
    self.wall = Tile.wall(seed or 42)
    self.hand = {}
    self.discard = {}
    self:draw_to_full()
    return self
end

function BattleState:draw()
    return table.remove(self.wall)
end

function BattleState:draw_to_full()
    while #self.hand < 13 and #self.wall > 0 do
        self.hand[#self.hand + 1] = self:draw()
    end
    table.sort(self.hand, Tile.compare)
end

function BattleState:preview(selected)
    local pattern = PatternMatcher.match(selected)
    return Scorer.score(pattern)
end

function BattleState:play(selected)
    if self.current_turn > self.max_turns then return { valid = false, reason = "battle_finished" } end
    local pattern = PatternMatcher.match(selected)
    if not pattern then return { valid = false, reason = "invalid_set" } end
    local score = Scorer.score(pattern)
    for _, selected_tile in ipairs(selected) do
        for i, hand_tile in ipairs(self.hand) do
            if hand_tile == selected_tile then
                table.insert(self.discard, hand_tile)
                table.remove(self.hand, i)
                break
            end
        end
    end
    self.total_score = self.total_score + score.final_score
    self.current_turn = self.current_turn + 1
    self:draw_to_full()
    score.valid = true
    return score
end

return BattleState
