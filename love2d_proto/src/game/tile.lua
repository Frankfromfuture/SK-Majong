local Tile = {}
Tile.__index = Tile

Tile.SUIT_NAMES = { man = "万", pin = "筒", sou = "索" }
Tile.SUIT_ORDER = { man = 1, pin = 2, sou = 3 }

function Tile.new(suit, rank)
    return setmetatable({ suit = suit or "man", rank = rank or 1 }, Tile)
end

function Tile:key()
    return self.suit .. ":" .. tostring(self.rank)
end

function Tile:display()
    return tostring(self.rank) .. Tile.SUIT_NAMES[self.suit]
end

function Tile:equals(other)
    return other and self.suit == other.suit and self.rank == other.rank
end

function Tile.compare(a, b)
    local sa, sb = Tile.SUIT_ORDER[a.suit], Tile.SUIT_ORDER[b.suit]
    if sa ~= sb then return sa < sb end
    return a.rank < b.rank
end

function Tile.wall(seed)
    local tiles = {}
    for _, suit in ipairs({ "man", "pin", "sou" }) do
        for rank = 1, 9 do
            for _ = 1, 4 do tiles[#tiles + 1] = Tile.new(suit, rank) end
        end
    end
    love.math.setRandomSeed(seed or os.time())
    for i = #tiles, 2, -1 do
        local j = love.math.random(i)
        tiles[i], tiles[j] = tiles[j], tiles[i]
    end
    return tiles
end

return Tile
