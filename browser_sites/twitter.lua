local Twitter = {}
Twitter.__index = Twitter

function Twitter.new(browser)
    local self = setmetatable({}, Twitter)
    self.browser = browser
    self.font = love.graphics.newFont(14)
    self.boldFont = love.graphics.newFont(14)
    self.titleFont = love.graphics.newFont(18)
    
    self.tweets = {
        {name="Elon Musk", handle="@elonmusk", text="Testing the new Lynux Caracal browser. Pretty smooth!", likes="1.2M", rt="400K", time="2h"},
        {name="Lynux Team", handle="@lynuxos", text="We've completely rewritten the browser for better performance and a cleaner look. Let us know what you think!", likes="50K", rt="12K", time="5h"},
        {name="Lua Fan", handle="@luadev", text="Love2D + Lua is the ultimate combo for rapid prototyping. Look at this browser!", likes="420", rt="69", time="12h"},
        {name="Tech News", handle="@technews", text="Rumors say the next update will include multiple tabs support.", likes="15K", rt="3K", time="1d"},
    }
    
    self.scroll = 0
    self.maxScroll = 0
    self.title = "Home / X"
    return self
end

function Twitter:draw(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    
    local colW = math.min(600, w)
    local cx = x + (w - colW)/2
    
    -- Content scrolling
    love.graphics.setScissor(x, y, w, h)
    local cy = y - self.scroll
    
    -- Top Sticky Header (simplified)
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.rectangle("fill", cx, y, colW, 50)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("Home", cx + 20, y + 15)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.line(cx, y + 50, cx + colW, y + 50)
    
    cy = cy + 50
    
    -- Compose Box
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", cx, cy, colW, 110)
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.circle("fill", cx + 30, cy + 30, 20)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setFont(self.font)
    love.graphics.print("What is happening?!", cx + 60, cy + 20)
    
    love.graphics.setColor(0.1, 0.6, 0.9)
    love.graphics.rectangle("fill", cx + colW - 90, cy + 70, 70, 30, 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Post", cx + colW - 90, cy + 77, 70, "center")
    
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.line(cx, cy + 110, cx + colW, cy + 110)
    cy = cy + 110
    
    -- Tweets list
    local totalH = 160
    for i, t in ipairs(self.tweets) do
        local tweetH = 120
        -- Simple text wrapping check (approximate)
        local _, lines = self.font:getWrap(t.text, colW - 100)
        tweetH = 60 + (#lines * 18) + 40
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", cx, cy, colW, tweetH)
        
        -- Avatar
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.circle("fill", cx + 30, cy + 30, 20)
        
        -- Name & Handle
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(self.boldFont)
        love.graphics.print(t.name, cx + 60, cy + 15)
        
        local nw = self.boldFont:getWidth(t.name)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.setFont(self.font)
        love.graphics.print(t.handle .. " · " .. t.time, cx + 60 + nw + 5, cy + 15)
        
        -- Text
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.printf(t.text, cx + 60, cy + 40, colW - 80, "left")
        
        -- Actions
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("C 12    R " .. t.rt .. "    H " .. t.likes .. "    V 10K", cx + 60, cy + tweetH - 30)
        
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.line(cx, cy + tweetH, cx + colW, cy + tweetH)
        
        cy = cy + tweetH
        totalH = totalH + tweetH
    end
    
    self.maxScroll = math.max(0, totalH - h)
    love.graphics.setScissor()
end

function Twitter:wheelmoved(wx, wy)
    if self.maxScroll > 0 then
        self.scroll = math.max(0, math.min(self.maxScroll, self.scroll - wy * 40))
    end
end

return Twitter
