local EventManager = {}
EventManager.__index = EventManager

function EventManager.new()
    return setmetatable({ events = {} }, EventManager)
end

function EventManager:add(config)
    config.elapsed = 0
    config.done = false
    self.events[#self.events + 1] = config
    return config
end

function EventManager:after(delay, fn)
    return self:add({ delay = delay or 0, fn = fn })
end

function EventManager:ease(duration, ref, key, to, fn)
    return self:add({
        delay = duration or 0.2,
        ref = ref,
        key = key,
        from = ref[key],
        to = to,
        fn = fn,
        ease = true,
    })
end

function EventManager:update(dt)
    local i = 1
    while i <= #self.events do
        local event = self.events[i]
        event.elapsed = event.elapsed + dt
        if event.ease then
            local t = math.min(1, event.elapsed / math.max(0.001, event.delay))
            local eased = 1 - (1 - t) * (1 - t) * (1 - t)
            event.ref[event.key] = event.from + (event.to - event.from) * eased
            if event.fn then event.fn(eased) end
            event.done = t >= 1
        elseif event.elapsed >= (event.delay or 0) then
            if event.fn then event.fn() end
            event.done = true
        end
        if event.done then
            table.remove(self.events, i)
        else
            i = i + 1
        end
    end
end

return EventManager
