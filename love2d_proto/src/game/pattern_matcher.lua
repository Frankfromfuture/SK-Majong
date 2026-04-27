local Tile = require("src.game.tile")

local PatternMatcher = {}

PatternMatcher.patterns = {
    { id = "yakuman", display = "YAKUMAN", base_score = 500, mult = 10, tile_count = 7 },
    { id = "chinitsu_group", display = "PURE FLUSH", base_score = 200, mult = 6, tile_count = 5 },
    { id = "iitsu", display = "FULL STRAIGHT", base_score = 150, mult = 5, tile_count = 9 },
    { id = "kan", display = "QUAD", base_score = 100, mult = 4, tile_count = 4 },
    { id = "iipeikou", display = "DOUBLE SEQUENCE", base_score = 80, mult = 3, tile_count = 6 },
    { id = "sanshoku_set", display = "THREE COLOR SET", base_score = 50, mult = 3, tile_count = 3 },
    { id = "two_pairs", display = "TWO PAIRS", base_score = 40, mult = 2, tile_count = 4 },
    { id = "sequence", display = "SEQUENCE", base_score = 30, mult = 2, tile_count = 3 },
    { id = "triplet", display = "TRIPLET", base_score = 30, mult = 2, tile_count = 3 },
    { id = "taatsu", display = "WAIT", base_score = 15, mult = 1, tile_count = 2 },
    { id = "pair", display = "PAIR", base_score = 10, mult = 1, tile_count = 2 },
    { id = "single", display = "SINGLE", base_score = 5, mult = 1, tile_count = 1 },
}

local function sorted_copy(tiles)
    local out = {}
    for i, tile in ipairs(tiles) do out[i] = tile end
    table.sort(out, Tile.compare)
    return out
end

local function all_same_tile(tiles)
    if #tiles == 0 then return false end
    local key = tiles[1]:key()
    for _, tile in ipairs(tiles) do if tile:key() ~= key then return false end end
    return true
end

local function all_same_suit(tiles)
    if #tiles == 0 then return false end
    local suit = tiles[1].suit
    for _, tile in ipairs(tiles) do if tile.suit ~= suit then return false end end
    return true
end

local function ranks(tiles)
    local r = {}
    for _, tile in ipairs(tiles) do r[#r + 1] = tile.rank end
    table.sort(r)
    return r
end

local function counts_by_tile(tiles)
    local counts = {}
    for _, tile in ipairs(tiles) do counts[tile:key()] = (counts[tile:key()] or 0) + 1 end
    return counts
end

local function counts_by_rank(tiles)
    local counts = {}
    for _, tile in ipairs(tiles) do counts[tile.rank] = (counts[tile.rank] or 0) + 1 end
    return counts
end

local function is_pair(tiles) return #tiles == 2 and all_same_tile(tiles) end
local function is_taatsu(tiles) return #tiles == 2 and all_same_suit(tiles) and math.abs(tiles[1].rank - tiles[2].rank) == 1 end
local function is_triplet(tiles) return #tiles == 3 and all_same_tile(tiles) end

local function is_sequence(tiles)
    if #tiles ~= 3 or not all_same_suit(tiles) then return false end
    local r = ranks(tiles)
    return r[1] + 1 == r[2] and r[2] + 1 == r[3]
end

local function is_two_pairs(tiles)
    if #tiles ~= 4 then return false end
    local groups = 0
    for _, count in pairs(counts_by_tile(tiles)) do
        if count ~= 2 then return false end
        groups = groups + 1
    end
    return groups == 2
end

local function is_sanshoku_set(tiles)
    if #tiles ~= 3 then return false end
    local rank = tiles[1].rank
    local suits = {}
    for _, tile in ipairs(tiles) do
        if tile.rank ~= rank then return false end
        suits[tile.suit] = true
    end
    return suits.man and suits.pin and suits.sou
end

local function is_iipeikou(tiles)
    if #tiles ~= 6 or not all_same_suit(tiles) then return false end
    local counts = counts_by_rank(tiles)
    local r = {}
    for rank, count in pairs(counts) do
        if count ~= 2 then return false end
        r[#r + 1] = rank
    end
    table.sort(r)
    return #r == 3 and r[1] + 1 == r[2] and r[2] + 1 == r[3]
end

local function is_kan(tiles) return #tiles == 4 and all_same_tile(tiles) end

local function is_iitsu(tiles)
    if #tiles ~= 9 or not all_same_suit(tiles) then return false end
    local r = ranks(tiles)
    for i = 1, 9 do if r[i] ~= i then return false end end
    return true
end

local function is_chinitsu_group(tiles) return #tiles == 5 and all_same_suit(tiles) end

local function subtract_subset(tiles, subset)
    local result = {}
    for _, tile in ipairs(tiles) do result[#result + 1] = tile end
    for _, selected in ipairs(subset) do
        for i, tile in ipairs(result) do
            if tile:equals(selected) then table.remove(result, i); break end
        end
    end
    return result
end

local function is_yakuman(tiles)
    if #tiles ~= 7 then return false end
    for key, count in pairs(counts_by_tile(tiles)) do
        if count >= 2 then
            local pair = {}
            for _, tile in ipairs(tiles) do
                if tile:key() == key and #pair < 2 then pair[#pair + 1] = tile end
            end
            local remaining = subtract_subset(tiles, pair)
            for i = 1, #remaining do
                for j = i + 1, #remaining do
                    for k = j + 1, #remaining do
                        local meld = { remaining[i], remaining[j], remaining[k] }
                        if is_sequence(meld) or is_triplet(meld) then
                            local rest = subtract_subset(remaining, meld)
                            if is_pair(rest) or is_taatsu(rest) then return true end
                        end
                    end
                end
            end
        end
    end
    return false
end

local matchers = {
    yakuman = is_yakuman,
    chinitsu_group = is_chinitsu_group,
    iitsu = is_iitsu,
    kan = is_kan,
    iipeikou = is_iipeikou,
    sanshoku_set = is_sanshoku_set,
    two_pairs = is_two_pairs,
    sequence = is_sequence,
    triplet = is_triplet,
    taatsu = is_taatsu,
    pair = is_pair,
    single = function(tiles) return #tiles == 1 end,
}

function PatternMatcher.match(tiles)
    if #tiles == 0 or #tiles > 9 then return nil end
    local sorted = sorted_copy(tiles)
    for _, pattern in ipairs(PatternMatcher.patterns) do
        if matchers[pattern.id](sorted) then
            return {
                id = pattern.id,
                display = pattern.display,
                base_score = pattern.base_score,
                mult = pattern.mult,
                tile_count = pattern.tile_count,
            }
        end
    end
    return nil
end

return PatternMatcher
