local Class = require("src.core.class")

local Node = Class:extend()

function Node:init(args)
    args = args or {}
    self.T = {
        x = args.x or 0,
        y = args.y or 0,
        w = args.w or 1,
        h = args.h or 1,
        r = args.r or 0,
        scale = args.scale or 1,
    }
    self.children = {}
    self.visible = args.visible ~= false
    self.hovered = false
    self.clickable = args.clickable ~= false
end

function Node:add(child)
    self.children[#self.children + 1] = child
    child.parent = self
    return child
end

function Node:contains(x, y)
    return x >= self.T.x and x <= self.T.x + self.T.w and y >= self.T.y and y <= self.T.y + self.T.h
end

function Node:update(dt)
    for _, child in ipairs(self.children) do
        if child.update then child:update(dt) end
    end
end

function Node:draw()
    if not self.visible then return end
    for _, child in ipairs(self.children) do
        if child.draw then child:draw() end
    end
end

return Node
