-- dlc/paint_studio/paint.lua
-- Digital Sketch and Drawing Canvas with Auto-Save

local AudioManager = require("src.core.audio_manager")
local filesystem = require("src.core.filesystem")
local Notifications = require("src.desktop.notifications")

local PaintApp = {}
PaintApp.__index = PaintApp

function PaintApp.new()
    local self = setmetatable({}, PaintApp)
    
    -- Canvas
    self.canvasW = 800
    self.canvasH = 600
    self.canvas = love.graphics.newCanvas(self.canvasW, self.canvasH)
    
    -- Colors (simplified palette)
    self.colors = {
        {0.12, 0.12, 0.14},  -- Black
        {0.94, 0.25, 0.25},  -- Red
        {0.95, 0.45, 0.15},  -- Orange
        {0.95, 0.75, 0.15},  -- Yellow
        {0.15, 0.75, 0.35},  -- Green
        {0.15, 0.55, 0.85},  -- Blue
        {0.55, 0.25, 0.85},  -- Purple
        {0.95, 0.35, 0.65},  -- Pink
        {1.0, 1.0, 1.0},     -- White
    }
    self.selectedColor = 1
    self.brushSize = 4
    self.brushSizes = {2, 4, 6, 10, 16}
    self.isDrawing = false
    
    -- Stroke data
    self.strokes = {}
    self.currentStroke = nil
    self.undoStack = {}
    self.redoStack = {}
    self.maxUndo = 30
    
    -- Auto-save state
    self.saveFileName = "autosave.paint"
    self.autoSaveTimer = 0
    self.autoSaveInterval = 2
    self.hasUnsavedChanges = false
    
    -- UI
    self.toolbarHeight = 40
    self.sidebarWidth = 40
    self.padding = 6
    
    -- Font
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 10) or love.graphics.newFont(10)
    self.smallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 9) or love.graphics.newFont(9)
    
    -- Load saved data
    self:loadAutoSave()
    
    return self
end

function PaintApp:clearCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0.96, 0.97, 0.98, 1)
    love.graphics.setCanvas()
    self.strokes = {}
    self.currentStroke = nil
    self.undoStack = {}
    self.redoStack = {}
    self.hasUnsavedChanges = true
    self:autoSave()
end

function PaintApp:startStroke(x, y)
    self.currentStroke = {
        color = self.colors[self.selectedColor],
        size = self.brushSize,
        points = {{x, y}}
    }
    self.isDrawing = true
end

function PaintApp:addStrokePoint(x, y)
    if not self.currentStroke then return end
    table.insert(self.currentStroke.points, {x, y})
end

function PaintApp:endStroke()
    if self.currentStroke and #self.currentStroke.points > 1 then
        table.insert(self.undoStack, {strokes = {self.currentStroke}})
        if #self.undoStack > self.maxUndo then
            table.remove(self.undoStack, 1)
        end
        self.redoStack = {}
        table.insert(self.strokes, self.currentStroke)
        self.hasUnsavedChanges = true
    end
    self.currentStroke = nil
    self.isDrawing = false
    self:redrawCanvas()
end

function PaintApp:undo()
    if #self.undoStack == 0 then return end
    local action = table.remove(self.undoStack)
    local stroke = table.remove(self.strokes)
    if stroke then
        table.insert(self.redoStack, {strokes = {stroke}})
        self:redrawCanvas()
        self.hasUnsavedChanges = true
    end
end

function PaintApp:redo()
    if #self.redoStack == 0 then return end
    local action = table.remove(self.redoStack)
    for _, stroke in ipairs(action.strokes) do
        table.insert(self.strokes, stroke)
    end
    table.insert(self.undoStack, action)
    self:redrawCanvas()
    self.hasUnsavedChanges = true
end

function PaintApp:redrawCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0.96, 0.97, 0.98, 1)
    
    for _, stroke in ipairs(self.strokes) do
        local c = stroke.color
        love.graphics.setColor(c[1], c[2], c[3])
        love.graphics.setLineWidth(stroke.size)
        local pts = stroke.points
        for i = 2, #pts do
            love.graphics.line(pts[i-1][1], pts[i-1][2], pts[i][1], pts[i][2])
            love.graphics.circle("fill", pts[i][1], pts[i][2], stroke.size / 2)
        end
    end
    
    if self.currentStroke then
        local c = self.currentStroke.color
        love.graphics.setColor(c[1], c[2], c[3])
        love.graphics.setLineWidth(self.currentStroke.size)
        local pts = self.currentStroke.points
        for i = 2, #pts do
            love.graphics.line(pts[i-1][1], pts[i-1][2], pts[i][1], pts[i][2])
            love.graphics.circle("fill", pts[i][1], pts[i][2], self.currentStroke.size / 2)
        end
    end
    
    love.graphics.setCanvas()
end

function PaintApp:autoSave()
    if #self.strokes == 0 then return end
    
    local fs = filesystem.getFS()
    if not fs then return end
    
    local drawingsDir = fs.children and fs.children["Drawings"]
    if not drawingsDir then
        drawingsDir = filesystem.createDirectory(fs, "Drawings")
        if not drawingsDir then return end
    end
    
    local saveData = {
        version = "1.0",
        type = "paint_drawing",
        strokes = {}
    }
    
    for _, stroke in ipairs(self.strokes) do
        local points = {}
        for _, p in ipairs(stroke.points) do
            table.insert(points, {p[1], p[2]})
        end
        table.insert(saveData.strokes, {
            color = stroke.color,
            size = stroke.size,
            points = points
        })
    end
    
    local json = require("lib.json")
    if not json then return end
    
    local content = json.encode(saveData, {indent = true})
    
    local fileNode = drawingsDir.children and drawingsDir.children[self.saveFileName]
    if fileNode then
        fileNode.content = content
        fileNode.modified = os.time()
    else
        filesystem.createFile(drawingsDir, self.saveFileName, content)
    end
    
    filesystem.save(fs)
    self.hasUnsavedChanges = false
end

function PaintApp:loadAutoSave()
    local fs = filesystem.getFS()
    if not fs then return end
    
    local drawingsDir = fs.children and fs.children["Drawings"]
    if not drawingsDir then return end
    
    local fileNode = drawingsDir.children and drawingsDir.children[self.saveFileName]
    if not fileNode then return end
    
    local json = require("lib.json")
    if not json then return end
    
    local data = json.decode(fileNode.content)
    if not data or data.type ~= "paint_drawing" then return end
    
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0.96, 0.97, 0.98, 1)
    
    self.strokes = {}
    for _, strokeData in ipairs(data.strokes) do
        local points = {}
        for _, p in ipairs(strokeData.points) do
            table.insert(points, {p[1], p[2]})
        end
        table.insert(self.strokes, {
            color = strokeData.color,
            size = strokeData.size,
            points = points
        })
    end
    love.graphics.setCanvas()
    self:redrawCanvas()
    self.hasUnsavedChanges = false
end

function PaintApp:update(dt)
    if self.hasUnsavedChanges then
        self.autoSaveTimer = self.autoSaveTimer + dt
        if self.autoSaveTimer >= self.autoSaveInterval then
            self.autoSaveTimer = 0
            self:autoSave()
        end
    end
end

function PaintApp:draw(x, y, width, height)
    self.width = width
    self.height = height
    
    love.graphics.push()
    love.graphics.translate(x, y)
    
    -- Background
    love.graphics.setColor(0.96, 0.97, 0.98)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Toolbar
    self:drawToolbar(width)
    
    -- Sidebar
    self:drawSidebar()
    
    -- Canvas
    self:drawCanvas(width, height)
    
    love.graphics.pop()
end

function PaintApp:drawToolbar(width)
    local th = self.toolbarHeight
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, width, th)
    love.graphics.setColor(0.9, 0.92, 0.94)
    love.graphics.line(0, th, width, th)
    
    local x = 8
    local btnSize = 28
    local y = (th - btnSize) / 2
    local spacing = 4
    
    -- Undo
    local active = #self.undoStack > 0
    love.graphics.setColor(active and 0.25 or 0.6, active and 0.35 or 0.65, active and 0.45 or 0.7)
    love.graphics.rectangle("fill", x, y, btnSize, btnSize, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font)
    love.graphics.printf("Un", x, y + 5, btnSize, "center")
    self.undoBtn = {x = x, y = y, w = btnSize, h = btnSize, active = active}
    x = x + btnSize + spacing
    
    -- Redo
    active = #self.redoStack > 0
    love.graphics.setColor(active and 0.25 or 0.6, active and 0.35 or 0.65, active and 0.45 or 0.7)
    love.graphics.rectangle("fill", x, y, btnSize, btnSize, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Re", x, y + 5, btnSize, "center")
    self.redoBtn = {x = x, y = y, w = btnSize, h = btnSize, active = active}
    x = x + btnSize + spacing + 6
    
    -- Clear
    love.graphics.setColor(0.85, 0.3, 0.3)
    love.graphics.rectangle("fill", x, y, 50, btnSize, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font)
    love.graphics.printf("Clear", x, y + 7, 50, "center")
    self.clearBtn = {x = x, y = y, w = 50, h = btnSize}
    x = x + 56
    
    -- Status
    love.graphics.setColor(0.5, 0.55, 0.65)
    love.graphics.setFont(self.smallFont)
    local status = self.hasUnsavedChanges and "0" or "1"
    love.graphics.print(status .. " " .. (#self.strokes) .. " strokes", x, y + 9)
end

function PaintApp:drawSidebar()
    local sw = self.sidebarWidth
    local th = self.toolbarHeight
    local y = th + self.padding
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.padding, y, sw, self.height - th - self.padding * 2)
    love.graphics.setColor(0.9, 0.92, 0.94)
    love.graphics.rectangle("line", self.padding, y, sw, self.height - th - self.padding * 2)
    
    local colorSize = 26
    local spacing = 4
    local total = colorSize + spacing
    local x = (sw - colorSize) / 2 + self.padding
    local startY = y + 8
    
    -- Colors
    for i, color in ipairs(self.colors) do
        local cy = startY + (i-1) * total
        if i == self.selectedColor then
            love.graphics.setColor(0.3, 0.4, 0.5)
            love.graphics.rectangle("fill", x - 2, cy - 2, colorSize + 4, colorSize + 4, 3, 3)
        end
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle("fill", x, cy, colorSize, colorSize, 3, 3)
        love.graphics.setColor(0.8, 0.85, 0.9)
        love.graphics.rectangle("line", x, cy, colorSize, colorSize, 3, 3)
        self.colorBtn = self.colorBtn or {}
        self.colorBtn[i] = {x = x, y = cy, w = colorSize, h = colorSize}
    end
    
    -- Size label
    local sizeY = startY + #self.colors * total + 12
    love.graphics.setColor(0.3, 0.35, 0.45)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("Size", self.padding, sizeY, sw, "center")
    
    -- Brush sizes
    for i, size in ipairs(self.brushSizes) do
        local cy = sizeY + 16 + (i-1) * total
        local active = self.brushSize == size
        if active then
            love.graphics.setColor(0.3, 0.4, 0.5)
            love.graphics.rectangle("fill", x - 2, cy - 2, colorSize + 4, colorSize + 4, 3, 3)
        end
        love.graphics.setColor(0.95, 0.96, 0.97)
        love.graphics.rectangle("fill", x, cy, colorSize, colorSize, 3, 3)
        love.graphics.setColor(0.6, 0.65, 0.7)
        love.graphics.rectangle("line", x, cy, colorSize, colorSize, 3, 3)
        
        love.graphics.setColor(0.2, 0.25, 0.3)
        local dot = math.min(size, colorSize / 2.8)
        love.graphics.circle("fill", x + colorSize/2, cy + colorSize/2, dot)
        self.sizeBtn = self.sizeBtn or {}
        self.sizeBtn[i] = {x = x, y = cy, w = colorSize, h = colorSize}
    end
end

function PaintApp:drawCanvas(width, height)
    local th = self.toolbarHeight
    local sw = self.sidebarWidth
    local pad = self.padding
    
    local cx = pad + sw + pad
    local cy = th + pad
    local cw = width - cx - pad
    local ch = height - th - pad * 2
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", cx, cy, cw, ch)
    love.graphics.setColor(0.85, 0.88, 0.92)
    love.graphics.rectangle("line", cx, cy, cw, ch)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.canvas, cx, cy, 0, cw / self.canvasW, ch / self.canvasH)
    
    self.canvasRect = {x = cx, y = cy, w = cw, h = ch}
end

function PaintApp:mousepressed(mx, my, button)
    if button ~= 1 then return false end
    
    local th = self.toolbarHeight
    local sw = self.sidebarWidth
    local pad = self.padding
    
    -- Toolbar
    if my <= th then
        if self.undoBtn and self.undoBtn.active then
            local b = self.undoBtn
            if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
                self:undo()
                AudioManager.playSFX("click")
                return true
            end
        end
        if self.redoBtn and self.redoBtn.active then
            local b = self.redoBtn
            if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
                self:redo()
                AudioManager.playSFX("click")
                return true
            end
        end
        if self.clearBtn then
            local b = self.clearBtn
            if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
                self:clearCanvas()
                AudioManager.playSFX("click")
                return true
            end
        end
        return true
    end
    
    -- Sidebar - Colors
    if mx >= pad and mx <= pad + sw then
        if self.colorBtn then
            for i, b in ipairs(self.colorBtn) do
                if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
                    self.selectedColor = i
                    AudioManager.playSFX("click")
                    return true
                end
            end
        end
        if self.sizeBtn then
            for i, b in ipairs(self.sizeBtn) do
                if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
                    self.brushSize = self.brushSizes[i]
                    AudioManager.playSFX("click")
                    return true
                end
            end
        end
        return true
    end
    
    -- Canvas
    local r = self.canvasRect
    if r and mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
        local cx = (mx - r.x) / r.w * self.canvasW
        local cy = (my - r.y) / r.h * self.canvasH
        self:startStroke(cx, cy)
        self:redrawCanvas()
        return true
    end
    
    return false
end

function PaintApp:mousemoved(mx, my, dx, dy)
    if not self.isDrawing then return false end
    
    local r = self.canvasRect
    if not r then return false end
    
    local cx = math.max(0, math.min(self.canvasW, (mx - r.x) / r.w * self.canvasW))
    local cy = math.max(0, math.min(self.canvasH, (my - r.y) / r.h * self.canvasH))
    
    self:addStrokePoint(cx, cy)
    self:redrawCanvas()
    return true
end

function PaintApp:mousereleased(mx, my, button)
    if button == 1 and self.isDrawing then
        self:endStroke()
        self:redrawCanvas()
        return true
    end
    return false
end

function PaintApp:keypressed(key)
    -- Undo/Redo shortcuts
    if key == "z" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("lcmd")) then
        self:undo()
        AudioManager.playSFX("click")
        return true
    elseif key == "y" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("lcmd")) then
        self:redo()
        AudioManager.playSFX("click")
        return true
    end
    return false
end

return PaintApp