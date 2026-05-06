-- google.lua
local utf8 = require("utf8")
local Google = {}
Google.__index = Google

function Google.new(browser)
    local self = setmetatable({}, Google)
    self.h = 0
    self.browser = browser
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.smallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 12) or love.graphics.newFont(12)
    self.logoFont = love.graphics.newFont("font/Nunito-Regular.ttf", 72) or love.graphics.newFont(72)
    self.resultFont = love.graphics.newFont("font/Nunito-Regular.ttf", 20) or love.graphics.newFont(20)
    
    self.query = ""
    self.inputActive = false
    
    -- Parse URL for search query
    if browser.urlInput:match("search%?q=(.*)") then
        self.query = browser.urlInput:match("search%?q=(.*)")
        -- URL decode
        self.query = self.query:gsub("+", " ")
        self.query = self.query:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
        self.state = "results"
        self:performSearch()
    else
        self.state = "home"
    end
    
    self.scroll = 0
    self.maxScroll = 0
    
    return self
end

function Google:performSearch()
    -- Comprehensive search database
    local searchDB = {
        {
            keywords = {"love", "love2d", "game", "engine", "framework", "2d", "lua"},
            title = "LÖVE - Free 2D Game Engine",
            url = "https://love2d.org",
            desc = "LÖVE is an awesome framework you can use to make 2D games in Lua. It's free, open-source, and works on Windows, Mac OS X, Linux, Android and iOS."
        },
        {
            keywords = {"lua", "programming", "language", "script", "learn"},
            title = "Lua: The Programming Language",
            url = "https://www.lua.org/about.html",
            desc = "Lua is a powerful, efficient, lightweight, embeddable scripting language. It supports procedural programming, object-oriented programming, functional programming, data-driven programming, and data description."
        },
        {
            keywords = {"stack", "overflow", "developer", "code", "question", "answer", "programming"},
            title = "Stack Overflow - Where Developers Learn, Share, & Build",
            url = "https://stackoverflow.com",
            desc = "Stack Overflow is the largest, most trusted online community for developers to learn, share their programming knowledge, and build their careers."
        },
        {
            keywords = {"desktop", "simulator", "os", "operating", "system", "virtual"},
            title = "Desktop Simulator - Virtual OS Environment",
            url = "https://github.com/desktop-simulator",
            desc = "An open-source desktop environment simulator built with Love2D and Lua. Features a working browser, email client, and more."
        },
        {
            keywords = {"github", "git", "repository", "code", "open source"},
            title = "GitHub: Let's build from here",
            url = "https://github.com",
            desc = "GitHub is where over 100 million developers shape the future of software, together. Contribute to the open source community, manage your Git repositories."
        },
        {
            keywords = {"reddit", "social", "news", "community", "forum"},
            title = "Reddit - Dive into anything",
            url = "https://reddit.com",
            desc = "Reddit is a network of communities where people can dive into their interests, hobbies and passions. There's a community for whatever you're interested in."
        },
        {
            keywords = {"twitter", "social", "media", "tweet", "follow"},
            title = "Twitter. It's what's happening",
            url = "https://twitter.com",
            desc = "From breaking news and entertainment to sports and politics, get the full story with all the live commentary."
        },
        {
            keywords = {"news", "breaking", "current", "events", "headlines"},
            title = "Google News - Top Stories",
            url = "https://news.google.com",
            desc = "Comprehensive up-to-date news coverage, aggregated from sources all over the world by Google News."
        }
    }
    
    -- Search algorithm
    self.results = {}
    local queryLower = self.query:lower()
    local queryWords = {}
    for word in queryLower:gmatch("%S+") do
        table.insert(queryWords, word)
    end
    
    for _, item in ipairs(searchDB) do
        local score = 0
        local titleLower = item.title:lower()
        local descLower = item.desc:lower()
        
        for _, qWord in ipairs(queryWords) do
            -- Check title
            if titleLower:find(qWord, 1, true) then
                score = score + 10
            end
            -- Check description
            if descLower:find(qWord, 1, true) then
                score = score + 5
            end
            -- Check keywords
            for _, kw in ipairs(item.keywords) do
                if kw == qWord then
                    score = score + 8
                elseif kw:find(qWord, 1, true) then
                    score = score + 3
                end
            end
        end
        
        if score > 0 then
            table.insert(self.results, {
                title = item.title,
                url = item.url,
                desc = item.desc,
                score = score
            })
        end
    end
    
    -- Sort by score
    table.sort(self.results, function(a, b) return a.score > b.score end)
end

function Google:update(dt)
    -- Update scroll bounds
    if self.state == "results" then
        local totalHeight = 150 -- Header
        totalHeight = totalHeight + (#self.results * 90) -- Results
        self.maxScroll = math.max(0, totalHeight - self.h + 50)
    end
end

function Google:draw(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    
    love.graphics.setColor(0.12, 0.12, 0.14)
    love.graphics.rectangle("fill", x, y, w, h)
    
    if self.state == "home" then
        self:drawHome(x, y, w, h)
    else
        self:drawResults(x, y, w, h)
    end
end

function Google:drawHome(x, y, w, h)
    -- Center everything
    local centerX = x + w/2
    local cy = y + h * 0.2
    
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
    
    love.graphics.setFont(self.logoFont)
    local totalWidth = 0
    for i, l in ipairs(letters) do
        totalWidth = totalWidth + self.logoFont:getWidth(l)
    end
    
    local lx = centerX - totalWidth/2
    for i, l in ipairs(letters) do
        love.graphics.setColor(colors[i])
        love.graphics.print(l, lx, cy)
        lx = lx + self.logoFont:getWidth(l)
    end
    
    cy = cy + 120
    
    -- Search box
    local inputW = math.min(600, w - 80)
    local inputX = centerX - inputW/2
    
    love.graphics.setColor(0.2, 0.2, 0.22)
    love.graphics.rectangle("fill", inputX, cy, inputW, 50, 25)
    
    love.graphics.setColor(0.3, 0.3, 0.35)
    if self.inputActive then
        love.graphics.setColor(0.3, 0.5, 0.9)
    end
    love.graphics.rectangle("line", inputX, cy, inputW, 50, 25)
    
    -- Search icon
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setFont(self.resultFont)
    love.graphics.print("🔍", inputX + 12, cy + 12)
    
    -- Query text
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setFont(self.font)
    love.graphics.print(self.query, inputX + 50, cy + 18)
    
    if self.inputActive and math.floor(love.timer.getTime() * 2) % 2 == 0 then
        local tw = self.font:getWidth(self.query)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.line(inputX + 50 + tw, cy + 12, inputX + 50 + tw, cy + 38)
    end
    
    cy = cy + 70
    
    -- Buttons
    local btnW = 140
    local btnH = 40
    local spacing = 20
    local btn1X = centerX - btnW - spacing/2
    local btn2X = centerX + spacing/2
    
    local mx, my = love.mouse.getPosition()
    local hovered1 = mx >= btn1X and mx <= btn1X + btnW and my >= cy and my <= cy + btnH
    local hovered2 = mx >= btn2X and mx <= btn2X + btnW and my >= cy and my <= cy + btnH
    
    love.graphics.setColor(0.22, 0.22, 0.25)
    if hovered1 then love.graphics.setColor(0.28, 0.28, 0.3) end
    love.graphics.rectangle("fill", btn1X, cy, btnW, btnH, 6)
    
    love.graphics.setColor(0.22, 0.22, 0.25)
    if hovered2 then love.graphics.setColor(0.28, 0.28, 0.3) end
    love.graphics.rectangle("fill", btn2X, cy, btnW, btnH, 6)
    
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setFont(self.font)
    love.graphics.printf("Google Search", btn1X, cy + 12, btnW, "center")
    love.graphics.printf("I'm Feeling Lucky", btn2X, cy + 12, btnW, "center")
end

function Google:drawResults(x, y, w, h)
    -- Header
    love.graphics.setColor(0.15, 0.15, 0.17)
    love.graphics.rectangle("fill", x, y, w, 70)
    
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.line(x, y + 70, x + w, y + 70)
    
    -- Google logo small
    love.graphics.setColor(0.26, 0.52, 0.96)
    love.graphics.setFont(self.resultFont)
    love.graphics.print("G", x + 20, y + 20)
    love.graphics.print("o", x + 38, y + 20)
    love.graphics.setColor(0.92, 0.26, 0.21)
    love.graphics.print("o", x + 55, y + 20)
    love.graphics.setColor(0.98, 0.73, 0.02)
    love.graphics.print("g", x + 72, y + 20)
    love.graphics.setColor(0.26, 0.52, 0.96)
    love.graphics.print("l", x + 91, y + 20)
    love.graphics.setColor(0.2, 0.66, 0.33)
    love.graphics.print("e", x + 104, y + 20)
    
    -- Search input in results
    local inputW = math.min(w - 250, 500)
    local inputX = x + 160
    
    love.graphics.setColor(0.2, 0.2, 0.22)
    love.graphics.rectangle("fill", inputX, y + 15, inputW, 40, 20)
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("line", inputX, y + 15, inputW, 40, 20)
    
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setFont(self.font)
    love.graphics.print(self.query, inputX + 15, y + 27)
    
    -- Results
    local contentY = y + 90 - self.scroll
    love.graphics.setScissor(x, y + 70, w, h - 70)
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setFont(self.smallFont)
    love.graphics.print("About " .. #self.results .. " results (0." .. math.random(10, 99) .. " seconds)", x + 100, contentY)
    
    contentY = contentY + 30
    
    for i, result in ipairs(self.results) do
        -- URL
        love.graphics.setColor(0.5, 0.7, 0.5)
        love.graphics.setFont(self.smallFont)
        love.graphics.print(result.url, x + 100, contentY)
        
        -- Title
        contentY = contentY + 18
        love.graphics.setColor(0.4, 0.6, 0.9)
        local titleFont = love.graphics.newFont("font/Nunito-Regular.ttf", 20) or love.graphics.newFont(20)
        love.graphics.setFont(titleFont)
        love.graphics.print(result.title, x + 100, contentY)
        
        -- Description
        contentY = contentY + 25
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(self.font)
        -- Truncate description if needed
        local desc = result.desc
        if #desc > 150 then desc = string.sub(desc, 1, 147) .. "..." end
        love.graphics.printf(desc, x + 100, contentY, w - 200, "left")
        
        contentY = contentY + 60
    end
    
    love.graphics.setScissor()
end

function Google:mousepressed(mx, my, button)
    if button ~= 1 then return end
    
    if self.state == "home" then
        local inputW = math.min(600, self.w - 80)
        local inputX = self.x + self.w/2 - inputW/2
        local cy = self.y + self.h * 0.2 + 120
        
        if mx >= inputX and mx <= inputX + inputW and my >= cy and my <= cy + 50 then
            self.inputActive = true
            return
        end
        
        self.inputActive = false
        
        -- Buttons
        cy = cy + 70
        local btnW = 140
        local btnH = 40
        local spacing = 20
        local centerX = self.x + self.w/2
        local btn1X = centerX - btnW - spacing/2
        local btn2X = centerX + spacing/2
        
        if mx >= btn1X and mx <= btn1X + btnW and my >= cy and my <= cy + btnH then
            if self.query ~= "" then
                self.browser:loadURL("http://google.com/search?q=" .. self.query:gsub("%s", "+"))
            end
        elseif mx >= btn2X and mx <= btn2X + btnW and my >= cy and my <= cy + btnH then
            if self.query ~= "" then
                self.browser:loadURL("http://google.com/search?q=" .. self.query:gsub("%s", "+"))
            end
        end
    else
        -- Results page - check search input
        local inputW = math.min(self.w - 250, 500)
        local inputX = self.x + 160
        if mx >= inputX and mx <= inputX + inputW and my >= self.y + 15 and my <= self.y + 55 then
            self.state = "home"
            self.inputActive = true
            return
        end
    end
end

function Google:wheelmoved(wx, wy)
    if self.state == "results" and self.maxScroll > 0 then
        self.scroll = math.max(0, math.min(self.maxScroll, self.scroll - wy * 50))
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
                self.browser:loadURL("http://google.com/search?q=" .. self.query:gsub("%s", "+"))
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