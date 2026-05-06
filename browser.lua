local utf8 = require("utf8")
local BrowserApp = {}
BrowserApp.__index = BrowserApp

local urlMapping = {
    ["http://home.com"] = "browser_sites.home",
    ["http://google.com"] = "browser_sites.google",
    ["http://bing.com"] = "browser_sites.bing",
    ["http://twitter.com"] = "browser_sites.twitter",
    ["http://reddit.com"] = "browser_sites.reddit",
    ["http://4chan.org"] = "browser_sites.4chan",
    ["http://news.com"] = "browser_sites.news",
}

function BrowserApp.new()
    local self = setmetatable({}, BrowserApp)
    self.font = love.graphics.newFont(12)
    self.urlFont = love.graphics.newFont(14)
    self.font48 = love.graphics.newFont(48)
    
    self.history = {}
    self.historyIndex = 0
    self.currentURL = ""
    self.urlInput = ""
    self.urlActive = false
    self.cursorBlink = 0
    
    self.siteInstance = nil
    self.loading = false
    self.loadTimer = 0
    self.loadDuration = 0
    
    -- Initialize coordinates to prevent nil-errors if clicked before first draw
    self.x, self.y = 0, 0 
    self.windowWidth = 800
    self.windowHeight = 600
    self.headerHeight = 48
    
    self.ui = {}
    
    self:loadURL("http://home.com")
    
    return self
end

function BrowserApp:loadURL(url)
    if not url:match("^http://") and not url:match("^https://") then
        url = "http://" .. url
    end
    
    self.urlInput = url
    self.urlActive = false
    
    if #self.history == 0 or self.history[self.historyIndex] ~= url then
        for i = #self.history, self.historyIndex + 1, -1 do
            table.remove(self.history, i)
        end
        table.insert(self.history, url)
        self.historyIndex = #self.history
    end
    
    self.loading = true
    self.loadTimer = 0
    self.loadDuration = math.random() * 0.3 + 0.2
    self.nextURL = url
end

function BrowserApp:finishLoading()
    self.loading = false
    self.currentURL = self.nextURL
    
    local modulePath = urlMapping[self.currentURL]
    if modulePath then
        local ok, siteModule = pcall(require, modulePath)
        if ok and siteModule and siteModule.new then
            self.siteInstance = siteModule.new(self)
        else
            self.siteInstance = self:create404()
        end
    else
        if self.currentURL:match("search%?q=") then
            local ok, siteModule = pcall(require, "browser_sites.google")
            if ok and siteModule and siteModule.new then
                self.siteInstance = siteModule.new(self)
                return
            end
        end
        self.siteInstance = self:create404()
    end
end

function BrowserApp:create404()
    return {
        draw = function(s, x, y, w, h)
            love.graphics.setColor(0.95, 0.95, 0.95)
            love.graphics.rectangle("fill", x, y, w, h)
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.setFont(self.font48)
            love.graphics.printf("404", x, y + h*0.3, w, "center")
            love.graphics.setFont(self.font)
            love.graphics.printf("Page not found: " .. self.currentURL, x, y + h*0.3 + 60, w, "center")
        end,
        maxScroll = 0,
        scroll = 0
    }
end

function BrowserApp:back()
    if self.historyIndex > 1 then
        self.historyIndex = self.historyIndex - 1
        local prev = self.history[self.historyIndex]
        self.urlInput = prev
        self.loading = true
        self.loadTimer = 0
        self.loadDuration = 0.2
        self.nextURL = prev
    end
end

function BrowserApp:forward()
    if self.historyIndex < #self.history then
        self.historyIndex = self.historyIndex + 1
        local nxt = self.history[self.historyIndex]
        self.urlInput = nxt
        self.loading = true
        self.loadTimer = 0
        self.loadDuration = 0.2
        self.nextURL = nxt
    end
end

function BrowserApp:refresh()
    self.loading = true
    self.loadTimer = 0
    self.loadDuration = 0.2
    self.nextURL = self.currentURL
end

function BrowserApp:update(dt)
    if self.loading then
        self.loadTimer = self.loadTimer + dt
        if self.loadTimer >= self.loadDuration then
            self:finishLoading()
        end
    end
    
    self.cursorBlink = self.cursorBlink + dt
    
    if self.siteInstance and self.siteInstance.update then
        self.siteInstance:update(dt)
    end
end

function BrowserApp:draw(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    self.windowWidth, self.windowHeight = w, h
    
    love.graphics.setColor(0.2, 0.2, 0.22)
    love.graphics.rectangle("fill", x, y, w, h)
    
    self:drawHeader(x, y, w)
    
    local contentY = y + self.headerHeight
    local contentH = h - self.headerHeight
    
    if self.loading then
        self:drawLoadingScreen(x, contentY, w, contentH)
    elseif self.siteInstance then
        self:drawContent(x, contentY, w, contentH)
    end
    
    self:drawScrollbar(x, contentY, w, contentH)
end

function BrowserApp:drawHeader(x, y, w)
    local hh = self.headerHeight
    
    love.graphics.setColor(0.18, 0.18, 0.2)
    love.graphics.rectangle("fill", x, y, w, hh)
    love.graphics.setColor(0.12, 0.12, 0.14)
    love.graphics.line(x, y + hh, x + w, y + hh)
    
    local btnSize = 32
    local padding = 4
    local btnY = y + (hh - btnSize) / 2
    local currentX = x + 8
    
    -- Robust helper that returns the new X coordinate
    local function drawBtn(id, text, enabled, cx)
        self.ui[id] = {x = cx, y = btnY, w = btnSize, h = btnSize, enabled = enabled}
        
        local mx, my = love.mouse.getPosition()
        local hovered = mx >= cx and mx <= cx + btnSize and my >= btnY and my <= btnY + btnSize
        
        love.graphics.setColor(enabled and (hovered and {0.95, 0.95, 0.95} or {0.85, 0.85, 0.85}) or {0.4, 0.4, 0.4})
        love.graphics.rectangle("fill", cx, btnY, btnSize, btnSize, 6)
        love.graphics.setColor(0.18, 0.18, 0.2)
        love.graphics.setFont(self.urlFont)
        love.graphics.print(text, cx + 8, btnY + 6)
        
        return cx + btnSize + padding
    end
    
    currentX = drawBtn("back", "◀", self.historyIndex > 1, currentX)
    currentX = drawBtn("forward", "▶", self.historyIndex < #self.history, currentX)
    currentX = drawBtn("refresh", "↻", true, currentX)
    currentX = drawBtn("home", "⌂", true, currentX)
    
    currentX = currentX + 4
    local urlW = math.max(100, w - (currentX - x) - 12)
    self.ui.url = {x = currentX, y = btnY, w = urlW, h = btnSize}
    
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.rectangle("fill", currentX, btnY, urlW, btnSize, 16)
    
    if self.urlActive then
        love.graphics.setColor(0.3, 0.6, 1.0)
    else
        love.graphics.setColor(0.35, 0.35, 0.38)
    end
    love.graphics.rectangle("line", currentX, btnY, urlW, btnSize, 16)
    
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setFont(self.font)
    love.graphics.setScissor(currentX + 12, btnY, urlW - 36, btnSize)
    
    local urlText = self.urlInput
    if urlText == "" then urlText = "Search or enter URL" end
    love.graphics.print(urlText, currentX + 12, btnY + 10)
    
    if self.urlActive and math.floor(self.cursorBlink * 2) % 2 == 0 then
        local tw = self.font:getWidth(self.urlInput)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.line(currentX + 12 + tw, btnY + 6, currentX + 12 + tw, btnY + btnSize - 6)
    end
    love.graphics.setScissor()
    
    if self.currentURL:match("^https://") then
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.circle("fill", currentX + urlW - 16, btnY + btnSize/2, 4)
    end
    
    if self.loading then
        love.graphics.setColor(0.3, 0.6, 1.0)
        love.graphics.rectangle("fill", x, y + hh - 2, w * (self.loadTimer / self.loadDuration), 2)
    end
end

function BrowserApp:drawLoadingScreen(x, y, w, h)
    love.graphics.setColor(0.98, 0.98, 0.98)
    love.graphics.rectangle("fill", x, y, w, h)
    
    local cx, cy = x + w/2, y + h/2
    local radius = 20
    local angle = love.timer.getTime() * 4
    
    for i = 0, 7 do
        local a = angle + (i * math.pi / 4)
        local alpha = 0.2 + (i / 7) * 0.8
        love.graphics.setColor(0.3, 0.6, 1.0, alpha)
        love.graphics.circle("fill", cx + math.cos(a) * radius, cy + math.sin(a) * radius, 4)
    end
end

function BrowserApp:drawContent(x, y, w, h)
    love.graphics.setScissor(x, y, w, h)
    if self.siteInstance and self.siteInstance.draw then
        self.siteInstance:draw(x, y, w, h)
    end
    love.graphics.setScissor()
end

function BrowserApp:drawScrollbar(x, y, w, h)
    self.ui.scrollbar = nil
    if not self.siteInstance or not self.siteInstance.maxScroll or self.siteInstance.maxScroll <= 0 then return end
    
    local scroll = self.siteInstance.scroll or 0
    local maxScroll = self.siteInstance.maxScroll
    
    local scrollbarW = 10
    local trackX = x + w - scrollbarW - 4
    local trackY = y + 4
    local trackH = h - 8
    
    local thumbH = math.max(30, (h / (maxScroll + h)) * trackH)
    local maxThumbY = trackH - thumbH
    local thumbY = trackY + (scroll / maxScroll) * maxThumbY
    
    self.ui.scrollbar = {
        trackX = trackX, trackY = trackY, trackW = scrollbarW, trackH = trackH,
        thumbX = trackX, thumbY = thumbY, thumbW = scrollbarW, thumbH = thumbH
    }
    
    love.graphics.setColor(0.15, 0.15, 0.17, 0.2)
    love.graphics.rectangle("fill", trackX, trackY, scrollbarW, trackH, 5)
    
    local mx, my = love.mouse.getPosition()
    local thumbHover = mx >= trackX and mx <= trackX + scrollbarW and my >= thumbY and my <= thumbY + thumbH
    
    love.graphics.setColor(0.5, 0.5, 0.5, thumbHover and 0.9 or 0.6)
    love.graphics.rectangle("fill", trackX, thumbY, scrollbarW, thumbH, 5)
end

function BrowserApp:mousepressed(mx, my, button)
    -- Handle LOVE backwards compatibility string buttons ("l")
    if button ~= 1 and button ~= "l" then return end
    
    local function inBounds(b)
        return b and mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
    end

    -- Header Controls check (safe wrap in case clicked before fully drawn)
    if self.y and my <= self.y + self.headerHeight then
        if inBounds(self.ui.back) and self.ui.back.enabled then self:back(); return end
        if inBounds(self.ui.forward) and self.ui.forward.enabled then self:forward(); return end
        if inBounds(self.ui.refresh) then self:refresh(); return end
        if inBounds(self.ui.home) then self:loadURL("http://home.com"); return end
        
        if inBounds(self.ui.url) then
            self.urlActive = true
            -- Fix: Force the nested page to blur its focus so we don't have two blinking cursors
            if self.siteInstance then self.siteInstance.inputActive = false end 
            if not self.urlInput or self.urlInput == "" then self.urlInput = self.currentURL or "" end
            return
        end
        self.urlActive = false
        return
    end
    
    self.urlActive = false
    
    -- Scrollbar
    local sb = self.ui.scrollbar
    if sb and mx >= sb.trackX and mx <= sb.trackX + sb.trackW and my >= sb.trackY and my <= sb.trackY + sb.trackH then
        if my >= sb.thumbY and my <= sb.thumbY + sb.thumbH then
            self.isDraggingScrollbar = true
            self.dragStartY = my
            self.dragStartScroll = self.siteInstance.scroll
        else
            local clickRatio = (my - sb.trackY - sb.thumbH/2) / (sb.trackH - sb.thumbH)
            self.siteInstance.scroll = math.max(0, math.min(clickRatio * self.siteInstance.maxScroll, self.siteInstance.maxScroll))
        end
        return
    end
    
    -- Pass remaining clicks down
    if not self.loading and self.siteInstance and self.siteInstance.mousepressed then
        self.siteInstance:mousepressed(mx, my, button)
    end
end

function BrowserApp:mousemoved(mx, my, dx, dy)
    if self.isDraggingScrollbar and self.siteInstance and self.ui.scrollbar then
        local sb = self.ui.scrollbar
        local deltaY = my - self.dragStartY
        local maxThumbTravel = sb.trackH - sb.thumbH
        local scrollRatio = deltaY / maxThumbTravel
        
        self.siteInstance.scroll = math.max(0, math.min(
            self.dragStartScroll + (scrollRatio * self.siteInstance.maxScroll),
            self.siteInstance.maxScroll
        ))
        return
    end
    
    if not self.loading and self.siteInstance and self.siteInstance.mousemoved then
        self.siteInstance:mousemoved(mx, my, dx, dy)
    end
end

function BrowserApp:mousereleased(mx, my, button)
    if self.isDraggingScrollbar then
        self.isDraggingScrollbar = false
        return
    end
    if not self.loading and self.siteInstance and self.siteInstance.mousereleased then
        self.siteInstance:mousereleased(mx, my, button)
    end
end

function BrowserApp:wheelmoved(x, y)
    if not self.loading and self.siteInstance then
        if self.siteInstance.wheelmoved then
            self.siteInstance:wheelmoved(x, y)
        elseif self.siteInstance.maxScroll then
            self.siteInstance.scroll = math.max(0, math.min(
                (self.siteInstance.scroll or 0) - y * 40,
                self.siteInstance.maxScroll
            ))
        end
    end
end

function BrowserApp:keypressed(key)
    if self.urlActive then
        if key == "backspace" then
            local byteoffset = utf8.offset(self.urlInput, -1)
            if byteoffset then self.urlInput = string.sub(self.urlInput, 1, byteoffset - 1) end
        elseif key == "return" then
            local url = self.urlInput
            if url:match("%.") and not url:match("%s") then self:loadURL(url)
            else self:loadURL("http://google.com/search?q=" .. url:gsub("%s", "+")) end
        elseif key == "escape" then
            self.urlActive = false
        end
    else
        if key == "escape" then self.urlActive = false
        elseif key == "f5" then self:refresh() end
        
        if not self.loading and self.siteInstance and self.siteInstance.keypressed then
            self.siteInstance:keypressed(key)
        end
    end
end

function BrowserApp:textinput(text)
    if self.urlActive then
        self.urlInput = self.urlInput .. text
    elseif not self.loading and self.siteInstance and self.siteInstance.textinput then
        self.siteInstance:textinput(text)
    end
end

function BrowserApp:resize(w, h)
    self.windowWidth, self.windowHeight = w, h
end

return BrowserApp