local News = {}
News.__index = News

function News.new(browser)
    local self = setmetatable({}, News)
    self.browser = browser
    self.font = love.graphics.newFont(14)
    self.smallFont = love.graphics.newFont(12)
    self.titleFont = love.graphics.newFont(20)
    self.headerFont = love.graphics.newFont(28)
    
    self.news = {
        {title="Global Markets Surge as Tech Stocks Rally", category="Finance", time="2 hours ago", source="Reuters"},
        {title="New Lynux OS Update Changes Everything", category="Technology", time="4 hours ago", source="TechCrunch"},
        {title="Local Developer Builds Entire Ecosystem in Lua", category="Technology", time="5 hours ago", source="DevDaily"},
        {title="Weather Alert: Heavy Rain Expected This Weekend", category="Local", time="12 hours ago", source="WeatherNet"},
        {title="Sports: City Team Wins Championship Again", category="Sports", time="1 day ago", source="SportsCenter"},
        {title="AI Breakthrough: Machine Learning Model Creates Art", category="Science", time="6 hours ago", source="Nature"},
        {title="Space Tourism Company Announces New Routes", category="Business", time="8 hours ago", source="Bloomberg"},
    }
    
    self.scroll = 0
    self.maxScroll = 0
    self.title = "Top Stories - News"
    
    return self
end

function News:draw(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    
    -- Clean professional light background
    love.graphics.setColor(0.98, 0.98, 0.99)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Header
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, 60)
    love.graphics.setColor(0.8, 0, 0)
    love.graphics.setFont(self.headerFont)
    love.graphics.printf("DAILY NEWS", x, y + 15, w, "center")
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.line(x, y + 60, x + w, y + 60)
    
    -- Content scrolling
    love.graphics.setScissor(x, y + 61, w, h - 61)
    local cy = y + 80 - self.scroll
    local totalH = 80
    
    local colW = math.min(700, w - 60)
    local cx = x + (w - colW) / 2
    
    for _, article in ipairs(self.news) do
        local ah = 110
        
        -- Article Card
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", cx, cy, colW, ah, 8)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.rectangle("line", cx, cy, colW, ah, 8)
        
        -- Category
        love.graphics.setColor(0.8, 0, 0)
        love.graphics.setFont(self.smallFont)
        love.graphics.print(article.category:upper(), cx + 15, cy + 15)
        
        -- Source & Time
        love.graphics.setColor(0.5, 0.5, 0.5)
        local sw = self.smallFont:getWidth(article.category:upper())
        love.graphics.print(" · " .. article.source .. " · " .. article.time, cx + 15 + sw, cy + 15)
        
        -- Title
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.setFont(self.titleFont)
        love.graphics.printf(article.title, cx + 15, cy + 35, colW - 30, "left")
        
        cy = cy + ah + 15
        totalH = totalH + ah + 15
    end
    
    self.maxScroll = math.max(0, totalH - (h - 60))
    love.graphics.setScissor()
end

function News:wheelmoved(wx, wy)
    if self.maxScroll > 0 then
        self.scroll = math.max(0, math.min(self.maxScroll, self.scroll - wy * 40))
    end
end

return News