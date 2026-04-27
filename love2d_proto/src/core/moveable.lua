local Node = require("src.core.node")

local Moveable = Node:extend()

function Moveable:init(args)
    Node.init(self, args)
    self.VT = {
        x = self.T.x,
        y = self.T.y,
        w = self.T.w,
        h = self.T.h,
        r = self.T.r,
        scale = self.T.scale,
    }
    self.speed = args and args.speed or 14
    self.juice = 0
    self.juice_rot = 0
    self.shadow = args and args.shadow or 2
end

function Moveable:set_target(x, y, w, h, r, scale)
    self.T.x = x or self.T.x
    self.T.y = y or self.T.y
    self.T.w = w or self.T.w
    self.T.h = h or self.T.h
    self.T.r = r or self.T.r
    self.T.scale = scale or self.T.scale
end

function Moveable:hard_set(x, y, w, h)
    self:set_target(x, y, w, h)
    self.VT.x, self.VT.y, self.VT.w, self.VT.h = self.T.x, self.T.y, self.T.w, self.T.h
    self.VT.r, self.VT.scale = self.T.r, self.T.scale
end

function Moveable:juice_up(amount, rot)
    self.juice = math.max(self.juice, amount or 0.45)
    self.juice_rot = rot or ((love.math.random() > 0.5) and 0.08 or -0.08)
end

local function approach(current, target, speed, dt)
    return current + (target - current) * math.min(1, speed * dt)
end

function Moveable:update(dt)
    self.VT.x = approach(self.VT.x, self.T.x, self.speed, dt)
    self.VT.y = approach(self.VT.y, self.T.y, self.speed, dt)
    self.VT.w = approach(self.VT.w, self.T.w, self.speed, dt)
    self.VT.h = approach(self.VT.h, self.T.h, self.speed, dt)
    self.VT.r = approach(self.VT.r, self.T.r, self.speed, dt)
    self.VT.scale = approach(self.VT.scale, self.T.scale, self.speed, dt)
    if self.juice > 0 then
        self.juice = math.max(0, self.juice - dt * 2.8)
    end
    Node.update(self, dt)
end

function Moveable:draw_transform(draw_fn)
    local bounce = self.juice > 0 and math.sin(self.juice * 28) * self.juice * 0.18 or 0
    local rot = self.VT.r + (self.juice > 0 and math.sin(self.juice * 22) * self.juice_rot or 0)
    love.graphics.push()
    love.graphics.translate(self.VT.x + self.VT.w * 0.5, self.VT.y + self.VT.h * 0.5)
    love.graphics.rotate(rot)
    love.graphics.scale(self.VT.scale + bounce, self.VT.scale + bounce)
    love.graphics.translate(-self.VT.w * 0.5, -self.VT.h * 0.5)
    draw_fn()
    love.graphics.pop()
end

return Moveable
