local utf8 = require("utf8")
local Google = {}
Google.__index = Google

function Google.new(browser)
    local self = setmetatable({}, Google)
    self.browser = browser
    self.font = love.graphics.newFont(14)
    self.fontSmall = love.graphics.newFont(12)
    self.fontTitle = love.graphics.newFont(20)
    self.fontLogo = love.graphics.newFont(64)
    self.fontLogoSmall = love.graphics.newFont(24)
    
    self.query = ""
    self.inputActive = false
    self.state = "home" -- "home" or "results"
    self.scroll = 0
    self.maxScroll = 0
    
    self.ui = { results = {} }
    
    self.title = "Google"
    
    -- Parse URL for search query
    if browser.urlInput:match("search%?q=(.*)") then
        self.query = browser.urlInput:match("search%?q=(.*)")
        -- URL decode
        self.query = self.query:gsub("+", " ")
        self.query = self.query:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
        self.state = "results"
        self:performSearch()
    end
    
    return self
end

function Google:performSearch()
    -- Mock search results + Dynamic results from mapping
    local searchDB = {
        {
            title = "LÖVE - Free 2D Game Engine",
            url = "https://love2d.org",
            desc = "LÖVE is an awesome framework you can use to make 2D games in Lua. It's free, open-source, and works on Windows, Mac OS X, Linux, Android and iOS."
        },
        {
            title = "Lua: The Programming Language",
            url = "https://www.lua.org",
            desc = "Lua is a powerful, efficient, lightweight, embeddable scripting language. It supports procedural programming, object-oriented programming, functional programming, etc."
        },
        {
            title = "Twitter",
            url = "http://twitter.com",
            desc = "Social network to stay informed about what's happening in the world."
        },
        {
            title = "Reddit: The front page of the internet",
            url = "http://reddit.com",
            desc = "Reddit is a network of communities where people can dive into their interests, hobbies and passions."
        },
        {
            title = "Bing",
            url = "http://bing.com",
            desc = "Microsoft's search engine. Provides search results, news, and more."
        },
        {
            title = "4chan /g/ - Technology",
            url = "http://4chan.org",
            desc = "A simple image-based bulletin board where anyone can post comments and share images."
        },
        {
            title = "Global News Network",
            url = "http://news.com",
            desc = "Latest breaking news, pictures, videos, and special reports from around the world."
        },
        {
            title = "GitHub: Let's build from here",
            url = "https://github.com",
            desc = "GitHub is where over 100 million developers shape the future of software, together. Contribute to the open source community, manage your Git repositories."
        }
    }
    
    self.results = {}
    local queryLower = self.query:lower()
    for _, item in ipairs(searchDB) do
        if item.title:lower():find(queryLower, 1, true) or item.desc:lower():find(queryLower, 1, true) or item.url:lower():find(queryLower, 1, true) then
            table.insert(self.results, item)
        end
    end
    
    -- Fallback if no results
    if #self.results == 0 then
        table.insert(self.results, {
            title = "No results found for '" .. self.query .. "'",
            url = "",
            desc = "Try different keywords or check your spelling."
        })
    end
    
    self.title = self.query .. " - Google Search"
end

function Google:draw(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    
    if self.state == "home" then
        self:drawHome(x, y, w, h)
    else
        self:drawResults(x, y, w, h)
    end
end

function Google:drawHome(x, y, w, h)
    local cy = y + h * 0.25
    local centerX = x + w/2
    
    -- Logo
    local letters = {"G", "o", "o", "g", "l", "e"}
    local colors = {
        {0.26, 0.52, 0.96}, -- blue
        {0.92, 0.26, 0.21}, -- red
        {0.98, 0.73, 0.02}, -- yellow
        {0.26, 0.52, 0.96}, -- blue
        {0.2, 0.66, 0.33},  -- green
        {0.92, 0.26, 0.21}, -- red
    }
    
    love.graphics.setFont(self.fontLogo)
    local totalW = 0
    for i, l in ipairs(letters) do totalW = totalW + self.fontLogo:getWidth(l) end
    local lx = centerX - totalW/2
    for i, l in ipairs(letters) do
        love.graphics.setColor(colors[i])
        love.graphics.print(l, lx, cy)
        lx = lx + self.fontLogo:getWidth(l)
    end
    
    cy = cy + 100
    
    -- Search bar
    local inputW = math.min(500, w - 80)
    local inputX = centerX - inputW/2
    local inputH = 46
    
    local mx, my = love.mouse.getPosition()
    local hovered = mx >= inputX and mx <= inputX + inputW and my >= cy and my <= cy + inputH
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", inputX, cy, inputW, inputH, 23)
    
    if self.inputActive or hovered then
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", inputX, cy, inputW, inputH, 23)
        -- Shadow effect simulated
        love.graphics.setColor(0, 0, 0, 0.05)
        love.graphics.rectangle("line", inputX-1, cy-1, inputW+2, inputH+2, 24)
    else
        love.graphics.setColor(0.87, 0.88, 0.9)
        love.graphics.rectangle("line", inputX, cy, inputW, inputH, 23)
    end
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setFont(self.font)
    love.graphics.print("S", inputX + 16, cy + 14)
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print(self.query, inputX + 45, cy + 14)
    
    if self.inputActive and math.floor(love.timer.getTime() * 2) % 2 == 0 then
        local tw = self.font:getWidth(self.query)
        love.graphics.setColor(0.26, 0.52, 0.96)
        love.graphics.line(inputX + 45 + tw, cy + 12, inputX + 45 + tw, cy + 34)
    end
    
    cy = cy + 80
    
    -- Buttons
    local btnW = 140
    local btnH = 36
    local b1x = centerX - btnW - 10
    local b2x = centerX + 10
    
    local function drawBtn(tx, bx)
        local hov = mx >= bx and mx <= bx + btnW and my >= cy and my <= cy + btnH
        love.graphics.setColor(hov and {0.95, 0.95, 0.95} or {0.97, 0.97, 0.97})
        love.graphics.rectangle("fill", bx, cy, btnW, btnH, 4)
        love.graphics.setColor(0.85, 0.85, 0.85)
        love.graphics.rectangle("line", bx, cy, btnW, btnH, 4)
        love.graphics.setColor(0.23, 0.25, 0.26)
        love.graphics.printf(tx, bx, cy + 10, btnW, "center")
    end
    
    drawBtn("Google Search", b1x)
    drawBtn("I'm Feeling Lucky", b2x)
end

function Google:drawResults(x, y, w, h)
    self.ui.results = {}
    
    -- Results header
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, 110)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.line(x, y + 110, x + w, y + 110)
    
    -- Small Logo
    local letters = {"G", "o", "o", "g", "l", "e"}
    local colors = {
        {0.26, 0.52, 0.96}, {0.92, 0.26, 0.21}, {0.98, 0.73, 0.02},
        {0.26, 0.52, 0.96}, {0.2, 0.66, 0.33}, {0.92, 0.26, 0.21}
    }
    
    love.graphics.setFont(self.fontLogoSmall)
    local lx = x + 30
    for i, l in ipairs(letters) do
        love.graphics.setColor(colors[i])
        love.graphics.print(l, lx, y + 25)
        lx = lx + self.fontLogoSmall:getWidth(l)
    end
    
    -- Search bar in results
    local inputX = x + 160
    local inputW = math.min(600, w - 200)
    local inputH = 40
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", inputX, y + 20, inputW, inputH, 20)
    love.graphics.setColor(0.87, 0.88, 0.9)
    love.graphics.rectangle("line", inputX, y + 20, inputW, inputH, 20)
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setFont(self.font)
    love.graphics.print(self.query, inputX + 20, y + 31)
    
    -- Results list
    local ry = y + 130 - self.scroll
    love.graphics.setScissor(x, y + 111, w, h - 111)
    
    love.graphics.setColor(0.44, 0.46, 0.48)
    love.graphics.setFont(self.fontSmall)
    love.graphics.print("About " .. #self.results .. " results", x + 160, ry)
    ry = ry + 30
    
    local mx, my = love.mouse.getPosition()
    
    for i, res in ipairs(self.results) do
        -- URL
        love.graphics.setColor(0.23, 0.25, 0.26)
        love.graphics.setFont(self.fontSmall)
        love.graphics.print(res.url, x + 160, ry)
        
        -- Title
        ry = ry + 18
        local tw = self.fontTitle:getWidth(res.title)
        local th = self.fontTitle:getHeight()
        local hovered = mx >= x + 160 and mx <= x + 160 + tw and my >= ry and my <= ry + th
        
        if hovered and res.url ~= "" then
            love.graphics.setColor(0.1, 0.45, 0.9)
            love.graphics.line(x + 160, ry + th, x + 160 + tw, ry + th)
        else
            love.graphics.setColor(0.1, 0.27, 0.63)
        end
        
        love.graphics.setFont(self.fontTitle)
        love.graphics.print(res.title, x + 160, ry)
        
        -- Add to UI hitboxes
        if res.url ~= "" then
            table.insert(self.ui.results, {x = x + 160, y = ry, w = tw, h = th, url = res.url})
        end
        
        -- Desc
        ry = ry + 30
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.setFont(self.font)
        love.graphics.printf(res.desc, x + 160, ry, w - 300, "left")
        
        ry = ry + 80
    end
    
    self.maxScroll = math.max(0, (ry + self.scroll) - (y + h) + 50)
    love.graphics.setScissor()
end

function Google:mousepressed(mx, my, button)
    if button ~= 1 and button ~= "l" then return end
    
    if self.state == "home" then
        local inputW = math.min(500, self.w - 80)
        local inputX = self.x + self.w/2 - inputW/2
        local cy = self.y + self.h * 0.25 + 100
        
        if mx >= inputX and mx <= inputX + inputW and my >= cy and my <= cy + 46 then
            self.inputActive = true
            return
        end
        self.inputActive = false
        
        -- Search button check
        local btnW = 140
        local btnH = 36
        local centerX = self.x + self.w/2
        local b1x = centerX - btnW - 10
        if mx >= b1x and mx <= b1x + btnW and my >= cy + 80 and my <= cy + 80 + btnH then
            if self.query ~= "" then
                self:performSearch()
                self.state = "results"
            end
            return
        end
    else
        -- Check search bar in results
        local inputX = self.x + 160
        if mx >= inputX and mx <= inputX + 600 and my >= self.y + 20 and my <= self.y + 60 then
            self.state = "home"
            self.inputActive = true
            return
        end
        
        -- Check results
        for _, res in ipairs(self.ui.results) do
            if mx >= res.x and mx <= res.x + res.w and my >= res.y and my <= res.y + res.h then
                self.browser:loadURL(res.url)
                return
            end
        end
    end
end

function Google:keypressed(key)
    if self.inputActive then
        if key == "backspace" then
            local bo = utf8.offset(self.query, -1)
            if bo then self.query = self.query:sub(1, bo - 1) end
        elseif key == "return" and self.query ~= "" then
            self:performSearch()
            self.state = "results"
            self.inputActive = false
        end
    end
end

function Google:textinput(text)
    if self.inputActive then
        self.query = self.query .. text
    end
end

return Google