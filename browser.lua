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
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 12) or love.graphics.newFont(12)
    self.urlFont = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    
    self.history = {}
    self.historyIndex = 0
    self.currentURL = ""
    self.urlInput = ""
    self.urlActive = false
    
    self.siteInstance = nil
    self.loading = false
    self.loadTimer = 0
    self.loadDuration = 0
    
    self.windowWidth = 800
    self.windowHeight = 600
    
    self:loadURL("http://home.com")
    
    return self
end

function BrowserApp:loadURL(url)
    if not url:match("^http://") and not url:match("^https://") then
        url = "http://" .. url
    end
    
    self.urlInput = url
    self.urlActive = false
    
    if self.history[self.historyIndex] ~= url then
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
        self.siteInstance = self:create404()
    end
end

function BrowserApp:create404()
    return {
        draw = function(s, x, y, w, h)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", x, y, w, h)
            love.graphics.setColor(0, 0, 0)
            love.graphics.setFont(self.urlFont)
            love.graphics.printf("404 Page Not Found", x, y + 50, w, "center")
            love.graphics.setFont(self.font)
            love.graphics.printf(self.currentURL, x, y + 80, w, "center")
        end
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

function BrowserApp:update(dt)
    if self.loading then
        self.loadTimer = self.loadTimer + dt
        if self.loadTimer >= self.loadDuration then
            self:finishLoading()
        end
    end
    if self.siteInstance and self.siteInstance.update then
        self.siteInstance:update(dt)
    end
end

function BrowserApp:draw(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.windowWidth = w
    self.windowHeight = h
    local headerHeight = 40
    
    -- Background
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", x, y, w, headerHeight)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.line(x, y + headerHeight, x + w, y + headerHeight)
    
    -- Buttons
    local btnY = y + 5
    local backX = x + 5
    local fwdX = x + 35
    local homeX = x + 65
    
    love.graphics.setFont(self.urlFont)
    -- Back
    love.graphics.setColor(self.historyIndex > 1 and {0.1,0.1,0.1} or {0.7,0.7,0.7})
    love.graphics.print("<", backX + 8, btnY + 5)
    
    -- Forward
    love.graphics.setColor(self.historyIndex < #self.history and {0.1,0.1,0.1} or {0.7,0.7,0.7})
    love.graphics.print(">", fwdX + 8, btnY + 5)
    
    -- Home
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.print("H", homeX + 8, btnY + 5)
    
    -- URL Bar
    local urlX = x + 95
    local urlW = w - 105
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", urlX, btnY, urlW, 30, 15)
    
    if self.urlActive then
        love.graphics.setColor(0.1, 0.5, 0.9)
        love.graphics.rectangle("line", urlX, btnY, urlW, 30, 15)
    else
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", urlX, btnY, urlW, 30, 15)
    end
    
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.setScissor(urlX + 10, btnY, urlW - 20, 30)
    love.graphics.print(self.urlInput, urlX + 10, btnY + 6)
    if self.urlActive and math.floor(love.timer.getTime() * 2) % 2 == 0 then
        local tw = self.urlFont:getWidth(self.urlInput)
        love.graphics.line(urlX + 10 + tw, btnY + 5, urlX + 10 + tw, btnY + 25)
    end
    love.graphics.setScissor()
    
    -- Loading bar
    if self.loading then
        love.graphics.setColor(0.1, 0.5, 0.9)
        love.graphics.rectangle("fill", x, y + headerHeight - 2, w * (self.loadTimer / self.loadDuration), 2)
    end
    
    -- Draw Site Content
    local contentY = y + headerHeight
    local contentH = h - headerHeight
    
    love.graphics.setScissor(x, contentY, w, contentH)
    if not self.loading and self.siteInstance then
        if self.siteInstance.draw then
            self.siteInstance:draw(x, contentY, w, contentH)
        end
    elseif not self.loading then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", x, contentY, w, contentH)
    end
    love.graphics.setScissor()
end

function BrowserApp:mousepressed(rx, ry, button, ax, ay)
    if not ax then ax = self.x + rx end
    if not ay then ay = self.y + ry end
    
    if button == 1 then
        local headerHeight = 40
        if ry <= headerHeight then
            if ry >= 5 and ry <= 35 then
                if rx >= 5 and rx <= 30 then self:back()
                elseif rx >= 35 and rx <= 60 then self:forward()
                elseif rx >= 65 and rx <= 90 then self:loadURL("http://home.com")
                elseif rx >= 95 and rx <= self.w - 10 then
                    self.urlActive = true
                    return
                end
            end
            self.urlActive = false
        else
            self.urlActive = false
            if not self.loading and self.siteInstance and self.siteInstance.mousepressed then
                self.siteInstance:mousepressed(ax, ay, button)
            end
        end
    end
end

function BrowserApp:mousemoved(ax, ay, dx, dy)
    if not self.loading and self.siteInstance and self.siteInstance.mousemoved then
        self.siteInstance:mousemoved(ax, ay, dx, dy)
    end
end

function BrowserApp:mousereleased(ax, ay, button)
    if not self.loading and self.siteInstance and self.siteInstance.mousereleased then
        self.siteInstance:mousereleased(ax, ay, button)
    end
end

function BrowserApp:wheelmoved(wx, wy)
    if not self.loading and self.siteInstance and self.siteInstance.wheelmoved then
        self.siteInstance:wheelmoved(wx, wy)
    end
end

function BrowserApp:keypressed(key)
    if self.urlActive then
        if key == "backspace" then
            local byteoffset = utf8.offset(self.urlInput, -1)
            if byteoffset then
                self.urlInput = string.sub(self.urlInput, 1, byteoffset - 1)
            end
        elseif key == "return" then
            self:loadURL(self.urlInput)
        end
    else
        if not self.loading and self.siteInstance and self.siteInstance.keypressed then
            self.siteInstance:keypressed(key)
        end
    end
end

function BrowserApp:textinput(text)
    if self.urlActive then
        self.urlInput = self.urlInput .. text
    else
        if not self.loading and self.siteInstance and self.siteInstance.textinput then
            self.siteInstance:textinput(text)
        end
    end
end

function BrowserApp:resize(w, h)
    self.windowWidth = w
    self.windowHeight = h
end

return BrowserApp