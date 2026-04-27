local Moveable = require("src.core.moveable")
local Atlas = require("src.render.atlas")

local Button = Moveable:extend()

function Button:init(args)
    self.game = args.game
    self.atlas = args.atlas
    self.frame = args.frame or "button_green"
    self.text = args.text or "Button"
    self.on_click = args.on_click
    self.disabled = args.disabled or false
    local f = Atlas.frame(self.atlas, self.frame)
    Moveable.init(self, { x = args.x, y = args.y, w = args.w or f.w, h = args.h or f.h, speed = 18 })
end

function Button:update(dt)
    local m = self.game.mouse
    self.hovered = (not self.disabled) and self:contains(m.x, m.y)
    self.T.scale = self.hovered and 1.055 or 1
    if self.hovered then
        self.T.r = math.sin(self.game.time * 6.0 + self.T.x) * 0.01
    else
        self.T.r = 0
    end
    Moveable.update(self, dt)
end

function Button:mousepressed(x, y)
    if self.disabled or not self:contains(x, y) then return false end
    self:juice_up(0.24, 0.035)
    if self.on_click then self.on_click() end
    return true
end

function Button:draw()
    local frame = Atlas.frame(self.atlas, self.frame)
    self:draw_transform(function()
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.draw(self.atlas.image, frame.quad, 3, 4, 0, self.VT.w / frame.w, self.VT.h / frame.h)
        if self.disabled then
            love.graphics.setColor(0.42, 0.42, 0.42, 0.8)
        elseif self.hovered then
            love.graphics.setColor(1.25, 1.12, 0.85, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.draw(self.atlas.image, frame.quad, 0, 0, 0, self.VT.w / frame.w, self.VT.h / frame.h)
        love.graphics.setFont(self.game.fonts.ui)
        love.graphics.setColor(0.04, 0.018, 0.012, 0.62)
        love.graphics.printf(self.text, 2, self.VT.h * 0.5 - 9 + 2, self.VT.w, "center")
        love.graphics.setColor(self.disabled and { 0.65, 0.62, 0.56, 0.85 } or { 1, 0.92, 0.62, 1 })
        love.graphics.printf(self.text, 0, self.VT.h * 0.5 - 9, self.VT.w, "center")
    end)
end

return Button
