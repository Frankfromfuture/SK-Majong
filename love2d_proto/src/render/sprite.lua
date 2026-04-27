local Moveable = require("src.core.moveable")
local Atlas = require("src.render.atlas")

local Sprite = Moveable:extend()

function Sprite:init(args)
    self.atlas = args.atlas
    self.frame_name = args.frame
    local frame = Atlas.frame(self.atlas, self.frame_name)
    args.w = args.w or frame.w
    args.h = args.h or frame.h
    Moveable.init(self, args)
    self.color = args.color or { 1, 1, 1, 1 }
end

function Sprite:draw()
    if not self.visible then return end
    local frame = Atlas.frame(self.atlas, self.frame_name)
    self:draw_transform(function()
        love.graphics.setColor(0, 0, 0, 0.32)
        love.graphics.draw(self.atlas.image, frame.quad, self.shadow, self.shadow, 0, self.VT.w / frame.w, self.VT.h / frame.h)
        love.graphics.setColor(self.color)
        love.graphics.draw(self.atlas.image, frame.quad, 0, 0, 0, self.VT.w / frame.w, self.VT.h / frame.h)
    end)
end

return Sprite
