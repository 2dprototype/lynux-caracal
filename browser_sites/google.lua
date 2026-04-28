local utf8 = require("utf8")
local Google = {}
Google.__index = Google

function Google.new(browser)
    local self = setmetatable({}, Google)
    self.browser = browser
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.logoFont = love.graphics.newFont("font/Nunito-Regular.ttf", 72) or love.graphics.newFont(72)
    self.query = ""
    if browser.urlInput:match("search%?q=(.*)") then
        self.query = browser.urlInput:match("search%?q=(.*)")
        -- Basic URL decode
        self.query = self.query:gsub("+", " ")
        self.query = self.query:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
        self.state = "results"
    else
        self.state = "home"
    end
    self.inputActive = false
    
    self.results = {
        {title="LÖVE - Free 2D Game Engine", url="https://love2d.org", desc="LÖVE is an awesome framework you can use to make 2D games in Lua."},
        {title="Lua: about", url="https://www.lua.org/about.html", desc="Lua is a powerful, efficient, lightweight, embeddable scripting language."},
        {title="Stack Overflow", url="https://stackoverflow.com", desc="Where developers learn, share their knowledge, and build their careers."},
    }
    
    return self
end

function Google:draw(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    
    if self.state == "home" then
        local cy = y + h * 0.3
        
        -- Logo
        love.graphics.setFont(self.logoFont)
        local logoW = self.logoFont:getWidth("Google")
        local letters = {"G", "o", "o", "g", "l", "e"}
        local colors = {
            {0.26, 0.52, 0.96}, -- blue
            {0.92, 0.26, 0.21}, -- red
            {0.98, 0.73, 0.02}, -- yellow
            {0.26, 0.52, 0.96}, -- blue
            {0.2, 0.66, 0.33},  -- green
            {0.92, 0.26, 0.21}, -- red
        }
        local cx = x + (w - logoW)/2
        for i, l in ipairs(letters) do
            love.graphics.setColor(colors[i])
            love.graphics.print(l, cx, cy)
            cx = cx + self.logoFont:getWidth(l)
        end
        
        cy = cy + 100
        
        -- Input
        local inputW = 584
        local inputX = x + (w - inputW) / 2
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", inputX, cy, inputW, 44, 22)
        love.graphics.setColor(0.8, 0.8, 0.8)
        if self.inputActive then love.graphics.setColor(0.6, 0.6, 0.6) end
        love.graphics.rectangle("line", inputX, cy, inputW, 44, 22)
        
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.setFont(self.font)
        love.graphics.print(self.query, inputX + 20, cy + 14)
        if self.inputActive and math.floor(love.timer.getTime() * 2) % 2 == 0 then
            local tw = self.font:getWidth(self.query)
            love.graphics.line(inputX + 20 + tw, cy + 10, inputX + 20 + tw, cy + 34)
        end
        
        cy = cy + 70
        
        -- Buttons
        local btnW = 120
        local btn1X = x + w/2 - btnW - 10
        local btn2X = x + w/2 + 10
        
        local mx, my = love.mouse.getPosition()
        local hovered1 = mx >= btn1X and mx <= btn1X+btnW and my >= cy and my <= cy+36
        local hovered2 = mx >= btn2X and mx <= btn2X+btnW and my >= cy and my <= cy+36
        
        love.graphics.setColor(0.96, 0.96, 0.96)
        if hovered1 then love.graphics.setColor(0.9, 0.9, 0.9) end
        love.graphics.rectangle("fill", btn1X, cy, btnW, 36, 4)
        
        love.graphics.setColor(0.96, 0.96, 0.96)
        if hovered2 then love.graphics.setColor(0.9, 0.9, 0.9) end
        love.graphics.rectangle("fill", btn2X, cy, btnW, 36, 4)
        
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.printf("Google Search", btn1X, cy + 10, btnW, "center")
        love.graphics.printf("I'm Feeling Lucky", btn2X, cy + 10, btnW, "center")
        
    elseif self.state == "results" then
        -- Header
        love.graphics.setColor(0.98, 0.98, 0.98)
        love.graphics.rectangle("fill", x, y, w, 80)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.line(x, y + 80, x + w, y + 80)
        
        love.graphics.setFont(self.logoFont)
        love.graphics.setColor(0.26, 0.52, 0.96)
        love.graphics.print("G", x + 20, y - 5)
        
        -- Input
        love.graphics.setFont(self.font)
        local inputW = 600
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", x + 80, y + 20, inputW, 40, 20)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", x + 80, y + 20, inputW, 40, 20)
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.print(self.query, x + 100, y + 32)
        
        -- Results
        local cy = y + 100
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("About 3 results (0.34 seconds)", x + 100, cy)
        cy = cy + 40
        
        for i, r in ipairs(self.results) do
            love.graphics.setColor(0.1, 0.6, 0.1)
            love.graphics.print(r.url, x + 100, cy)
            cy = cy + 20
            
            love.graphics.setColor(0.1, 0.1, 0.8)
            local tFont = love.graphics.newFont("font/Nunito-Regular.ttf", 20) or love.graphics.newFont(20)
            love.graphics.setFont(tFont)
            love.graphics.print(r.title, x + 100, cy)
            cy = cy + 25
            
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.setFont(self.font)
            love.graphics.print(r.desc, x + 100, cy)
            cy = cy + 40
        end
    end
end

function Google:mousepressed(mx, my, button)
    local w = self.w
    local x = self.x
    local y = self.y
    if self.state == "home" then
        local inputW = 584
        local inputX = x + (w - inputW) / 2
        local cy = y + self.h * 0.3 + 100
        
        if mx >= inputX and mx <= inputX + inputW and my >= cy and my <= cy + 44 then
            self.inputActive = true
        else
            self.inputActive = false
            
            cy = cy + 70
            local btnW = 120
            local btn1X = x + w/2 - btnW - 10
            local btn2X = x + w/2 + 10
            
            if mx >= btn1X and mx <= btn1X+btnW and my >= cy and my <= cy+36 then
                if self.query ~= "" then
                    self.browser:loadURL("http://google.com/search?q=" .. self.query)
                end
            end
            if mx >= btn2X and mx <= btn2X+btnW and my >= cy and my <= cy+36 then
                -- I'm feeling lucky
                if self.query ~= "" then
                    self.browser:loadURL("http://google.com/search?q=" .. self.query)
                end
            end
        end
    end
end

function Google:keypressed(key)
    if self.inputActive and self.state == "home" then
        if key == "backspace" then
            local bo = utf8.offset(self.query, -1)
            if bo then
                self.query = self.query:sub(1, bo - 1)
            end
        elseif key == "return" then
            if self.query ~= "" then
                self.browser:loadURL("http://google.com/search?q=" .. self.query)
            end
        end
    end
end

function Google:textinput(text)
    if self.inputActive and self.state == "home" then
        self.query = self.query .. text
    end
end

return Google
