local Home = {}
Home.__index = Home

function Home.new(browser)
    local self = setmetatable({}, Home)
    self.browser = browser
    self.font = love.graphics.newFont(14)
    self.titleFont = love.graphics.newFont(32)
    self.query = ""
    self.inputActive = true
    
    self.scroll = 0
    self.maxScroll = 0
    
    self.ui = { sites = {} }
    
    self.sites = {
        {name="Google", url="http://google.com", color={0.2, 0.5, 0.9}},
        {name="Bing", url="http://bing.com", color={0.1, 0.6, 0.6}},
        {name="Twitter", url="http://twitter.com", color={0.1, 0.6, 0.9}},
        {name="Reddit", url="http://reddit.com", color={1, 0.3, 0}},
        {name="4CHAN", url="http://4chan.org", color={0.1, 0.4, 0.2}},
        {name="News", url="http://news.com", color={0.7, 0.1, 0.1}},
        {name="Github", url="http://github.com", color={0.2, 0.2, 0.2}},
        {name="Stack", url="http://stackoverflow.com", color={0.9, 0.5, 0.1}},
    }
    return self
end

function Home:draw(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    
    love.graphics.setColor(0.98, 0.98, 0.98)
    love.graphics.rectangle("fill", x, y, w, h)
    
    love.graphics.push()
    love.graphics.translate(0, -self.scroll)
    
    local cy = y + h * 0.15
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Welcome to Browser", x, cy, w, "center")
    
    cy = cy + 70
    
    -- Safe responsive bounds
    local inputW = math.max(200, math.min(600, w - 60)) 
    local inputX = x + (w - inputW) / 2
    self.ui.input = { x = inputX, y = cy, w = inputW, h = 46 }
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", inputX, cy, inputW, 46, 23)
    
    if self.inputActive then
        love.graphics.setColor(0.2, 0.6, 1.0)
    else
        love.graphics.setColor(0.8, 0.8, 0.8)
    end
    love.graphics.rectangle("line", inputX, cy, inputW, 46, 23)
    
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.setFont(self.font)
    local drawText = self.query
    if self.query == "" and not self.inputActive then
        love.graphics.setColor(0.6, 0.6, 0.6)
        drawText = "Search Google or type a URL"
    end
    love.graphics.print(drawText, inputX + 24, cy + 15)
    
    if self.inputActive and math.floor(love.timer.getTime() * 2) % 2 == 0 then
        local tw = self.font:getWidth(self.query)
        love.graphics.line(inputX + 24 + tw, cy + 12, inputX + 24 + tw, cy + 34)
    end
    
    cy = cy + 90
    
    local bw, bh = 130, 110
    local spacing = 24
    local cols = math.max(1, math.floor((w - 40) / (bw + spacing)))
    if cols > #self.sites then cols = #self.sites end
    local totalW = (cols * bw) + ((cols - 1) * spacing)
    local startX = x + (w - totalW) / 2
    
    local mx, my = love.mouse.getPosition()
    local adjustedMY = my + self.scroll 
    
    self.ui.sites = {} 
    
    for i, site in ipairs(self.sites) do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local sx = startX + col * (bw + spacing)
        local sy = cy + row * (bh + spacing)
        
        table.insert(self.ui.sites, { x = sx, y = sy, w = bw, h = bh, url = site.url })
        
        local hovered = mx >= sx and mx <= sx + bw and adjustedMY >= sy and adjustedMY <= sy + bh
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", sx, sy, bw, bh, 12)
        
        if hovered then
            love.graphics.setColor(0.2, 0.6, 1.0, 0.5)
            love.graphics.rectangle("line", sx - 1, sy - 1, bw + 2, bh + 2, 12)
        else
            love.graphics.setColor(0.85, 0.85, 0.85)
            love.graphics.rectangle("line", sx, sy, bw, bh, 12)
        end
        
        love.graphics.setColor(site.color)
        love.graphics.circle("fill", sx + bw/2, sy + 40, 26)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(site.name:sub(1,1), sx, sy + 25, bw, "center")
        
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.printf(site.name, sx, sy + 80, bw, "center")
    end
    
    local rows = math.ceil(#self.sites / cols)
    local totalContentHeight = (cy - y) + (rows * (bh + spacing)) + 60
    self.maxScroll = math.max(0, totalContentHeight - h)
    
    love.graphics.pop()
end

function Home:mousepressed(mx, my, button)
    -- Accommodate LÖVE legacy mouse strings
    if button ~= 1 and button ~= "l" then return end
    
    -- Safety check: if the user forces URL bar focus, drop child-focus instantly
    if self.browser.urlActive then 
        self.inputActive = false
        return 
    end
    
    local localY = my + self.scroll
    local ib = self.ui.input
    
    if ib and mx >= ib.x and mx <= ib.x + ib.w and localY >= ib.y and localY <= ib.y + ib.h then
        self.inputActive = true
    else
        self.inputActive = false
        
        for _, siteBounds in ipairs(self.ui.sites) do
            if mx >= siteBounds.x and mx <= siteBounds.x + siteBounds.w and localY >= siteBounds.y and localY <= siteBounds.y + siteBounds.h then
                self.browser:loadURL(siteBounds.url)
                return
            end
        end
    end
end

function Home:keypressed(key)
    if self.inputActive then
        if key == "backspace" then
            local utf8 = require("utf8")
            local bo = utf8.offset(self.query, -1)
            if bo then
                self.query = string.sub(self.query, 1, bo - 1)
            end
        elseif key == "return" and self.query ~= "" then
            self.browser:loadURL("http://google.com/search?q=" .. self.query:gsub("%s", "+"))
        end
    end
end

function Home:textinput(text)
    if self.inputActive then
        self.query = self.query .. text
    end
end

return Home