local Button = require("src.ui.button")
local Moveable = require("src.core.moveable")
local Atlas = require("src.render.atlas")
local BattleState = require("src.game.battle_state")

local TileCard = Moveable:extend()

function TileCard:init(args)
    self.game = args.game
    self.atlas = args.atlas
    self.tile = args.tile
    self.selected = false
    self.index = args.index
    self.on_click = args.on_click
    Moveable.init(self, { x = args.x, y = args.y, w = 36, h = 49.5, speed = 18 })
end

function TileCard:update(dt)
    local m = self.game.mouse
    self.hovered = self:contains(m.x, m.y)
    self.T.y = self.base_y - ((self.selected and 16 or 0) + (self.hovered and 5 or 0))
    self.T.r = self.selected and -0.05 + (self.index % 3) * 0.05 or math.sin(self.game.time * 2 + self.index) * 0.01
    self.T.scale = self.hovered and 1.05 or 1
    Moveable.update(self, dt)
end

function TileCard:mousepressed(x, y)
    if self:contains(x, y) and self.on_click then
        self.on_click(self)
        self:juice_up(0.28, 0.05)
        return true
    end
    return false
end

function TileCard:draw()
    local frame = Atlas.frame(self.atlas, self.selected and "tile_selected" or "tile_base")
    self:draw_transform(function()
        love.graphics.setColor(0, 0, 0, 0.38)
        love.graphics.draw(self.atlas.image, frame.quad, 3, 4, 0, self.VT.w / frame.w, self.VT.h / frame.h)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.atlas.image, frame.quad, 0, 0, 0, self.VT.w / frame.w, self.VT.h / frame.h)
        love.graphics.setFont(self.game.fonts.tile)
        local suit_colours = { man = { 0.78, 0.05, 0.03, 1 }, pin = { 0.03, 0.40, 0.95, 1 }, sou = { 0.02, 0.62, 0.22, 1 } }
        love.graphics.setColor(suit_colours[self.tile.suit])
        love.graphics.printf(self.tile:display(), 0, 14, self.VT.w, "center")
    end)
end

local Battle = {}
Battle.__index = Battle

function Battle.new(game)
    local self = setmetatable({
        game = game,
        battle = BattleState.new(300, os.time()),
        cards = {},
        selected = {},
        score_display = 0,
        score_burst = nil,
        locked = false,
    }, Battle)
    self.play_button = Button:new({
        game = game, atlas = game.atlas, frame = "button_red", text = "PLAY SET",
        x = 486, y = 268, w = 140, h = 28,
        on_click = function() self:play_selected() end,
    })
    self:layout_hand(true)
    return self
end

function Battle:layout_hand(hard)
    self.cards = {}
    local card_w = 36
    local gap = 4
    local total = #self.battle.hand * card_w + (#self.battle.hand - 1) * gap
    local start_x = (640 - total) * 0.5
    for i, tile in ipairs(self.battle.hand) do
        local card = TileCard:new({
            game = self.game, atlas = self.game.atlas, tile = tile, index = i,
            x = start_x + (i - 1) * (card_w + gap), y = 292,
            on_click = function(c) self:toggle_card(c) end,
        })
        card.base_y = 292
        if hard then card:hard_set(card.T.x, card.T.y, card.T.w, card.T.h) end
        self.cards[i] = card
    end
end

function Battle:toggle_card(card)
    if self.locked then return end
    card.selected = not card.selected
    self.selected = {}
    for _, c in ipairs(self.cards) do
        if c.selected then self.selected[#self.selected + 1] = c.tile end
    end
end

function Battle:preview()
    return self.battle:preview(self.selected)
end

function Battle:play_selected()
    if self.locked then return end
    local preview = self:preview()
    if preview.final_score <= 0 then
        self.score_burst = { text = "INVALID SET", t = 0.8, scale = 1.0 }
        return
    end
    self.locked = true
    for i, c in ipairs(self.cards) do
        if c.selected then
            c:set_target(258 + i * 8, 112 + (i % 2) * 8, c.T.w, c.T.h, -0.18 + i * 0.05, 1.1)
        end
    end
    self.game.events:after(0.28, function()
        local result = self.battle:play(self.selected)
        self.score_burst = { text = result.pattern or "SET", t = 1.15, scale = 1.6 }
        self.game.shake = 1
        local from = self.score_display
        self.score_display = from
        self.game.events:ease(0.55, self, "score_display", self.battle.total_score)
    end)
    self.game.events:after(0.95, function()
        self.selected = {}
        self.locked = false
        self:layout_hand(true)
    end)
end

function Battle:update(dt)
    for _, card in ipairs(self.cards) do card:update(dt) end
    self.play_button.disabled = self.locked or self:preview().final_score <= 0
    self.play_button:update(dt)
    if self.score_burst then
        self.score_burst.t = self.score_burst.t - dt
        self.score_burst.scale = self.score_burst.scale + dt * 0.8
        if self.score_burst.t <= 0 then self.score_burst = nil end
    end
end

function Battle:mousepressed(x, y)
    if self.play_button:mousepressed(x, y) then return end
    for i = #self.cards, 1, -1 do
        if self.cards[i]:mousepressed(x, y) then return end
    end
end

local function draw_panel(atlas, name, x, y, w, h)
    local frame = Atlas.frame(atlas, name)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(atlas.image, frame.quad, x, y, 0, w / frame.w, h / frame.h)
end

function Battle:draw()
    local g = self.game
    if g.shaders.background then
        g.shaders.background:send("time", g.time + 8)
        love.graphics.setShader(g.shaders.background)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 640, 360)
    love.graphics.setShader()

    love.graphics.setFont(g.fonts.ui)
    draw_panel(g.atlas, "panel_small", 16, 12, 150, 38)
    draw_panel(g.atlas, "panel_small", 184, 12, 170, 38)
    draw_panel(g.atlas, "panel_small", 374, 12, 150, 38)
    love.graphics.setColor(1, 0.88, 0.55, 1)
    love.graphics.print("Round  " .. tostring(math.min(self.battle.current_turn, self.battle.max_turns)) .. "/" .. self.battle.max_turns, 34, 22)
    love.graphics.print("Score  " .. tostring(math.floor(self.score_display + 0.5)), 202, 22)
    love.graphics.print("Target " .. tostring(self.battle.target_score), 392, 22)

    draw_panel(g.atlas, "play_area", 220, 82, 206, 92)
    love.graphics.setColor(0.55, 1, 0.68, 0.5)
    love.graphics.printf("PLAY AREA", 220, 118, 206, "center")

    draw_panel(g.atlas, "panel_jade", 462, 78, 160, 172)
    local preview = self:preview()
    love.graphics.setFont(g.fonts.small)
    love.graphics.setColor(0.6, 1, 0.68, 1)
    love.graphics.print("Score Preview", 482, 94)
    love.graphics.setColor(1, 0.86, 0.48, 1)
    love.graphics.print("Pattern", 482, 120)
    love.graphics.print(preview.pattern ~= "" and preview.pattern or "Invalid Set", 482, 136)
    love.graphics.print("Base", 482, 164)
    love.graphics.print(tostring(preview.base_score), 552, 164)
    love.graphics.print("Multiplier", 482, 188)
    love.graphics.print("x" .. tostring(preview.pattern_mult), 552, 188)
    love.graphics.print("Score", 482, 212)
    love.graphics.print(tostring(preview.final_score), 552, 212)
    self.play_button:draw()

    for _, card in ipairs(self.cards) do card:draw() end

    if self.score_burst then
        love.graphics.push()
        love.graphics.translate(320, 180)
        love.graphics.scale(self.score_burst.scale, self.score_burst.scale)
        love.graphics.setFont(g.fonts.big)
        love.graphics.setColor(0, 0, 0, 0.72)
        love.graphics.printf(self.score_burst.text, -170 + 3, -18 + 3, 340, "center")
        love.graphics.setColor(1, 0.72, 0.16, math.min(1, self.score_burst.t))
        love.graphics.printf(self.score_burst.text, -170, -18, 340, "center")
        love.graphics.pop()
    end
end

return Battle
