local News = {}
News.__index = News

function News.new(browser)
    local self = setmetatable({}, News)
    self.browser = browser
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.titleFont = love.graphics.newFont("font/Nunito-Regular.ttf", 24) or love.graphics.newFont(24)
    self.headlineFont = love.graphics.newFont("font/Nunito-Regular.ttf", 36) or love.graphics.newFont(36)
    
    self.news = {
        {title="Global Markets Surge as Tech Stocks Rally", category="Finance", time="2 hours ago"},
        {title="New Lynux OS Update Changes Everything", category="Technology", time="4 hours ago"},
        {title="Local Developer Builds Entire Ecosystem in Lua", category="Technology", time="5 hours ago"},
        {title="Weather Alert: Heavy Rain Expected This Weekend", category="Local", time="12 hours ago"},
        {title="Sports: City Team Wins Championship Again", category="Sports", time="1 day ago"},
    }
    
    self.scroll = 0
    return self
end

function News:draw(x, y, w, h)
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Header
    love.graphics.setColor(0.7, 0.1, 0.1)
    love.graphics.rectangle("fill", x, y, w, 60)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.headlineFont)
    love.graphics.printf("DAILY NEWS", x, y + 10, w, "center")
    
    local contentY = y + 60
    love.graphics.setScissor(x, contentY, w, h - 60)
    
    local cy = contentY + 30 - self.scroll
    local totalHeight = 30
    
    local colW = math.min(800, w - 40)
    local cx = x + (w - colW)/2
    
    for i, n in ipairs(self.news) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", cx, cy, colW, 100, 5)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", cx, cy, colW, 100, 5)
        
        love.graphics.setColor(0.7, 0.1, 0.1)
        love.graphics.setFont(self.font)
        love.graphics.print(n.category:upper(), cx + 20, cy + 15)
        
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.setFont(self.titleFont)
        love.graphics.printf(n.title, cx + 20, cy + 35, colW - 40, "left")
        
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.setFont(self.font)
        love.graphics.print(n.time, cx + 20, cy + 70)
        
        cy = cy + 120
        totalHeight = totalHeight + 120
    end
    
    self.maxScroll = math.max(0, totalHeight - (h - 60))
    self.scroll = math.max(0, math.min(self.scroll, self.maxScroll))
    
    love.graphics.setScissor()
end

function News:wheelmoved(wx, wy)
    if self.maxScroll then
        self.scroll = math.max(0, math.min(self.maxScroll, self.scroll - wy * 40))
    end
end

return News
