local MainMenu = {}
MainMenu.__index = MainMenu

local LAYER_CONFIG = {
    logo_sangoku_mahjong = { kind = "logo", float = 3.0, pulse = 0.018 },
    button_start_run = { kind = "button", action = "start", hover = true },
    button_collection = { kind = "button", hover = true },
    button_options = { kind = "button", hover = true },
    button_quit = { kind = "button", action = "quit", hover = true },
    panel_highest_score = { kind = "panel", float = 0.7 },
    panel_bonus_multiplier = { kind = "panel", float = 0.7 },
    prototype_build = { kind = "label", pulse_alpha = true },
    tile_wan_left = { kind = "tile", float = 3.4, wobble = 0.025 },
    tile_fa_right = { kind = "tile", float = 2.5, wobble = -0.020 },
    tile_pin_right = { kind = "tile", float = 2.1, wobble = 0.014 },
    tile_dong_right = { kind = "tile", float = 2.8, wobble = -0.018 },
}

function MainMenu.new(game)
    local manifest = require("assets.main_menu_layers.layers")
    local self = setmetatable({
        game = game,
        disable_post_crt = true,
        background = love.graphics.newImage(manifest.background),
        layers = {},
        hovered = nil,
        pressed = nil,
    }, MainMenu)
    self.background:setFilter("nearest", "nearest")

    for _, layer in ipairs(manifest.layers) do
        local image = love.graphics.newImage(layer.path)
        image:setFilter("nearest", "nearest")
        local config = LAYER_CONFIG[layer.name] or {}
        self.layers[#self.layers + 1] = {
            name = layer.name,
            image = image,
            x = layer.x,
            y = layer.y,
            w = layer.w,
            h = layer.h,
            base_x = layer.x,
            base_y = layer.y,
            kind = config.kind or "decor",
            action = config.action,
            hover = config.hover,
            float = config.float or 0,
            wobble = config.wobble or 0,
            pulse = config.pulse or 0,
            pulse_alpha = config.pulse_alpha,
            scale = 1,
            rotation = 0,
            alpha = 1,
        }
    end
    return self
end

local function contains(layer, x, y)
    return x >= layer.x and x <= layer.x + layer.w and y >= layer.y and y <= layer.y + layer.h
end

function MainMenu:update(dt)
    self.hovered = nil
    for _, layer in ipairs(self.layers) do
        if layer.hover and contains(layer, self.game.mouse.x, self.game.mouse.y) then
            self.hovered = layer
            break
        end
    end

    for i, layer in ipairs(self.layers) do
        layer.x = layer.base_x
        layer.y = layer.base_y
        layer.scale = 1
        layer.rotation = 0
        layer.alpha = 1

        if layer.float ~= 0 then
            layer.y = layer.base_y + math.sin(self.game.time * 1.7 + i * 0.8) * layer.float
        end
        if layer.wobble ~= 0 then
            layer.rotation = math.sin(self.game.time * 1.9 + i) * layer.wobble
        end
        if layer.pulse ~= 0 then
            layer.scale = layer.scale + math.sin(self.game.time * 2.2) * layer.pulse
        end
        if layer.pulse_alpha then
            layer.alpha = 0.72 + math.sin(self.game.time * 3.0) * 0.20
        end
        if self.hovered == layer then
            layer.scale = layer.scale + 0.035 + math.sin(self.game.time * 12.0) * 0.006
        end
        if self.pressed == layer then
            layer.scale = layer.scale - 0.035
        end
    end
end

function MainMenu:mousepressed(x, y)
    for _, layer in ipairs(self.layers) do
        if layer.hover and contains(layer, x, y) then
            self.pressed = layer
            if layer.action == "start" then
                self.game.scenes:switch("battle")
            elseif layer.action == "quit" then
                love.event.quit()
            end
            return
        end
    end
end

function MainMenu:mousereleased()
    self.pressed = nil
end

function MainMenu:draw_layer(layer)
    love.graphics.push()
    love.graphics.translate(layer.x + layer.w * 0.5, layer.y + layer.h * 0.5)
    love.graphics.rotate(layer.rotation)
    love.graphics.scale(layer.scale, layer.scale)
    love.graphics.translate(-layer.w * 0.5, -layer.h * 0.5)
    love.graphics.setColor(1, 1, 1, layer.alpha)
    love.graphics.draw(layer.image, 0, 0)

    if self.hovered == layer and layer.action then
        love.graphics.setColor(1.0, 0.78, 0.18, 0.28 + math.sin(self.game.time * 10.0) * 0.08)
        love.graphics.rectangle("line", 5, 5, layer.w - 10, layer.h - 10, 5, 5)
    end
    love.graphics.pop()
end

function MainMenu:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.background, 0, 0)
    for _, layer in ipairs(self.layers) do
        self:draw_layer(layer)
    end
end

return MainMenu
