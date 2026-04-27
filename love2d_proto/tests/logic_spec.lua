package.path = package.path .. ";../src/?.lua;../src/?/?.lua;src/?.lua;src/?/?.lua"

love = love or {}
love.math = love.math or {
    setRandomSeed = function(seed) math.randomseed(seed) end,
    random = function(n) return math.random(n) end,
}

local Tile = require("src.game.tile")
local PatternMatcher = require("src.game.pattern_matcher")
local Scorer = require("src.game.scorer")
local BattleState = require("src.game.battle_state")

local function assert_eq(actual, expected, label)
    if actual ~= expected then
        error((label or "assert_eq") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function test_sequence_scores_60()
    local pattern = PatternMatcher.match({ Tile.new("man", 1), Tile.new("man", 2), Tile.new("man", 3) })
    assert_eq(pattern.id, "sequence", "sequence id")
    assert_eq(Scorer.score(pattern).final_score, 60, "sequence score")
end

local function test_pair_and_invalid()
    local pair = PatternMatcher.match({ Tile.new("pin", 8), Tile.new("pin", 8) })
    assert_eq(pair.id, "pair", "pair id")
    local invalid = PatternMatcher.match({ Tile.new("pin", 8), Tile.new("sou", 9) })
    assert_eq(invalid, nil, "invalid set")
end

local function test_battle_draws_to_thirteen()
    local battle = BattleState.new(300, 123)
    assert_eq(#battle.hand, 13, "initial hand")
    battle.hand = { Tile.new("man", 1), Tile.new("man", 2), Tile.new("man", 3) }
    local result = battle:play({ battle.hand[1], battle.hand[2], battle.hand[3] })
    assert_eq(result.valid, true, "play valid")
    assert_eq(battle.current_turn, 2, "turn advances")
    assert_eq(#battle.hand, 13, "refill")
end

test_sequence_scores_60()
test_pair_and_invalid()
test_battle_draws_to_thirteen()
print("logic_spec ok")
