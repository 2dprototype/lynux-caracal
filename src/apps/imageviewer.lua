-- imageviewer.lua
local ImageViewer = {}
ImageViewer.__index = ImageViewer

function ImageViewer.new(__filepath, fileNode)
    if type(__filepath) == "table" and not fileNode then
        fileNode = __filepath
        __filepath = fileNode.name
    end

    local self = setmetatable({}, ImageViewer)
    self.fileNode = fileNode or { name = tostring(__filepath or "image.png") }
    self.image = nil
    self.scale = 1.0
    self.offsetX = 0
    self.offsetY = 0
    self.dragging = false
    self.lastX, self.lastY = 0, 0
    self.minScale = 0.05
    self.maxScale = 15.0
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = 0, 0, 0, 0
    
    -- UI Dimensions
    self.uiHeight = 36
    self.controlsHeight = 38
    self.showInfo = true
    
    -- Animation states
    self.smoothZoom = true
    self.targetScale = 1.0
    self.zoomSpeed = 12.0
    self.targetOffsetX = 0
    self.targetOffsetY = 0
    self.missingSource = nil
    
    -- Determine candidate paths from node.content, node.name, __filepath
    local contentSrc = (self.fileNode and self.fileNode.content and self.fileNode.content ~= "") and self.fileNode.content or nil
    local fileName = (self.fileNode and self.fileNode.name) or tostring(__filepath or "image.png")

    local candidatePaths = {}
    if contentSrc then
        table.insert(candidatePaths, contentSrc)
        table.insert(candidatePaths, "data/images/" .. contentSrc)
        table.insert(candidatePaths, "data/files/" .. contentSrc)
    end
    if fileName then
        table.insert(candidatePaths, "data/images/" .. fileName)
        table.insert(candidatePaths, "data/files/" .. fileName)
        table.insert(candidatePaths, "data/backgrounds/" .. fileName)
        table.insert(candidatePaths, "data/characters/" .. fileName)
        table.insert(candidatePaths, "data/" .. fileName)
    end
    if __filepath and __filepath ~= fileName then
        table.insert(candidatePaths, __filepath)
        table.insert(candidatePaths, "data/images/" .. __filepath)
        table.insert(candidatePaths, "data/files/" .. __filepath)
    end

    -- Try loading image from candidates
    for _, path in ipairs(candidatePaths) do
        if love.filesystem.getInfo(path) then
            local ok, img = pcall(love.graphics.newImage, path)
            if ok and img then
                self.image = img
                self.image:setFilter("linear", "nearest")
                self.imagePath = path
                break
            end
        end
    end
    
    if not self.image then
        self.missingSource = contentSrc or ("data/images/" .. fileName)
    else
        self:resetView()
    end
    
    return self
end

function ImageViewer:loadImage(node)
    if not node then return end
    self.fileNode = node
    local contentSrc = (node.content and node.content ~= "") and node.content or nil
    local fileName = node.name or "image.png"

    local candidatePaths = {}
    if contentSrc then
        table.insert(candidatePaths, contentSrc)
        table.insert(candidatePaths, "data/images/" .. contentSrc)
    end
    table.insert(candidatePaths, "data/images/" .. fileName)
    table.insert(candidatePaths, "data/files/" .. fileName)
    table.insert(candidatePaths, "data/backgrounds/" .. fileName)
    table.insert(candidatePaths, "data/characters/" .. fileName)

    for _, path in ipairs(candidatePaths) do
        if love.filesystem.getInfo(path) then
            local ok, img = pcall(love.graphics.newImage, path)
            if ok and img then
                self.image = img
                self.image:setFilter("linear", "nearest")
                self.imagePath = path
                self.missingSource = nil
                self:resetView()
                return
            end
        end
    end

    self.image = nil
    self.missingSource = contentSrc or ("data/images/" .. fileName)
end

function ImageViewer:update(dt)
    -- Smooth zoom animation
    if self.smoothZoom then
        -- Interpolate scale
        if math.abs(self.scale - self.targetScale) > 0.001 then
            self.scale = self.scale + (self.targetScale - self.scale) * self.zoomSpeed * dt
        else
            self.scale = self.targetScale
        end
        
        -- Interpolate offsets for smooth panning
        if math.abs(self.offsetX - self.targetOffsetX) > 0.1 then
            self.offsetX = self.offsetX + (self.targetOffsetX - self.offsetX) * (self.zoomSpeed * 1.5) * dt
        else
            self.offsetX = self.targetOffsetX
        end
        
        if math.abs(self.offsetY - self.targetOffsetY) > 0.1 then
            self.offsetY = self.offsetY + (self.targetOffsetY - self.offsetY) * (self.zoomSpeed * 1.5) * dt
        else
            self.offsetY = self.targetOffsetY
        end
    end
end

function ImageViewer:draw(x, y, width, height)
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = x, y, width, height
    
    -- Clean light background
    love.graphics.setColor(0.97, 0.97, 0.98)
    love.graphics.rectangle("fill", x, y, width, height)
    
    if not self.image then
        -- Developer placeholder card for missing image
        local cardW = math.min(320, width - 40)
        local cardH = math.min(180, height - 60)
        local cardX = x + (width - cardW) / 2
        local cardY = y + (height - cardH) / 2

        love.graphics.setColor(0.06, 0.09, 0.16, 0.95)
        love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 6, 6)
        love.graphics.setColor(0.2, 0.5, 0.85, 0.8)
        love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 6, 6)

        -- Title
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self.fileNode and self.fileNode.name or "Image", cardX, cardY + 14, cardW, "center")

        -- Tag
        love.graphics.setColor(0.95, 0.45, 0.45)
        love.graphics.printf("[Missing Image File]", cardX, cardY + 38, cardW, "center")

        -- Expected Path box
        love.graphics.setColor(0.04, 0.06, 0.11)
        love.graphics.rectangle("fill", cardX + 12, cardY + 64, cardW - 24, 48, 4, 4)
        love.graphics.setColor(0.45, 0.75, 1.0)
        love.graphics.printf("Expected Content Source:", cardX + 16, cardY + 70, cardW - 32, "center")
        love.graphics.setColor(0.85, 0.9, 0.98)
        love.graphics.printf(tostring(self.missingSource or "data/images/*.png"), cardX + 16, cardY + 88, cardW - 32, "center")

        love.graphics.setColor(0.5, 0.55, 0.65)
        love.graphics.printf("Place image in data/images/ to view", cardX, cardY + cardH - 24, cardW, "center")
        return
    end
    
    -- Capture dimensions and reset view on first draw to ensure fit-to-screen
    if self.windowWidth <= 1 then
        self.windowWidth = width
        self.windowHeight = height
        self:resetView()
    end
    
    local imgW, imgH = self.image:getDimensions()
    
    -- Safe view dimensions (prevent negative numbers)
    local viewWidth = math.max(1, width)
    local viewHeight = math.max(1, height)
    
    if self.showInfo then
        viewHeight = math.max(1, viewHeight - self.uiHeight - self.controlsHeight)
    end
    
    -- Calculate drawing dimensions based on current scale
    local drawW = imgW * self.scale
    local drawH = imgH * self.scale
    
    local centerX = x + viewWidth / 2
    local centerY = y + (self.showInfo and self.uiHeight or 0) + viewHeight / 2
    
    -- Base calculation for drawing
    local drawX = centerX - drawW / 2 + self.offsetX
    local drawY = centerY - drawH / 2 + self.offsetY
    
    -- Enforce drag bounds
    self:applyDragBounds(drawW, drawH, viewWidth, viewHeight)
    
    -- Re-calculate after bounds clamp
    drawX = centerX - drawW / 2 + self.offsetX
    drawY = centerY - drawH / 2 + self.offsetY
    
    -- Set scissor for image area to prevent drawing over UI
    local imageAreaY = y + (self.showInfo and self.uiHeight or 0)
    love.graphics.setScissor(x, imageAreaY, viewWidth, viewHeight)
    
    -- Draw subtle drop shadow behind image
    love.graphics.setColor(0, 0, 0, 0.05)
    love.graphics.rectangle("fill", drawX + 4, drawY + 4, drawW, drawH)
    
    -- Draw image bounds
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", drawX, drawY, drawW, drawH)
    love.graphics.draw(self.image, drawX, drawY, 0, self.scale, self.scale)
    
    -- Subtle image border
    love.graphics.setColor(0.85, 0.86, 0.88)
    love.graphics.rectangle("line", drawX, drawY, drawW, drawH)
    
    love.graphics.setScissor()
    
    -- Draw UI overlay
    if self.showInfo then
        self:drawUI(x, y, width, height, imgW, imgH)
    end
end

function ImageViewer:applyDragBounds(drawW, drawH, viewWidth, viewHeight)
    local maxOffsetX = math.max(0, (drawW - viewWidth) / 2)
    local maxOffsetY = math.max(0, (drawH - viewHeight) / 2)
    
    -- Target offsets (for smooth panning)
    self.targetOffsetX = math.max(-maxOffsetX, math.min(self.targetOffsetX, maxOffsetX))
    self.targetOffsetY = math.max(-maxOffsetY, math.min(self.targetOffsetY, maxOffsetY))
    
    -- Hard clamp current offsets to prevent visual snapping
    self.offsetX = math.max(-maxOffsetX, math.min(self.offsetX, maxOffsetX))
    self.offsetY = math.max(-maxOffsetY, math.min(self.offsetY, maxOffsetY))
end

function ImageViewer:drawUI(x, y, width, height, imgW, imgH)
    local textDark = {0.13, 0.13, 0.14}
    local textMuted = {0.37, 0.40, 0.44}
    local borderLight = {0.85, 0.86, 0.88}
    local googleBlue = {0.10, 0.45, 0.91}
    
    -- Top Info Bar Background (White)
    love.graphics.setColor(1, 1, 1, 0.98)
    love.graphics.rectangle("fill", x, y, width, self.uiHeight)
    love.graphics.setColor(borderLight)
    love.graphics.rectangle("fill", x, y + self.uiHeight - 1, width, 1) -- Bottom border
    
    -- Top Bar Text
    love.graphics.setColor(textDark)
    love.graphics.print(self.fileNode.name or "Unknown File", x + 16, y + 12)
    
    love.graphics.setColor(textMuted)
    local zoomPercent = math.floor(self.scale * 100)
    love.graphics.printf(string.format("%dx%d px  |  %d%%", imgW, imgH, zoomPercent), x, y + 12, width - 16, "right")
    
    -- Bottom Controls Bar Background
    local controlsY = y + height - self.controlsHeight
    love.graphics.setColor(1, 1, 1, 0.98)
    love.graphics.rectangle("fill", x, controlsY, width, self.controlsHeight)
    love.graphics.setColor(borderLight)
    love.graphics.rectangle("fill", x, controlsY, width, 1) -- Top border
    
    -- Bottom Controls Text
    love.graphics.setColor(textMuted)
    love.graphics.print("Drag: Pan • Scroll: Zoom • R: Fit • 1: Actual Size • I: Toggle UI", x + 16, controlsY + 14)
    
    -- Google-style Zoom Slider
    local barWidth = 120
    local barX = x + width - barWidth - 24
    local barY = controlsY + 20
    
    -- Slider Track
    love.graphics.setColor(0.90, 0.91, 0.93)
    love.graphics.rectangle("fill", barX, barY - 2, barWidth, 4, 2, 2)
    
    -- Slider Fill
    local zoomRatio = (math.log(self.scale) - math.log(self.minScale)) / (math.log(self.maxScale) - math.log(self.minScale))
    zoomRatio = math.max(0, math.min(1, zoomRatio))
    
    love.graphics.setColor(googleBlue)
    love.graphics.rectangle("fill", barX, barY - 2, barWidth * zoomRatio, 4, 2, 2)
    
    -- Slider Thumb
    love.graphics.circle("fill", barX + (barWidth * zoomRatio), barY, 6)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function ImageViewer:mousepressed(mx, my, button)
    local relY = my - self.windowY
    local imageAreaY = self.showInfo and self.uiHeight or 0
    local imageAreaBottom = self.windowHeight - (self.showInfo and self.controlsHeight or 0)
    
    if button == 1 and relY >= imageAreaY and relY <= imageAreaBottom then
        self.dragging = true
        self.lastX, self.lastY = mx, my
        return true 
    end
    return false
end

function ImageViewer:mousemoved(mx, my)
    if self.dragging then
        local dx = mx - self.lastX
        local dy = my - self.lastY
        
        -- Update target offsets directly
        self.targetOffsetX = self.targetOffsetX + dx
        self.targetOffsetY = self.targetOffsetY + dy
        
        -- Sync current offsets for immediate feedback
        self.offsetX = self.targetOffsetX
        self.offsetY = self.targetOffsetY
        
        self.lastX, self.lastY = mx, my
        return true 
    end
    return false
end

function ImageViewer:mousereleased(mx, my, button)
    if button == 1 then
        self.dragging = false
        return true 
    end
    return false
end

function ImageViewer:wheelmoved(x, y)
    if not self.image then return false end
    
    local zoomFactor = 1.15
    if y > 0 then
        self.targetScale = self.targetScale * zoomFactor
    elseif y < 0 then
        self.targetScale = self.targetScale / zoomFactor
    end
    
    self.targetScale = math.max(self.minScale, math.min(self.targetScale, self.maxScale))
    
    if not self.smoothZoom then
        self.scale = self.targetScale
    end
    
    return true
end

function ImageViewer:resetView()
    if not self.image then return end
    
    local imgW, imgH = self.image:getDimensions()
    
    -- Force view dimensions to be at least 1 to prevent math errors and negative scales
    local viewWidth = math.max(1, self.windowWidth)
    local viewHeight = math.max(1, self.windowHeight - (self.showInfo and (self.uiHeight + self.controlsHeight) or 0))
    
    local scaleX = viewWidth / imgW
    local scaleY = viewHeight / imgH
    
    -- Min scale constraint added to prevent negative numbers
    self.targetScale = math.max(self.minScale, math.min(scaleX, scaleY))
    
    -- Add 10% padding so the image doesn't touch the borders perfectly when "fit"
    self.targetScale = self.targetScale * 0.95
    
    self.scale = self.targetScale
    self.targetOffsetX, self.targetOffsetY = 0, 0
    self.offsetX, self.offsetY = 0, 0
end

function ImageViewer:setActualSize()
    if self.image then
        self.targetScale = 1.0
        self.targetOffsetX, self.targetOffsetY = 0, 0
    end
end

function ImageViewer:keypressed(key)
    if key == "r" then
        self:resetView()
        return true
    elseif key == "f" then
        self:resetView()
        return true
    elseif key == "1" then
        self:setActualSize()
        return true
    elseif key == "i" then
        self.showInfo = not self.showInfo
        self:resetView()
        return true
    elseif key == "=" or key == "+" then
        self.targetScale = math.min(self.targetScale * 1.2, self.maxScale)
        return true
    elseif key == "-" then
        self.targetScale = math.max(self.targetScale / 1.2, self.minScale)
        return true
    elseif key == "0" then
        self:setActualSize()
        return true
    end
    return false
end

function ImageViewer:resize(w, h)
    self.windowWidth = w
    self.windowHeight = h
    self:resetView()
end

return ImageViewer