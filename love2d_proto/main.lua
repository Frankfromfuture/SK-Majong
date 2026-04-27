package.path = package.path .. ";src/?.lua;src/?/init.lua;src/?.lua;src/?/?.lua"

local SceneManager = require("src.core.scene_manager")
local EventManager = require("src.core.event_manager")
local Atlas = require("src.render.atlas")
local Shaders = require("src.render.shaders")
local MainMenu = require("src.scenes.main_menu")
local Battle = require("src.scenes.battle")

local LOGICAL_W, LOGICAL_H = 640, 360

local Game = {
    logical_w = LOGICAL_W,
    logical_h = LOGICAL_H,
    time = 0,
    mouse = { x = 0, y = 0, down = false, pressed = false, released = false },
    shake = 0,
    shake_x = 0,
    shake_y = 0,
}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    Game.canvas = love.graphics.newCanvas(LOGICAL_W, LOGICAL_H)
    Game.canvas:setFilter("nearest", "nearest")
    Game.fonts = {
        title = love.graphics.newFont(54),
        big = love.graphics.newFont(34),
        ui = love.graphics.newFont(18),
        small = love.graphics.newFont(12),
        tile = love.graphics.newFont(30),
    }
    pcall(function()
        Game.fonts.tile = love.graphics.newFont("/System/Library/Fonts/PingFang.ttc", 30)
    end)
    Game.atlas = Atlas.load("assets/generated/ui_atlas.png", "assets.generated.ui_atlas")
    Game.events = EventManager.new()
    Game.shaders = Shaders.new()
    Game.scenes = SceneManager.new(Game)
    Game.scenes:register("main_menu", MainMenu)
    Game.scenes:register("battle", Battle)
    Game.scenes:switch("main_menu")
end

local function update_mouse()
    local ww, wh = love.graphics.getDimensions()
    local scale = math.min(ww / LOGICAL_W, wh / LOGICAL_H)
    local ox = (ww - LOGICAL_W * scale) * 0.5
    local oy = (wh - LOGICAL_H * scale) * 0.5
    local mx, my = love.mouse.getPosition()
    Game.mouse.x = (mx - ox) / scale
    Game.mouse.y = (my - oy) / scale
end

function love.update(dt)
    Game.time = Game.time + math.min(dt, 1 / 20)
    update_mouse()
    Game.events:update(dt)
    Game.scenes:update(dt)
    if Game.shake > 0 then
        Game.shake = math.max(0, Game.shake - dt * 4.0)
        local amp = 5 * Game.shake
        Game.shake_x = math.sin(Game.time * 91.0) * amp
        Game.shake_y = math.cos(Game.time * 83.0) * amp
    else
        Game.shake_x, Game.shake_y = 0, 0
    end
    Game.mouse.pressed = false
    Game.mouse.released = false
end

function love.draw()
    love.graphics.setCanvas(Game.canvas)
    love.graphics.clear(0.018, 0.014, 0.018, 1)
    love.graphics.push()
    love.graphics.translate(Game.shake_x, Game.shake_y)
    Game.scenes:draw()
    love.graphics.pop()
    love.graphics.setCanvas()

    local ww, wh = love.graphics.getDimensions()
    local scale = math.floor(math.min(ww / LOGICAL_W, wh / LOGICAL_H))
    if scale < 1 then scale = math.min(ww / LOGICAL_W, wh / LOGICAL_H) end
    local ox = math.floor((ww - LOGICAL_W * scale) * 0.5)
    local oy = math.floor((wh - LOGICAL_H * scale) * 0.5)

    love.graphics.clear(0, 0, 0, 1)
    local use_crt = not (Game.scenes.current and Game.scenes.current.disable_post_crt)
    if use_crt and Game.shaders.crt then
        Game.shaders.crt:send("time", Game.time)
        Game.shaders.crt:send("scanline_strength", 0.16)
        love.graphics.setShader(Game.shaders.crt)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Game.canvas, ox, oy, 0, scale, scale)
    love.graphics.setShader()
end

function love.mousepressed(_, _, button)
    if button == 1 then
        Game.mouse.down = true
        Game.mouse.pressed = true
        Game.scenes:mousepressed(Game.mouse.x, Game.mouse.y)
    end
end

function love.mousereleased(_, _, button)
    if button == 1 then
        Game.mouse.down = false
        Game.mouse.released = true
        Game.scenes:mousereleased(Game.mouse.x, Game.mouse.y)
    end
end

function love.keypressed(key)
    if key == "escape" then
        if Game.scenes.current_name == "battle" then
            Game.scenes:switch("main_menu")
        else
            love.event.quit()
        end
    end
end
