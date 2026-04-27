local Shaders = {}

function Shaders.new()
    local shaders = {}
    local ok, crt = pcall(love.graphics.newShader, [[
        extern number time;
        extern number scanline_strength;
        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 pc) {
            vec2 uv = tc;
            number curve = 0.018;
            vec2 cc = uv * 2.0 - 1.0;
            uv += cc * dot(cc, cc) * curve;
            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                return vec4(0.0, 0.0, 0.0, 1.0);
            }
            vec4 base = Texel(tex, uv);
            number scan = sin((pc.y + time * 24.0) * 2.65) * 0.5 + 0.5;
            number vignette = smoothstep(0.86, 0.22, distance(tc, vec2(0.5)));
            base.rgb *= 1.0 - scanline_strength * scan;
            base.rgb += vec3(0.018, 0.0, 0.0) * sin(time * 12.0 + pc.y * 0.11);
            base.rgb *= 0.72 + 0.34 * vignette;
            return base * color;
        }
    ]])
    if ok then shaders.crt = crt end

    local ok_bg, bg = pcall(love.graphics.newShader, [[
        extern number time;
        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 pc) {
            vec2 uv = pc / love_ScreenSize.xy;
            number a = sin(uv.x * 17.0 + time * 0.7) + cos(uv.y * 13.0 - time * 0.55);
            number b = sin((uv.x + uv.y) * 24.0 + time * 0.45);
            vec3 red = vec3(0.16, 0.025, 0.035);
            vec3 jade = vec3(0.015, 0.18, 0.12);
            vec3 gold = vec3(0.55, 0.22, 0.04);
            vec3 col = mix(red, jade, smoothstep(-1.0, 1.0, a));
            col += gold * max(0.0, b) * 0.10;
            number vignette = smoothstep(0.75, 0.18, distance(uv, vec2(0.5, 0.46)));
            return vec4(col * (0.55 + vignette * 0.65), 1.0);
        }
    ]])
    if ok_bg then shaders.background = bg end
    return shaders
end

return Shaders
