local Home = {}
Home.__index = Home

function Home.new(browser)
    local self = setmetatable({}, Home)
    self.browser = browser
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.titleFont = love.graphics.newFont("font/Nunito-Regular.ttf", 32) or love.graphics.newFont(32)
    self.query = ""
    self.inputActive = true
    self.sites = {
        {name="Google", url="http://google.com", color={0.2, 0.5, 0.9}},
        {name="Bing", url="http://bing.com", color={0.1, 0.6, 0.6}},
        {name="Twitter", url="http://twitter.com", color={0.1, 0.6, 0.9}},
        {name="Reddit", url="http://reddit.com", color={1, 0.3, 0}},
        {name="4CHAN", url="http://4chan.org", color={0.1, 0.4, 0.2}},
        {name="News", url="http://news.com", color={0.7, 0.1, 0.1}},
    }
    return self
end

function Home:draw(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    love.graphics.setColor(0.98, 0.98, 0.98)
    love.graphics.rectangle("fill", x, y, w, h)
    
    local cy = y + h * 0.2
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Welcome to Browser", x, cy, w, "center")
    
    cy = cy + 60
    
    -- Search Input
    local inputW = 500
    local inputX = x + (w - inputW) / 2
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", inputX, cy, inputW, 40, 20)
    
    if self.inputActive then
        love.graphics.setColor(0.1, 0.5, 0.9)
    else
        love.graphics.setColor(0.8, 0.8, 0.8)
    end
    love.graphics.rectangle("line", inputX, cy, inputW, 40, 20)
    
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.setFont(self.font)
    local drawText = self.query
    if self.query == "" and not self.inputActive then
        love.graphics.setColor(0.6, 0.6, 0.6)
        drawText = "Search Google or type a URL"
    end
    love.graphics.print(drawText, inputX + 20, cy + 12)
    
    if self.inputActive and math.floor(love.timer.getTime() * 2) % 2 == 0 then
        local tw = self.font:getWidth(self.query)
        love.graphics.line(inputX + 20 + tw, cy + 10, inputX + 20 + tw, cy + 30)
    end
    
    cy = cy + 80
    
    -- Top sites
    local bw, bh = 120, 100
    local spacing = 20
    local cols = math.max(1, math.floor((w - 40) / (bw + spacing)))
    if cols > #self.sites then cols = #self.sites end
    local totalW = (cols * bw) + ((cols - 1) * spacing)
    local startX = x + (w - totalW) / 2
    
    for i, site in ipairs(self.sites) do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local sx = startX + col * (bw + spacing)
        local sy = cy + row * (bh + spacing)
        
        local mx, my = love.mouse.getPosition()
        local hovered = mx >= sx and mx <= sx+bw and my >= sy and my <= sy+bh
        
        love.graphics.setColor(1, 1, 1)
        if hovered then love.graphics.setColor(0.9, 0.9, 0.9) end
        love.graphics.rectangle("fill", sx, sy, bw, bh, 10)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", sx, sy, bw, bh, 10)
        
        -- Circle icon
        love.graphics.setColor(site.color)
        love.graphics.circle("fill", sx + bw/2, sy + 40, 25)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(site.name:sub(1,1), sx, sy + 25, bw, "center")
        
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.printf(site.name, sx, sy + 75, bw, "center")
    end
end

function Home:mousepressed(mx, my, button)
    local w = self.w
    local inputW = 500
    local inputX = self.x + (w - inputW) / 2
    local cy = self.y + self.h * 0.2 + 60
    
    if mx >= inputX and mx <= inputX + inputW and my >= cy and my <= cy + 40 then
        self.inputActive = true
    else
        self.inputActive = false
        
        -- Check sites
        local bw, bh = 120, 100
        local spacing = 20
        local cols = math.max(1, math.floor((w - 40) / (bw + spacing)))
        if cols > #self.sites then cols = #self.sites end
        local totalW = (cols * bw) + ((cols - 1) * spacing)
        local startX = self.x + (w - totalW) / 2
        local sitesY = cy + 80
        
        for i, site in ipairs(self.sites) do
            local row = math.floor((i - 1) / cols)
            local col = (i - 1) % cols
            local sx = startX + col * (bw + spacing)
            local sy = sitesY + row * (bh + spacing)
            
            if mx >= sx and mx <= sx+bw and my >= sy and my <= sy+bh then
                self.browser:loadURL(site.url)
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
                self.query = self.query:sub(1, bo - 1)
            end
        elseif key == "return" then
            if self.query ~= "" then
                self.browser:loadURL("http://google.com/search?q=" .. self.query)
            end
        end
    end
end

function Home:textinput(text)
    if self.inputActive then
        self.query = self.query .. text
    end
end

return Home
