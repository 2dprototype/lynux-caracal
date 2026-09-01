-- src/core/viewport.lua
-- Fixed Virtual Resolution & Letterbox Viewport Scaling Engine

local Viewport = {
    baseW = 760,
    baseH = 480,
    scale = 1.0,
    offsetX = 0,
    offsetY = 0,
    drawW = 760,
    drawH = 480
}

function Viewport.update()
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    
    local scaleX = winW / Viewport.baseW
    local scaleY = winH / Viewport.baseH
    Viewport.scale = math.min(scaleX, scaleY)
    
    Viewport.drawW = math.floor(Viewport.baseW * Viewport.scale)
    Viewport.drawH = math.floor(Viewport.baseH * Viewport.scale)
    Viewport.offsetX = math.floor((winW - Viewport.drawW) / 2)
    Viewport.offsetY = math.floor((winH - Viewport.drawH) / 2)
end

function Viewport.push()
    Viewport.update()
    love.graphics.push()
    love.graphics.translate(Viewport.offsetX, Viewport.offsetY)
    love.graphics.scale(Viewport.scale, Viewport.scale)
    love.graphics.setScissor(Viewport.offsetX, Viewport.offsetY, Viewport.drawW, Viewport.drawH)
end

function Viewport.pop()
    love.graphics.setScissor()
    love.graphics.pop()

    -- Draw letterbox / pillarbox black bars
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    love.graphics.setColor(0, 0, 0, 1)

    if Viewport.offsetX > 0 then
        love.graphics.rectangle("fill", 0, 0, Viewport.offsetX, winH)
        love.graphics.rectangle("fill", Viewport.offsetX + Viewport.drawW, 0, winW - (Viewport.offsetX + Viewport.drawW) + 2, winH)
    end
    if Viewport.offsetY > 0 then
        love.graphics.rectangle("fill", 0, 0, winW, Viewport.offsetY)
        love.graphics.rectangle("fill", 0, Viewport.offsetY + Viewport.drawH, winW, winH - (Viewport.offsetY + Viewport.drawH) + 2)
    end
end

-- Convert physical screen / touch coords into fixed virtual game coordinates
function Viewport.toVirtual(screenX, screenY)
    local vx = (screenX - Viewport.offsetX) / Viewport.scale
    local vy = (screenY - Viewport.offsetY) / Viewport.scale
    return vx, vy
end

function Viewport.toScreen(vx, vy)
    local sx = vx * Viewport.scale + Viewport.offsetX
    local sy = vy * Viewport.scale + Viewport.offsetY
    return sx, sy
end

function Viewport.getWidth()
    return Viewport.baseW
end

function Viewport.getHeight()
    return Viewport.baseH
end

return Viewport
