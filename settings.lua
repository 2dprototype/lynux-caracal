-- settings.lua
local SettingsApp = {}
SettingsApp.__index = SettingsApp

function SettingsApp.new(availableWallpapers, currentWallpaper, onWallpaperChange)
    local self = setmetatable({}, SettingsApp)
    
    -- Data
    self.availableWallpapers = availableWallpapers or {}
    self.currentWallpaper = currentWallpaper or {}
    self.onWallpaperChange = onWallpaperChange or function() end
    
    -- UI State
    self.tabs = {"Wallpaper", "Display", "System"}
    self.selectedTab = 1
    
    -- Dimensions & Layout
    self.width = 0
    self.height = 0
    self.tabHeight = 35
    
    -- Input State (Relative coordinates)
    self.mouseX = -1
    self.mouseY = -1
    self.mousePressed = false
    
    -- Wallpaper Grid Settings
    self.wallpaperPreviewSize = 120
    self.wallpaperGridColumns = 3
    self.wallpaperScroll = 0
    self.maxScroll = 0
    
    -- Scrollbar Interactive State
    self.isDraggingScrollbar = false
    self.scrollDragOffset = 0
    
    -- Display options
    self.resolutions = {
        {800, 600}, {1024, 768}, {1280, 720}, 
        {1366, 768}, {1600, 900}, {1920, 1080}
    }
    self.currentResolution = 1
    
    return self
end

function SettingsApp:setWallpaperTab()
    self.selectedTab = 1
end

function SettingsApp:draw(x, y, width, height)
    self.width = width
    self.height = height
    
    -- Push transformation to use relative coordinates (0,0 is top-left of app content)
    love.graphics.push()
    love.graphics.translate(x, y)
    
    -- Background
    love.graphics.setColor(0.96, 0.96, 0.98)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Draw Tabs
    local tabWidth = width / #self.tabs
    for i, tab in ipairs(self.tabs) do
        local tabX = (i - 1) * tabWidth
        local isHovered = self.mouseX >= tabX and self.mouseX <= tabX + tabWidth and self.mouseY >= 0 and self.mouseY <= self.tabHeight
        
        if i == self.selectedTab then
            love.graphics.setColor(0.2, 0.45, 0.8) -- Active tab (Blue)
        elseif isHovered then
            love.graphics.setColor(0.85, 0.85, 0.9) -- Hover state
        else
            love.graphics.setColor(0.9, 0.9, 0.95) -- Inactive tab
        end
        
        love.graphics.rectangle("fill", tabX, 0, tabWidth, self.tabHeight)
        
        -- Tab Separator
        love.graphics.setColor(0.8, 0.8, 0.85)
        love.graphics.rectangle("line", tabX, 0, tabWidth, self.tabHeight)
        
        -- Tab Text
        if i == self.selectedTab then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.3, 0.3, 0.3)
        end
        love.graphics.printf(tab, tabX, 10, tabWidth, "center")
    end
    
    -- Draw Active Content
    if self.selectedTab == 1 then
        self:drawWallpaperTab(x, y) -- Pass absolute x,y strictly for the Scissor
    elseif self.selectedTab == 2 then
        self:drawDisplayTab()
    elseif self.selectedTab == 3 then
        self:drawSystemTab()
    end
    
    love.graphics.pop()
end

function SettingsApp:drawWallpaperTab(absX, absY)
    local contentY = self.tabHeight
    local contentHeight = self.height - self.tabHeight
    
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.print("Current: " .. self:getCurrentWallpaperName(), 15, contentY + 15)
    
    local gridStartY = contentY + 45
    local gridHeight = contentHeight - 45
    
    -- Calculate grid layout
    local padding = 15
    local scrollbarWidth = 12
    local availableWidth = self.width - scrollbarWidth - (padding * 2)
    local cols = self.wallpaperGridColumns
    local itemWidth = (availableWidth - (cols - 1) * padding) / cols
    local itemHeight = self.wallpaperPreviewSize + 35
    
    local rows = math.ceil(#self.availableWallpapers / cols)
    local totalContentHeight = rows * (itemHeight + padding)
    
    self.maxScroll = math.max(0, totalContentHeight - gridHeight + padding)
    self.wallpaperScroll = math.max(0, math.min(self.wallpaperScroll, self.maxScroll))
    
    -- 1. Apply the main content scissor (mapped to absolute window space)
    local clipX = absX
    local clipY = absY + gridStartY
    local clipWidth = self.width
    local clipHeight = math.min(gridHeight, self.height - gridStartY)
    
    love.graphics.setScissor(clipX, clipY, clipWidth, clipHeight)
    
    -- Draw grid items
    for i, wallpaper in ipairs(self.availableWallpapers) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        
        local itemX = padding + col * (itemWidth + padding)
        local itemY = gridStartY + row * (itemHeight + padding) - self.wallpaperScroll
        
        -- Don't draw if fully outside scissor bounds
        if itemY + itemHeight > gridStartY and itemY < gridStartY + gridHeight then
            local isCurrent = self:isCurrentWallpaper(wallpaper)
            local isHovered = self.mouseX >= itemX and self.mouseX <= itemX + itemWidth and 
                              self.mouseY >= itemY and self.mouseY <= itemY + itemHeight and
                              self.mouseY >= gridStartY
            
            -- Selection / Hover Background
            if isCurrent then
                love.graphics.setColor(0.2, 0.45, 0.8, 0.2)
                love.graphics.rectangle("fill", itemX - 4, itemY - 4, itemWidth + 8, itemHeight + 8, 4)
                love.graphics.setColor(0.2, 0.45, 0.8)
                love.graphics.rectangle("line", itemX - 4, itemY - 4, itemWidth + 8, itemHeight + 8, 4)
            elseif isHovered then
                love.graphics.setColor(0.85, 0.85, 0.9)
                love.graphics.rectangle("fill", itemX - 4, itemY - 4, itemWidth + 8, itemHeight + 8, 4)
            end
            
            -- Preview Area
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.rectangle("fill", itemX, itemY, itemWidth, self.wallpaperPreviewSize)
            
            if wallpaper.type == "color" then
                love.graphics.setColor(wallpaper.color)
                love.graphics.rectangle("fill", itemX, itemY, itemWidth, self.wallpaperPreviewSize)
            elseif wallpaper.type == "gradient" then
                for py = 0, self.wallpaperPreviewSize do
                    local ratio = py / self.wallpaperPreviewSize
                    local r = wallpaper.gradient.top[1] * (1 - ratio) + wallpaper.gradient.bottom[1] * ratio
                    local g = wallpaper.gradient.top[2] * (1 - ratio) + wallpaper.gradient.bottom[2] * ratio
                    local b = wallpaper.gradient.top[3] * (1 - ratio) + wallpaper.gradient.bottom[3] * ratio
                    love.graphics.setColor(r, g, b)
                    love.graphics.line(itemX, itemY + py, itemX + itemWidth, itemY + py)
                end
            elseif wallpaper.type == "image" and wallpaper.image then
                love.graphics.setColor(1, 1, 1)
                local scale = math.max(itemWidth / wallpaper.image:getWidth(), self.wallpaperPreviewSize / wallpaper.image:getHeight())
                
                -- PRO FIX: Push a temporary coordinate boundary with intersectScissor
                love.graphics.push("all") 
                
                -- This automatically respects existing scissor coordinates AND locks down the image bounds
                love.graphics.intersectScissor(absX + itemX, absY + itemY, itemWidth, self.wallpaperPreviewSize)
                
                local drawWidth = wallpaper.image:getWidth() * scale
                local drawHeight = wallpaper.image:getHeight() * scale
                local offsetX = (itemWidth - drawWidth) / 2
                local offsetY = (self.wallpaperPreviewSize - drawHeight) / 2
                
                love.graphics.draw(wallpaper.image, itemX + offsetX, itemY + offsetY, 0, scale, scale)
                
                -- Revert to original settings/scissor seamlessly
                love.graphics.pop() 
            end
            
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.rectangle("line", itemX, itemY, itemWidth, self.wallpaperPreviewSize)
            
            love.graphics.setColor(0.1, 0.1, 0.1)
            love.graphics.printf(wallpaper.name, itemX, itemY + self.wallpaperPreviewSize + 8, itemWidth, "center")
        end
    end
    
    love.graphics.setScissor() -- Clear the main scissor once complete
    
    -- Draw Custom Interactive Scrollbar
    if self.maxScroll > 0 then
        local trackX = self.width - scrollbarWidth - 4
        local trackY = gridStartY + 4
        local trackHeight = gridHeight - 8
        
        local thumbHeight = math.max(30, (gridHeight / totalContentHeight) * trackHeight)
        local thumbY = trackY + (self.wallpaperScroll / self.maxScroll) * (trackHeight - thumbHeight)
        
        local thumbHovered = self.mouseX >= trackX and self.mouseX <= trackX + scrollbarWidth and 
                             self.mouseY >= thumbY and self.mouseY <= thumbY + thumbHeight
                             
        love.graphics.setColor(0.85, 0.85, 0.85, 0.5)
        love.graphics.rectangle("fill", trackX, trackY, scrollbarWidth, trackHeight, 6)
        
        if self.isDraggingScrollbar then
            love.graphics.setColor(0.4, 0.4, 0.4)
        elseif thumbHovered then
            love.graphics.setColor(0.5, 0.5, 0.5)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
        end
        love.graphics.rectangle("fill", trackX, thumbY, scrollbarWidth, thumbHeight, 6)
    end
end

function SettingsApp:drawDisplayTab()
    local y = self.tabHeight + 20
    
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.print("Display Settings", 20, y)
    
    local res = self.resolutions[self.currentResolution]
    love.graphics.print("Resolution: " .. res[1] .. "x" .. res[2], 20, y + 40)
    self:drawButton("Previous", 20, y + 70, 100, 30)
    self:drawButton("Next", 130, y + 70, 100, 30)
    
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.print("Fullscreen: " .. (love.window.getFullscreen() and "Yes" or "No"), 20, y + 130)
    self:drawButton("Toggle Fullscreen", 20, y + 160, 150, 30)
    
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.print("VSync: " .. (love.window.getVSync() == 1 and "Enabled" or "Disabled"), 20, y + 220)
    self:drawButton("Toggle VSync", 20, y + 250, 150, 30)
end

function SettingsApp:drawSystemTab()
    local y = self.tabHeight + 20
    love.graphics.setColor(0.1, 0.1, 0.1)
    
    love.graphics.print("System Information", 20, y)
    love.graphics.print("OS: " .. love.system.getOS(), 20, y + 40)
    love.graphics.print("Love2D Version: " .. string.format(love.getVersion()), 20, y + 70)
    love.graphics.print(string.format("FPS: %d", love.timer.getFPS()), 20, y + 100)
    love.graphics.print(string.format("Memory: %.2f MB", collectgarbage("count") / 1024), 20, y + 130)
    
    local stats = love.graphics.getStats()
    love.graphics.print(string.format("Draw Calls: %d", stats.drawcalls), 20, y + 160)
    love.graphics.print(string.format("Texture Memory: %.2f MB", stats.texturememory / 1024 / 1024), 20, y + 190)
    
    self:drawButton("Run Garbage Collector", 20, y + 230, 200, 30)
end

function SettingsApp:drawButton(text, x, y, w, h)
    local isHovered = self.mouseX >= x and self.mouseX <= x + w and self.mouseY >= y and self.mouseY <= y + h
    
    if isHovered then
        if self.mousePressed then
            love.graphics.setColor(0.15, 0.35, 0.7)
        else
            love.graphics.setColor(0.3, 0.55, 0.9)
        end
    else
        love.graphics.setColor(0.2, 0.45, 0.8)
    end
    
    love.graphics.rectangle("fill", x, y, w, h, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(text, x, y + (h - 14) / 2, w, "center")
end

-- ================= Interaction Logic =================

function SettingsApp:mousepressed(mx, my, button, wx, wy)
    self.mousePressed = true
    
    -- Tab switching
    if my <= self.tabHeight then
        local tabWidth = self.width / #self.tabs
        local clickedTab = math.floor(mx / tabWidth) + 1
        if clickedTab >= 1 and clickedTab <= #self.tabs then
            self.selectedTab = clickedTab
        end
        return
    end
    
    -- Route to active tab logic
    if self.selectedTab == 1 then
        self:handleWallpaperTabClick(mx, my)
    elseif self.selectedTab == 2 then
        self:handleDisplayTabClick(mx, my)
    elseif self.selectedTab == 3 then
        self:handleSystemTabClick(mx, my)
    end
end

function SettingsApp:mousemoved(mx, my, dx, dy)
    self.mouseX = mx
    self.mouseY = my
    
    -- Handle Scrollbar Dragging
    if self.selectedTab == 1 and self.isDraggingScrollbar then
        local gridStartY = self.tabHeight + 45
        local gridHeight = (self.height - self.tabHeight) - 45
        local trackHeight = gridHeight - 8
        
        local rows = math.ceil(#self.availableWallpapers / self.wallpaperGridColumns)
        local totalContentHeight = rows * (self.wallpaperPreviewSize + 50)
        local thumbHeight = math.max(30, (gridHeight / totalContentHeight) * trackHeight)
        
        local currentThumbY = my - self.scrollDragOffset
        local normalizedY = currentThumbY - (gridStartY + 4)
        
        local scrollFraction = normalizedY / (trackHeight - thumbHeight)
        self.wallpaperScroll = scrollFraction * self.maxScroll
        self.wallpaperScroll = math.max(0, math.min(self.wallpaperScroll, self.maxScroll))
    end
end

function SettingsApp:mousereleased(mx, my, button)
    self.mousePressed = false
    self.isDraggingScrollbar = false
end

function SettingsApp:wheelmoved(x, y)
    if self.selectedTab == 1 then
        self.wallpaperScroll = self.wallpaperScroll - y * 40
        self.wallpaperScroll = math.max(0, math.min(self.wallpaperScroll, self.maxScroll))
    end
end

function SettingsApp:handleWallpaperTabClick(mx, my)
    local gridStartY = self.tabHeight + 45
    local gridHeight = (self.height - self.tabHeight) - 45
    
    -- Scrollbar Click Detection
    if self.maxScroll > 0 then
        local scrollbarWidth = 12
        local trackX = self.width - scrollbarWidth - 4
        if mx >= trackX and mx <= trackX + scrollbarWidth and my >= gridStartY then
            local trackHeight = gridHeight - 8
            local rows = math.ceil(#self.availableWallpapers / self.wallpaperGridColumns)
            local totalContentHeight = rows * (self.wallpaperPreviewSize + 50)
            local thumbHeight = math.max(30, (gridHeight / totalContentHeight) * trackHeight)
            local thumbY = (gridStartY + 4) + (self.wallpaperScroll / self.maxScroll) * (trackHeight - thumbHeight)
            
            if my >= thumbY and my <= thumbY + thumbHeight then
                self.isDraggingScrollbar = true
                self.scrollDragOffset = my - thumbY
                return
            else
                -- Clicked track outside thumb - jump scroll
                if my < thumbY then
                    self.wallpaperScroll = math.max(0, self.wallpaperScroll - gridHeight)
                else
                    self.wallpaperScroll = math.min(self.maxScroll, self.wallpaperScroll + gridHeight)
                end
                return
            end
        end
    end
    
    -- Wallpaper Grid Click Detection
    if my < gridStartY then return end 
    
    local padding = 15
    local cols = self.wallpaperGridColumns
    local availableWidth = self.width - 12 - (padding * 2)
    local itemWidth = (availableWidth - (cols - 1) * padding) / cols
    local itemHeight = self.wallpaperPreviewSize + 35
    
    for i, wallpaper in ipairs(self.availableWallpapers) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        
        local itemX = padding + col * (itemWidth + padding)
        local itemY = gridStartY + row * (itemHeight + padding) - self.wallpaperScroll
        
        if mx >= itemX and mx <= itemX + itemWidth and my >= itemY and my <= itemY + itemHeight then
            -- Deep copy selection to prevent reference sharing
            self.currentWallpaper = {
                type = wallpaper.type,
                color = wallpaper.color,
                gradient = wallpaper.gradient,
                image = wallpaper.image,
                filename = wallpaper.filename
            }
            self.onWallpaperChange(self.currentWallpaper)
            break
        end
    end
end

function SettingsApp:handleDisplayTabClick(mx, my)
    local y = self.tabHeight + 20
    
    if self:isButtonClicked(mx, my, 20, y + 70, 100, 30) then
        self.currentResolution = self.currentResolution - 1
        if self.currentResolution < 1 then self.currentResolution = #self.resolutions end
        local res = self.resolutions[self.currentResolution]
        love.window.setMode(res[1], res[2])
    end
    
    if self:isButtonClicked(mx, my, 130, y + 70, 100, 30) then
        self.currentResolution = self.currentResolution + 1
        if self.currentResolution > #self.resolutions then self.currentResolution = 1 end
        local res = self.resolutions[self.currentResolution]
        love.window.setMode(res[1], res[2])
    end
    
    if self:isButtonClicked(mx, my, 20, y + 160, 150, 30) then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
    
    if self:isButtonClicked(mx, my, 20, y + 250, 150, 30) then
        love.window.setVSync(love.window.getVSync() == 1 and 0 or 1)
    end
end

function SettingsApp:handleSystemTabClick(mx, my)
    local y = self.tabHeight + 20
    if self:isButtonClicked(mx, my, 20, y + 230, 200, 30) then
        collectgarbage("collect")
    end
end

-- ================= Utilities =================

function SettingsApp:isButtonClicked(mx, my, bx, by, bw, bh)
    return mx >= bx and mx <= bx + bw and my >= by and my <= by + bh
end

function SettingsApp:isCurrentWallpaper(wp)
    if wp.type ~= self.currentWallpaper.type then return false end
    
    if wp.type == "color" then
        return self:colorsEqual(wp.color, self.currentWallpaper.color)
    elseif wp.type == "gradient" then
        return self:colorsEqual(wp.gradient.top, self.currentWallpaper.gradient.top) and
               self:colorsEqual(wp.gradient.bottom, self.currentWallpaper.gradient.bottom)
    elseif wp.type == "image" then
        return wp.filename == self.currentWallpaper.filename
    end
    return false
end

function SettingsApp:colorsEqual(c1, c2)
    if not c1 or not c2 then return false end
    return c1[1] == c2[1] and c1[2] == c2[2] and c1[3] == c2[3]
end

function SettingsApp:getCurrentWallpaperName()
    for _, wallpaper in ipairs(self.availableWallpapers) do
        if self:isCurrentWallpaper(wallpaper) then
            return wallpaper.name
        end
    end
    return "Custom"
end

function SettingsApp:update(dt) end
function SettingsApp:keypressed(key) end
function SettingsApp:textinput(text) end
function SettingsApp:resize(w, h) end

return SettingsApp