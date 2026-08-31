-- src/core/transitions.lua
local Transitions = {
    active = false,
    duration = 0.5,
    timer = 0,
    type = "fade", -- "fade", "crt_zoom", "glitch", "scanline"
    direction = "out", -- "out" (to black/zoom), "in" (reveal new mode)
    onMidpoint = nil,
    onComplete = nil,
    fromMode = nil,
    toMode = nil,
    color = {0, 0, 0}
}

function Transitions.start(type, duration, onMidpoint, onComplete)
    Transitions.active = true
    Transitions.type = type or "fade"
    Transitions.duration = duration or 0.6
    Transitions.timer = 0
    Transitions.direction = "out"
    Transitions.onMidpoint = onMidpoint
    Transitions.onComplete = onComplete
end

function Transitions.update(dt)
    if not Transitions.active then return end

    Transitions.timer = Transitions.timer + dt
    local half = Transitions.duration / 2

    if Transitions.direction == "out" and Transitions.timer >= half then
        Transitions.direction = "in"
        if Transitions.onMidpoint then
            Transitions.onMidpoint()
        end
    elseif Transitions.direction == "in" and Transitions.timer >= Transitions.duration then
        Transitions.active = false
        if Transitions.onComplete then
            Transitions.onComplete()
        end
    end
end

function Transitions.draw()
    if not Transitions.active then return end

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local half = Transitions.duration / 2
    local alpha = 0

    if Transitions.direction == "out" then
        alpha = math.min(1, Transitions.timer / half)
    else
        alpha = math.max(0, 1 - (Transitions.timer - half) / half)
    end

    if Transitions.type == "fade" then
        love.graphics.setColor(Transitions.color[1], Transitions.color[2], Transitions.color[3], alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)

    elseif Transitions.type == "crt_zoom" then
        -- Black background
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)

        -- Drawing shrinking/expanding CRT aperture line
        local progress = (Transitions.direction == "out") and (1 - alpha) or (1 - alpha)
        local rectW = w * progress
        local rectH = math.max(2, h * (progress ^ 2))
        local rx = (w - rectW) / 2
        local ry = (h - rectH) / 2

        love.graphics.setColor(0.65, 0.75, 0.85, (1 - alpha) * 0.5)
        love.graphics.rectangle("line", rx, ry, rectW, rectH)
        love.graphics.setColor(0.92, 0.94, 0.98, 1 - alpha)
        love.graphics.line(0, h / 2, w, h / 2)

    elseif Transitions.type == "glitch" then
        love.graphics.setColor(0.05, 0.05, 0.1, alpha * 0.9)
        love.graphics.rectangle("fill", 0, 0, w, h)
        -- Glitch bars
        for i = 1, 8 do
            local gy = math.random(0, h)
            local gh = math.random(4, 20)
            love.graphics.setColor(math.random() * 0.5, 0.8, 0.9, alpha * 0.6)
            love.graphics.rectangle("fill", 0, gy, w, gh)
        end
    end
end

function Transitions.isActive()
    return Transitions.active
end

return Transitions
