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

-- Chrome-like Professional Light Theme
local Theme = {
    headerBg = {0.87, 0.88, 0.90}, -- #DEE1E6
    urlBarBg = {0.945, 0.953, 0.957}, -- #F1F3F4
    urlBarBorder = {0.9, 0.9, 0.9},
    textPrimary = {0.235, 0.25, 0.263}, -- #3C4043
    textSecondary = {0.37, 0.388, 0.408}, -- #5F6368
    accent = {0.1, 0.45, 0.9},
    border = {0.8, 0.8, 0.8},
    loadingBar = {0.26, 0.52, 0.96},
}

function BrowserApp.new()
    local self = setmetatable({}, BrowserApp)
    
    -- Fonts
    self.font = love.graphics.newFont(12)
    self.urlFont = love.graphics.newFont(13)
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
    
    -- Dimensions (Relative)
    self.w, self.h = 800, 600
    self.navBarHeight = 44
    self.headerHeight = self.navBarHeight
    
    self.ui = {}
    self.title = "Browser"
    
    self:loadURL("http://home.com")
    
    return self
end

function BrowserApp:loadURL(url)
    if not url:match("^http://") and not url:match("^https://") then
        if url:match("%.") and not url:match("%s") then
            url = "http://" .. url
        else
            url = "http://google.com/search?q=" .. url:gsub("%s", "+")
        end
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
    self.loadDuration = math.random() * 0.4 + 0.2
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
    
    -- Update window title
    if self.siteInstance and self.siteInstance.title then
        self.title = self.siteInstance.title
    else
        local title = self.currentURL:gsub("http://", ""):gsub("https://", "")
        if title == "" then title = "Browser" end
        self.title = title
    end
end

function BrowserApp:create404()
    return {
        draw = function(s, x, y, w, h)
            love.graphics.setColor(0.98, 0.98, 0.98)
            love.graphics.rectangle("fill", x, y, w, h)
            love.graphics.setColor(Theme.textPrimary)
            love.graphics.setFont(self.font48)
            love.graphics.printf(":(", x, y + h*0.2, w, "center")
            love.graphics.setFont(self.urlFont)
            love.graphics.printf("This site can't be reached", x, y + h*0.2 + 80, w, "center")
            love.graphics.setColor(Theme.textSecondary)
            love.graphics.setFont(self.font)
            love.graphics.printf(self.currentURL .. " refused to connect.", x, y + h*0.2 + 110, w, "center")
        end,
        maxScroll = 0,
        scroll = 0,
        title = "404 Not Found"
    }
end

function BrowserApp:back()
    if self.historyIndex > 1 then
        self.historyIndex = self.historyIndex - 1
        self:loadURL(self.history[self.historyIndex])
    end
end

function BrowserApp:forward()
    if self.historyIndex < #self.history then
        self.historyIndex = self.historyIndex + 1
        self:loadURL(self.history[self.historyIndex])
    end
end

function BrowserApp:refresh()
    self:loadURL(self.currentURL)
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

function BrowserApp:draw(ax, ay, w, h)
    self.ax, self.ay, self.w, self.h = ax, ay, w, h
    
    -- 1. Draw Header (Translated)
    love.graphics.push()
    love.graphics.translate(ax, ay)
    
    -- Background
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    self:drawHeader(w)
    love.graphics.pop()
    
    -- 2. Draw Content (Absolute coordinates, with scissor)
    local contentY = self.headerHeight
    local contentH = h - self.headerHeight
    
    love.graphics.setScissor(ax, ay + contentY, w, contentH)
    
    if self.loading then
        self:drawLoadingScreen(ax, ay + contentY, w, contentH)
    elseif self.siteInstance then
        self.siteInstance:draw(ax, ay + contentY, w, contentH)
    end
    
    love.graphics.setScissor()
    
    -- 3. Draw Scrollbar (Translated)
    love.graphics.push()
    love.graphics.translate(ax, ay)
    self:drawScrollbar(w, contentH)
    
    -- Border
    love.graphics.setColor(Theme.border)
    love.graphics.rectangle("line", 0, 0, w, h)
    love.graphics.pop()
end

function BrowserApp:drawHeader(w)
    local mx, my = love.mouse.getPosition()
    mx, my = mx - self.ax, my - self.ay -- Relative mouse
    
    -- Nav Bar
    local navY = 0
    love.graphics.setColor(0.98, 0.98, 0.98)
    love.graphics.rectangle("fill", 0, navY, w, self.navBarHeight)
    love.graphics.setColor(0.85, 0.85, 0.85)
    love.graphics.line(0, navY + self.navBarHeight, w, navY + self.navBarHeight)
    
    local btnSize = 28
    local btnY = navY + (self.navBarHeight - btnSize) / 2
    local curX = 10
    
    local function drawNavBtn(id, icon, enabled, cx)
        local hovered = mx >= cx and mx <= cx + btnSize and my >= btnY and my <= my + btnSize
        if enabled and hovered then
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.circle("fill", cx + btnSize/2, btnY + btnSize/2, btnSize/2 + 2)
        end
        love.graphics.setColor(enabled and Theme.textSecondary or {0.7, 0.7, 0.7})
        love.graphics.setFont(self.urlFont)
        love.graphics.printf(icon, cx, btnY + 6, btnSize, "center")
        self.ui[id] = {x = cx, y = btnY, w = btnSize, h = btnSize, enabled = enabled}
        return cx + btnSize + 8
    end
    
    curX = drawNavBtn("back", "<", self.historyIndex > 1, curX)
    curX = drawNavBtn("forward", ">", self.historyIndex < #self.history, curX)
    curX = drawNavBtn("refresh", "R", true, curX)
    curX = drawNavBtn("home", "H", true, curX)
    
    -- Address Bar
    local urlW = w - (curX) - 40
    local urlX = curX + 10
    self.ui.url = {x = urlX, y = btnY - 2, w = urlW, h = btnSize + 4}
    
    love.graphics.setColor(Theme.urlBarBg)
    love.graphics.rectangle("fill", urlX, btnY - 2, urlW, btnSize + 4, 16)
    if self.urlActive then
        love.graphics.setColor(Theme.accent)
        love.graphics.rectangle("line", urlX, btnY - 2, urlW, btnSize + 4, 16)
    end
    
    love.graphics.setScissor(self.ax + urlX + 15, self.ay + btnY, urlW - 30, btnSize)
    love.graphics.setColor(Theme.textPrimary)
    love.graphics.setFont(self.urlFont)
    local urlText = self.urlActive and self.urlInput or self.currentURL
    love.graphics.print(urlText, urlX + 15, btnY + 7)
    
    if self.urlActive and math.floor(self.cursorBlink * 2) % 2 == 0 then
        local tw = self.urlFont:getWidth(self.urlInput)
        love.graphics.setColor(Theme.accent)
        love.graphics.line(urlX + 15 + tw, btnY + 4, urlX + 15 + tw, btnY + btnSize - 4)
    end
    love.graphics.setScissor()
    
    if self.loading then
        love.graphics.setColor(Theme.loadingBar)
        local progress = self.loadTimer / self.loadDuration
        love.graphics.rectangle("fill", 0, navY + self.navBarHeight - 2, w * progress, 2)
    end
end

function BrowserApp:drawLoadingScreen(x, y, w, h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    local cx, cy = x + w/2, y + h/2
    local radius = 15
    local angle = love.timer.getTime() * 5
    for i = 0, 7 do
        local a = angle + (i * math.pi / 4)
        local alpha = 0.2 + (i / 7) * 0.8
        love.graphics.setColor(Theme.loadingBar[1], Theme.loadingBar[2], Theme.loadingBar[3], alpha)
        love.graphics.circle("fill", cx + math.cos(a) * radius, cy + math.sin(a) * radius, 3)
    end
end

function BrowserApp:drawScrollbar(w, h)
    self.ui.scrollbar = nil
    if not self.siteInstance then return end
    
    local scroll = self.siteInstance.scroll or 0
    local maxScroll = self.siteInstance.maxScroll or 0
    local scrollbarW = 12
    local trackX = w - scrollbarW
    local trackY = self.headerHeight
    local trackH = h
    
    self.ui.scrollbar = {
        trackX = trackX, trackY = trackY, trackW = scrollbarW, trackH = trackH
    }
    
    -- Track background (Native feel)
    love.graphics.setColor(0.96, 0.96, 0.96)
    love.graphics.rectangle("fill", trackX, trackY, scrollbarW, trackH)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.line(trackX, trackY, trackX, trackY + trackH)
    
    if maxScroll > 0 then
        local thumbH = math.max(30, (h / (maxScroll + h)) * trackH)
        local maxThumbY = trackH - thumbH
        local thumbY = trackY + (scroll / maxScroll) * maxThumbY
        
        self.ui.scrollbar.thumbX = trackX
        self.ui.scrollbar.thumbY = thumbY
        self.ui.scrollbar.thumbW = scrollbarW
        self.ui.scrollbar.thumbH = thumbH
        
        local mx, my = love.mouse.getPosition()
        mx, my = mx - self.ax, my - self.ay
        local hovered = mx >= trackX and mx <= trackX + scrollbarW and my >= trackY and my <= trackY + trackH
        
        if hovered or self.isDraggingScrollbar then
            love.graphics.setColor(0.7, 0.7, 0.7)
        else
            love.graphics.setColor(0.8, 0.8, 0.8)
        end
        love.graphics.rectangle("fill", trackX + 2, thumbY + 2, scrollbarW - 4, thumbH - 4, 4)
    end
end

function BrowserApp:mousepressed(mx, my, button, absX, absY)
    if button ~= 1 and button ~= "l" then return end
    
    local function inBounds(b)
        return b and mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h
    end

    -- Header Controls (mx, my are already relative to browser origin)
    if my < self.headerHeight then
        if inBounds(self.ui.back) and self.ui.back.enabled then self:back(); return end
        if inBounds(self.ui.forward) and self.ui.forward.enabled then self:forward(); return end
        if inBounds(self.ui.refresh) then self:refresh(); return end
        if inBounds(self.ui.home) then self:loadURL("http://home.com"); return end
        
        if inBounds(self.ui.url) then
            self.urlActive = true
            if self.siteInstance then self.siteInstance.inputActive = false end 
            self.urlInput = self.currentURL
            return
        end
        self.urlActive = false
        return
    end
    
    self.urlActive = false
    
    -- Scrollbar
    local sb = self.ui.scrollbar
    if sb and mx >= sb.trackX - 5 and mx <= sb.trackX + sb.trackW then
        if my >= sb.thumbY and my <= sb.thumbY + sb.thumbH then
            self.isDraggingScrollbar = true
            self.dragStartY = my
            self.dragStartScroll = self.siteInstance.scroll
        elseif self.siteInstance.maxScroll and self.siteInstance.maxScroll > 0 then
            local clickRatio = (my - sb.trackY - sb.thumbH/2) / (sb.trackH - sb.thumbH)
            self.siteInstance.scroll = math.max(0, math.min(clickRatio * self.siteInstance.maxScroll, self.siteInstance.maxScroll))
        end
        return
    end
    
    -- Content Area (Use absolute coordinates for sites)
    if not self.loading and self.siteInstance and self.siteInstance.mousepressed then
        self.siteInstance:mousepressed(absX, absY, button)
    end
end

function BrowserApp:mousemoved(mx, my, dx, dy, absX, absY)
    if self.isDraggingScrollbar and self.siteInstance and self.ui.scrollbar then
        local sb = self.ui.scrollbar
        local deltaY = my - self.dragStartY
        local maxThumbTravel = sb.trackH - sb.thumbH
        if maxThumbTravel > 0 then
            local scrollRatio = deltaY / maxThumbTravel
            self.siteInstance.scroll = math.max(0, math.min(
                self.dragStartScroll + (scrollRatio * self.siteInstance.maxScroll),
                self.siteInstance.maxScroll
            ))
        end
        return
    end
    
    if not self.loading and self.siteInstance and self.siteInstance.mousemoved then
        self.siteInstance:mousemoved(absX, absY, dx, dy)
    end
end

function BrowserApp:mousereleased(mx, my, button, absX, absY)
    self.isDraggingScrollbar = false
    if not self.loading and self.siteInstance and self.siteInstance.mousereleased then
        self.siteInstance:mousereleased(absX, absY, button)
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
            self:loadURL(self.urlInput)
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
    self.w, self.h = w, h
end

return BrowserApp