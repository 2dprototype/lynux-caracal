-- news.lua
local News = {}
News.__index = News

function News.new(browser)
    local self = setmetatable({}, News)
    self.browser = browser
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.titleFont = love.graphics.newFont("font/Nunito-Regular.ttf", 24) or love.graphics.newFont(24)
    self.headlineFont = love.graphics.newFont("font/Nunito-Regular.ttf", 36) or love.graphics.newFont(36)
    
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
    
    return self
end

function News:draw(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    
    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Header
    love.graphics.setColor(0.15, 0.15, 0.17)
    love.graphics.rectangle("fill", x, y, w, 70)
    
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.setFont(self.headlineFont)
    love.graphics.printf("DAILY NEWS", x, y + 15, w, "center")
    
    -- News items
    local cy = y + 80 - self.scroll
    love.graphics.setScissor(x, y + 70, w, h - 70)
    
    local totalHeight = 0
    local colW = math.min(800, w - 80)
    local cx = x + (w - colW) / 2
    
    for _, article in ipairs(self.news) do
        local ah = 120
        
        love.graphics.setColor(0.12, 0.12, 0.14)
        love.graphics.rectangle("fill", cx, cy, colW, ah, 8)
        
        love.graphics.setColor(0.2, 0.2, 0.22)
        love.graphics.rectangle("line", cx, cy, colW, ah, 8)
        
        -- Category badge
        love.graphics.setColor(0.8, 0.2, 0.2)
        love.graphics.rectangle("fill", cx + 15, cy + 15, 80, 24, 12)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.font)
        love.graphics.printf(article.category:upper(), cx + 15, cy + 18, 80, "center")
        
        -- Source and time
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(article.source .. " · " .. article.time, cx + 110, cy + 20)
        
        -- Title
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.setFont(self.titleFont)
        love.graphics.printf(article.title, cx + 15, cy + 50, colW - 30, "left")
        
        cy = cy + ah + 15
        totalHeight = totalHeight + ah + 15
    end
    
    self.maxScroll = math.max(0, totalHeight - (h - 70))
    self.scroll = math.max(0, math.min(self.scroll, self.maxScroll))
    
    love.graphics.setScissor()
end

function News:wheelmoved(wx, wy)
    if self.maxScroll > 0 then
        self.scroll = math.max(0, math.min(self.maxScroll, self.scroll - wy * 50))
    end
end

return News