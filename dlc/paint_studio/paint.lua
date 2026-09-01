-- dlc/paint_studio/paint.lua
-- Digital Sketch and Drawing Canvas

local AudioManager = require("src.core.audio_manager")

local PaintApp = {}
PaintApp.__index = PaintApp

function PaintApp.new()
    local self = setmetatable({}, PaintApp)
    self.width = 520
    self.height = 380
    self.canvasW = 800
    self.canvasH = 600
    self.canvas = love.graphics.newCanvas(self.canvasW, self.canvasH)
    self:clearCanvas()

    self.colors = {
        {0.1, 0.12, 0.16},  -- Black / Dark
        {0.15, 0.45, 0.90}, -- Royal Blue
        {0.20, 0.70, 0.95}, -- Sky Blue
        {0.22, 0.75, 0.40}, -- Green
        {0.95, 0.35, 0.35}, -- Coral Red
        {0.98, 0.75, 0.20}, -- Amber Yellow
        {0.65, 0.35, 0.85}, -- Purple
        {1.0, 1.0, 1.0}     -- White / Eraser
    }
    self.selectedColorIdx = 1
    self.brushSize = 4
    self.brushSizes = { 2, 4, 8, 16 }
    self.isDrawing = false
    self.lastX, self.lastY = nil, nil
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 12) or love.graphics.newFont(12)
    return self
end

function PaintApp:clearCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(1, 1, 1, 1)
    love.graphics.setCanvas()
end

function PaintApp:drawLine(x1, y1, x2, y2)
    love.graphics.setCanvas(self.canvas)
    local c = self.colors[self.selectedColorIdx]
    love.graphics.setColor(c[1], c[2], c[3], 1)
    love.graphics.setLineWidth(self.brushSize)
    love.graphics.line(x1, y1, x2, y2)
    love.graphics.circle("fill", x2, y2, self.brushSize / 2)
    love.graphics.setCanvas()
end

function PaintApp:update(dt) end

function PaintApp:draw(x, y, width, height)
    self.width = width
    self.height = height

    love.graphics.push()
    love.graphics.translate(x, y)

    -- Background
    love.graphics.setColor(0.92, 0.93, 0.95)
    love.graphics.rectangle("fill", 0, 0, width, height)

    -- Top Toolbar
    local toolH = 38
    love.graphics.setColor(0.98, 0.98, 0.99)
    love.graphics.rectangle("fill", 0, 0, width, toolH)
    love.graphics.setColor(0.85, 0.88, 0.92)
    love.graphics.line(0, toolH, width, toolH)

    -- Palette Colors
    local curX = 12
    for i, c in ipairs(self.colors) do
        local boxSize = 22
        local boxY = 8
        if i == self.selectedColorIdx then
            love.graphics.setColor(0.0, 0.47, 0.83)
            love.graphics.rectangle("fill", curX - 2, boxY - 2, boxSize + 4, boxSize + 4, 3, 3)
        end
        love.graphics.setColor(c[1], c[2], c[3])
        love.graphics.rectangle("fill", curX, boxY, boxSize, boxSize, 2, 2)
        love.graphics.setColor(0.7, 0.75, 0.8)
        love.graphics.rectangle("line", curX, boxY, boxSize, boxSize, 2, 2)
        curX = curX + boxSize + 8
    end

    -- Brush Sizes
    curX = curX + 12
    love.graphics.setFont(self.font)
    love.graphics.setColor(0.3, 0.35, 0.45)
    love.graphics.print("Size:", curX, 11)
    curX = curX + 34

    for _, sz in ipairs(self.brushSizes) do
        local btnW = 24
        if self.brushSize == sz then
            love.graphics.setColor(0.85, 0.92, 0.98)
            love.graphics.rectangle("fill", curX, 7, btnW, 24, 3, 3)
            love.graphics.setColor(0.15, 0.45, 0.85)
        else
            love.graphics.setColor(0.94, 0.95, 0.97)
            love.graphics.rectangle("fill", curX, 7, btnW, 24, 3, 3)
            love.graphics.setColor(0.4, 0.45, 0.5)
        end
        love.graphics.rectangle("line", curX, 7, btnW, 24, 3, 3)
        love.graphics.printf(tostring(sz), curX, 11, btnW, "center")
        curX = curX + btnW + 6
    end

    -- Clear Button
    curX = curX + 10
    love.graphics.setColor(0.95, 0.4, 0.4)
    love.graphics.rectangle("fill", curX, 7, 54, 24, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Clear", curX, 11, 54, "center")

    -- Canvas Area
    local canX = 8
    local canY = toolH + 8
    local canW = width - 16
    local canH = height - toolH - 16

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.canvas, canX, canY, 0, canW / self.canvasW, canH / self.canvasH)
    love.graphics.setColor(0.75, 0.8, 0.85)
    love.graphics.rectangle("line", canX, canY, canW, canH)

    love.graphics.pop()
end

function PaintApp:mousepressed(mx, my, button)
    if button ~= 1 then return false end
    local toolH = 38
    if my <= toolH then
        -- Check palette clicks
        local curX = 12
        for i, _ in ipairs(self.colors) do
            local boxSize = 22
            if mx >= curX and mx <= curX + boxSize and my >= 8 and my <= 30 then
                self.selectedColorIdx = i
                AudioManager.playSFX("click")
                return true
            end
            curX = curX + boxSize + 8
        end

        -- Check brush size clicks
        curX = curX + 46
        for _, sz in ipairs(self.brushSizes) do
            local btnW = 24
            if mx >= curX and mx <= curX + btnW and my >= 7 and my <= 31 then
                self.brushSize = sz
                AudioManager.playSFX("click")
                return true
            end
            curX = curX + btnW + 6
        end

        -- Check Clear button click
        curX = curX + 10
        if mx >= curX and mx <= curX + 54 and my >= 7 and my <= 31 then
            self:clearCanvas()
            AudioManager.playSFX("click")
            return true
        end
        return true
    end

    -- Canvas click
    local canX = 8
    local canY = toolH + 8
    local canW = self.width - 16
    local canH = self.height - toolH - 16

    if mx >= canX and mx <= canX + canW and my >= canY and my <= canY + canH then
        self.isDrawing = true
        local cx = (mx - canX) / canW * self.canvasW
        local cy = (my - canY) / canH * self.canvasH
        self.lastX, self.lastY = cx, cy
        self:drawLine(cx, cy, cx, cy)
        return true
    end
    return false
end

function PaintApp:mousemoved(mx, my, dx, dy)
    if not self.isDrawing then return false end
    local toolH = 38
    local canX = 8
    local canY = toolH + 8
    local canW = self.width - 16
    local canH = self.height - toolH - 16

    local cx = math.max(0, math.min(self.canvasW, (mx - canX) / canW * self.canvasW))
    local cy = math.max(0, math.min(self.canvasH, (my - canY) / canH * self.canvasH))

    if self.lastX and self.lastY then
        self:drawLine(self.lastX, self.lastY, cx, cy)
    end
    self.lastX, self.lastY = cx, cy
    return true
end

function PaintApp:mousereleased(mx, my, button)
    if button == 1 and self.isDrawing then
        self.isDrawing = false
        self.lastX, self.lastY = nil, nil
        return true
    end
    return false
end

return PaintApp
