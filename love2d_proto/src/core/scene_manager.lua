local SceneManager = {}
SceneManager.__index = SceneManager

function SceneManager.new(game)
    return setmetatable({ game = game, factories = {}, current = nil, current_name = "" }, SceneManager)
end

function SceneManager:register(name, factory)
    self.factories[name] = factory
end

function SceneManager:switch(name, ...)
    assert(self.factories[name], "Unknown scene: " .. tostring(name))
    self.current_name = name
    self.current = self.factories[name].new(self.game, ...)
end

function SceneManager:update(dt)
    if self.current and self.current.update then self.current:update(dt) end
end

function SceneManager:draw()
    if self.current and self.current.draw then self.current:draw() end
end

function SceneManager:mousepressed(x, y)
    if self.current and self.current.mousepressed then self.current:mousepressed(x, y) end
end

function SceneManager:mousereleased(x, y)
    if self.current and self.current.mousereleased then self.current:mousereleased(x, y) end
end

return SceneManager
