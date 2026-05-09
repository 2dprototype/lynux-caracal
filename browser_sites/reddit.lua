local Reddit = {}
Reddit.__index = Reddit

function Reddit.new(browser)
    local self = setmetatable({}, Reddit)
    self.browser = browser
    self.font = love.graphics.newFont(14)
    self.titleFont = love.graphics.newFont(16)
    self.logoFont = love.graphics.newFont(24)
    
    self.posts = {
        {id=1, title="TIL that honey never spoils.", author="u/history_fan", sub="r/todayilearned", upvotes=15420, upvoted=false, downvoted=false},
        {id=2, title="What's your unpopular opinion?", author="u/curious", sub="r/askreddit", upvotes=8921, upvoted=false, downvoted=false},
        {id=3, title="My cat learned to open doors", author="u/cat_owner", sub="r/cats", upvotes=7563, upvoted=false, downvoted=false},
        {id=4, title="The new Lynux OS looks amazing!", author="u/devguy", sub="r/linux", upvotes=2340, upvoted=false, downvoted=false},
        {id=5, title="I built a desktop simulator in Love2D", author="u/mahdin", sub="r/gamedev", upvotes=5600, upvoted=false, downvoted=false},
    }
    
    self.scroll = 0
    self.maxScroll = 0
    self.title = "Reddit - Dive into anything"
    self.ui_elements = {}
    return self
end

function Reddit:draw(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    
    -- Professional reddit light gray background
    love.graphics.setColor(0.95, 0.95, 0.96)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Header
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, 48)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.line(x, y + 48, x + w, y + 48)
    
    -- Logo
    love.graphics.setColor(1, 0.27, 0)
    love.graphics.circle("fill", x + 35, y + 24, 14)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.logoFont)
    love.graphics.print("r", x + 30, y + 10)
    
    love.graphics.setColor(1, 0.27, 0)
    love.graphics.setFont(self.logoFont)
    love.graphics.print("reddit", x + 55, y + 10)
    
    -- Content scrolling
    love.graphics.setScissor(x, y + 49, w, h - 49)
    local cy = y + 60 - self.scroll
    local totalH = 60
    
    self.ui_elements = {}
    
    for i, p in ipairs(self.posts) do
        local pw = math.min(700, w - 40)
        local px = x + (w - pw)/2
        local ph = 100
        
        -- Post Box
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", px, cy, pw, ph, 4)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.rectangle("line", px, cy, pw, ph, 4)
        
        -- Vote area
        love.graphics.setColor(0.98, 0.98, 0.98)
        love.graphics.rectangle("fill", px + 1, cy + 1, 40, ph - 2, 4, 0, 4, 0)
        
        -- Upvote
        local upX, upY = px + 10, cy + 10
        if p.upvoted then love.graphics.setColor(1, 0.27, 0) else love.graphics.setColor(0.6, 0.6, 0.6) end
        love.graphics.printf("U", px, cy + 10, 40, "center")
        
        -- Count
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.setFont(self.font)
        love.graphics.printf(tostring(p.upvotes), px, cy + 40, 40, "center")
        
        -- Downvote
        if p.downvoted then love.graphics.setColor(0.4, 0.4, 1) else love.graphics.setColor(0.6, 0.6, 0.6) end
        love.graphics.printf("D", px, cy + 65, 40, "center")
        
        -- Store interaction areas
        table.insert(self.ui_elements, {id=p.id, type="up", x=px, y=cy, w=40, h=35})
        table.insert(self.ui_elements, {id=p.id, type="down", x=px, y=cy+65, w=40, h=35})
        
        -- Content
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.setFont(self.font)
        love.graphics.print(p.sub .. " • Posted by " .. p.author, px + 50, cy + 15)
        
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.setFont(self.titleFont)
        love.graphics.printf(p.title, px + 50, cy + 40, pw - 60, "left")
        
        cy = cy + ph + 15
        totalH = totalH + ph + 15
    end
    
    self.maxScroll = math.max(0, totalH - (h - 49))
    love.graphics.setScissor()
end

function Reddit:mousepressed(mx, my, button)
    if button ~= 1 and button ~= "l" then return end
    
    for _, el in ipairs(self.ui_elements) do
        if mx >= el.x and mx <= el.x + el.w and my >= el.y and my <= el.y + el.h then
            -- Find post
            for _, p in ipairs(self.posts) do
                if p.id == el.id then
                    if el.type == "up" then
                        if p.upvoted then p.upvoted = false; p.upvotes = p.upvotes - 1
                        else p.upvoted = true; p.upvotes = p.upvotes + 1; p.downvoted = false end
                    else
                        if p.downvoted then p.downvoted = false; p.upvotes = p.upvotes + 1
                        else p.downvoted = true; p.upvotes = p.upvotes - 1; p.upvoted = false end
                    end
                    return
                end
            end
        end
    end
end

function Reddit:wheelmoved(wx, wy)
    if self.maxScroll > 0 then
        self.scroll = math.max(0, math.min(self.maxScroll, self.scroll - wy * 40))
    end
end

return Reddit
