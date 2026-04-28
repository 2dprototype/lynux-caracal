local Reddit = {}
Reddit.__index = Reddit

function Reddit.new(browser)
    local self = setmetatable({}, Reddit)
    self.browser = browser
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.titleFont = love.graphics.newFont("font/Nunito-Regular.ttf", 18) or love.graphics.newFont(18)
    
    self.posts = {
        {id=1, title="TIL that honey never spoils.", author="u/history_fan", sub="r/todayilearned", upvotes=15420, upvoted=false, downvoted=false},
        {id=2, title="What's your unpopular opinion?", author="u/curious", sub="r/askreddit", upvotes=8921, upvoted=false, downvoted=false},
        {id=3, title="My cat learned to open doors", author="u/cat_owner", sub="r/cats", upvotes=7563, upvoted=false, downvoted=false},
        {id=4, title="The new Lynux OS looks amazing!", author="u/devguy", sub="r/linux", upvotes=2340, upvoted=false, downvoted=false},
        {id=5, title="I built a desktop simulator in Love2D", author="u/mahdin", sub="r/gamedev", upvotes=5600, upvoted=false, downvoted=false},
    }
    
    self.scroll = 0
    return self
end

function Reddit:draw(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    love.graphics.setColor(0.85, 0.88, 0.9)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Header
    love.graphics.setColor(1, 0.27, 0)
    love.graphics.rectangle("fill", x, y, w, 50)
    love.graphics.setColor(1, 1, 1)
    local hFont = love.graphics.newFont("font/Nunito-Regular.ttf", 24) or love.graphics.newFont(24)
    love.graphics.setFont(hFont)
    love.graphics.print("reddit", x + 20, y + 10)
    
    local contentY = y + 50
    local contentH = h - 50
    love.graphics.setScissor(x, contentY, w, contentH)
    
    local cy = contentY + 20 - self.scroll
    for i, p in ipairs(self.posts) do
        local pw = math.min(800, w - 40)
        local px = x + (w - pw)/2
        local ph = 100
        
        -- Post bg
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", px, cy, pw, ph, 4)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", px, cy, pw, ph, 4)
        
        -- Vote area
        love.graphics.setColor(0.96, 0.96, 0.96)
        love.graphics.rectangle("fill", px, cy, 40, ph, 4)
        
        -- Upvote
        if p.upvoted then love.graphics.setColor(1, 0.27, 0) else love.graphics.setColor(0.6, 0.6, 0.6) end
        love.graphics.setFont(self.titleFont)
        love.graphics.printf("▲", px, cy + 10, 40, "center")
        
        -- Count
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.setFont(self.font)
        love.graphics.printf(tostring(p.upvotes), px, cy + 40, 40, "center")
        
        -- Downvote
        if p.downvoted then love.graphics.setColor(0.4, 0.4, 1) else love.graphics.setColor(0.6, 0.6, 0.6) end
        love.graphics.setFont(self.titleFont)
        love.graphics.printf("▼", px, cy + 65, 40, "center")
        
        -- Content
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.setFont(self.font)
        love.graphics.print(p.sub .. " • Posted by " .. p.author, px + 50, cy + 15)
        
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.setFont(self.titleFont)
        love.graphics.printf(p.title, px + 50, cy + 40, pw - 60, "left")
        
        cy = cy + ph + 15
    end
    
    love.graphics.setScissor()
end

function Reddit:mousepressed(mx, my, button)
    if button == 1 then
        local w = self.w
        local contentY = self.y + 50
        local cy = contentY + 20 - self.scroll
        for i, p in ipairs(self.posts) do
            local pw = math.min(800, w - 40)
            local px = self.x + (w - pw)/2
            local ph = 100
            
            if mx >= px and mx <= px + 40 then
                if my >= cy + 5 and my <= cy + 30 then
                    if p.upvoted then
                        p.upvoted = false
                        p.upvotes = p.upvotes - 1
                    else
                        p.upvoted = true
                        p.upvotes = p.upvotes + 1
                        if p.downvoted then
                            p.downvoted = false
                            p.upvotes = p.upvotes + 1
                        end
                    end
                elseif my >= cy + 60 and my <= cy + 90 then
                    if p.downvoted then
                        p.downvoted = false
                        p.upvotes = p.upvotes + 1
                    else
                        p.downvoted = true
                        p.upvotes = p.upvotes - 1
                        if p.upvoted then
                            p.upvoted = false
                            p.upvotes = p.upvotes - 1
                        end
                    end
                end
            end
            cy = cy + ph + 15
        end
    end
end

function Reddit:wheelmoved(wx, wy)
    self.scroll = math.max(0, self.scroll - wy * 40)
end

return Reddit
