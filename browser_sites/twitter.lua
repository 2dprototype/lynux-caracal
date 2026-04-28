local Twitter = {}
Twitter.__index = Twitter

function Twitter.new(browser)
    local self = setmetatable({}, Twitter)
    self.browser = browser
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.boldFont = love.graphics.newFont("font/Nunito-Regular.ttf", 16) or love.graphics.newFont(16)
    
    self.tweets = {
        {name="Elon", handle="@elonmusk", text="Just bought another company.", likes="1.2M", rt="400K"},
        {name="LynuxOS", handle="@lynuxos", text="Version 4.5 is out now! Check out the new browser.", likes="50K", rt="12K"},
        {name="DevGuy", handle="@devguy", text="Programming in Lua is actually so much fun.", likes="420", rt="69"},
    }
    
    self.scroll = 0
    return self
end

function Twitter:draw(x, y, w, h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    
    local contentY = y
    love.graphics.setScissor(x, contentY, w, h)
    local cy = contentY - self.scroll
    
    local colW = math.min(600, w)
    local cx = x + (w - colW)/2
    
    -- Header
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", cx, cy, colW, 50)
    love.graphics.setColor(0.1, 0.6, 0.9)
    love.graphics.setFont(self.boldFont)
    love.graphics.printf("Home", cx, cy + 15, colW, "center")
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.line(cx, cy+50, cx+colW, cy+50)
    
    cy = cy + 50
    
    -- Compose
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", cx, cy, colW, 100)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.circle("fill", cx + 40, cy + 40, 20)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setFont(self.font)
    love.graphics.print("What's happening?", cx + 80, cy + 30)
    
    love.graphics.setColor(0.1, 0.6, 0.9)
    love.graphics.rectangle("fill", cx + colW - 100, cy + 60, 80, 30, 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Tweet", cx + colW - 100, cy + 66, 80, "center")
    
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.line(cx, cy+100, cx+colW, cy+100)
    
    cy = cy + 100
    
    -- Tweets
    for i, t in ipairs(self.tweets) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", cx, cy, colW, 120)
        
        -- Avatar
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.circle("fill", cx + 40, cy + 30, 20)
        
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.setFont(self.boldFont)
        love.graphics.print(t.name, cx + 70, cy + 15)
        
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.setFont(self.font)
        love.graphics.print(t.handle, cx + 70 + self.boldFont:getWidth(t.name) + 5, cy + 16)
        
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.printf(t.text, cx + 70, cy + 40, colW - 90, "left")
        
        -- Actions
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print("💬 12  🔁 " .. t.rt .. "  ❤️ " .. t.likes, cx + 70, cy + 90)
        
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.line(cx, cy+120, cx+colW, cy+120)
        
        cy = cy + 120
    end
    
    love.graphics.setScissor()
end

function Twitter:wheelmoved(wx, wy)
    self.scroll = math.max(0, self.scroll - wy * 40)
end

return Twitter
