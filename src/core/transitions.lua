-- src/core/transitions.lua
-- Standard Visual Novel & Cinematic Transitions Engine

local Transitions = {
    active = false,
    duration = 0.5,
    timer = 0,
    type = "fade", -- "fade", "fade_white", "wipe_left", "wipe_right", "wipe_down", "curtain", "iris", "crt_zoom", "glitch"
    direction = "out", -- "out" (obscure screen), "in" (reveal new scene)
    onMidpoint = nil,
    onComplete = nil,
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
    
    if Transitions.type == "fade_white" then
        Transitions.color = {1, 1, 1}
    else
        Transitions.color = {0, 0, 0}
    end
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
    local progress = 0 -- 0.0 to 1.0 (0=open/clear, 1=fully covered)

    if Transitions.direction == "out" then
        progress = math.min(1, Transitions.timer / half)
    else
        progress = math.max(0, 1 - (Transitions.timer - half) / half)
    end

    love.graphics.push()

    if Transitions.type == "fade" then
        -- Smooth Black Fade
        love.graphics.setColor(0, 0, 0, progress)
        love.graphics.rectangle("fill", 0, 0, w, h)

    elseif Transitions.type == "fade_white" or Transitions.type == "flash" then
        -- Dramatic White Flash / Fade
        love.graphics.setColor(1, 1, 1, progress)
        love.graphics.rectangle("fill", 0, 0, w, h)

    elseif Transitions.type == "wipe_right" then
        -- Horizontal Wipe: Left to Right
        love.graphics.setColor(0.04, 0.07, 0.14, 1)
        if Transitions.direction == "out" then
            love.graphics.rectangle("fill", 0, 0, w * progress, h)
        else
            love.graphics.rectangle("fill", w * (1 - progress), 0, w * progress, h)
        end

    elseif Transitions.type == "wipe_left" then
        -- Horizontal Wipe: Right to Left
        love.graphics.setColor(0.04, 0.07, 0.14, 1)
        if Transitions.direction == "out" then
            local wipeW = w * progress
            love.graphics.rectangle("fill", w - wipeW, 0, wipeW, h)
        else
            love.graphics.rectangle("fill", 0, 0, w * progress, h)
        end

    elseif Transitions.type == "wipe_down" then
        -- Vertical Wipe: Top to Bottom
        love.graphics.setColor(0.04, 0.07, 0.14, 1)
        if Transitions.direction == "out" then
            love.graphics.rectangle("fill", 0, 0, w, h * progress)
        else
            love.graphics.rectangle("fill", 0, h * (1 - progress), w, h * progress)
        end

    elseif Transitions.type == "curtain" then
        -- Horizontal Split Curtain meeting in middle
        love.graphics.setColor(0.04, 0.07, 0.14, 1)
        local curW = (w / 2) * progress
        love.graphics.rectangle("fill", 0, 0, curW, h)
        love.graphics.rectangle("fill", w - curW, 0, curW, h)

    elseif Transitions.type == "iris" or Transitions.type == "circle" then
        -- Circular Iris Mask closing/opening from center
        love.graphics.setColor(0.04, 0.07, 0.14, 1)
        local maxRadius = math.sqrt((w / 2) ^ 2 + (h / 2) ^ 2)
        local currentRadius = maxRadius * (1 - progress)

        -- If not fully open, draw stencil / borders
        love.graphics.setColor(0, 0, 0, progress)
        love.graphics.rectangle("fill", 0, 0, w, h)

    elseif Transitions.type == "crt_zoom" then
        -- Retro CRT Screen Collapse & Expansion
        love.graphics.setColor(0, 0, 0, progress)
        love.graphics.rectangle("fill", 0, 0, w, h)

        local lineProg = 1 - progress
        local rectW = w * lineProg
        local rectH = math.max(2, h * (lineProg ^ 2))
        local rx = (w - rectW) / 2
        local ry = (h - rectH) / 2

        love.graphics.setColor(0.65, 0.75, 0.85, (1 - progress) * 0.6)
        love.graphics.rectangle("line", rx, ry, rectW, rectH)
        love.graphics.setColor(0.92, 0.94, 0.98, 1 - progress)
        love.graphics.line(0, h / 2, w, h / 2)

    elseif Transitions.type == "glitch" then
        -- Cyberpunk Interference Scanlines & Blocks
        love.graphics.setColor(0.04, 0.06, 0.12, progress * 0.9)
        love.graphics.rectangle("fill", 0, 0, w, h)
        
        for i = 1, 10 do
            local gy = (i * 47 + Transitions.timer * 400) % h
            local gh = 6 + (i * 3) % 18
            love.graphics.setColor(0.2, 0.6, 0.9, progress * 0.7)
            love.graphics.rectangle("fill", 0, gy, w, gh)
        end
    end

    love.graphics.pop()
end

function Transitions.isActive()
    return Transitions.active
end

return Transitions
