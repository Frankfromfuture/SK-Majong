local Atlas = {}

function Atlas.load(image_path, manifest_module)
    local manifest = require(manifest_module)
    local image = love.graphics.newImage(image_path)
    image:setFilter("nearest", "nearest")
    local atlas = { image = image, frames = {} }
    local iw, ih = image:getDimensions()
    for name, frame in pairs(manifest.frames) do
        atlas.frames[name] = {
            quad = love.graphics.newQuad(frame.x, frame.y, frame.w, frame.h, iw, ih),
            x = frame.x,
            y = frame.y,
            w = frame.w,
            h = frame.h,
        }
    end
    return atlas
end

function Atlas.frame(atlas, name)
    local frame = atlas.frames[name]
    assert(frame, "Missing atlas frame: " .. tostring(name))
    return frame
end

return Atlas
