local Class = {}
Class.__index = Class

function Class:extend()
    local cls = {}
    for k, v in pairs(self) do
        if k:sub(1, 2) == "__" then
            cls[k] = v
        end
    end
    cls.__index = cls
    cls.super = self
    setmetatable(cls, self)
    return cls
end

function Class:new(...)
    local instance = setmetatable({}, self)
    if instance.init then instance:init(...) end
    return instance
end

function Class:__call(...)
    return self:new(...)
end

return Class
