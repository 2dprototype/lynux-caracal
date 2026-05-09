local FourChan = {}
FourChan.__index = FourChan

function FourChan.new(browser)
    local self = setmetatable({}, FourChan)
    self.browser = browser
    self.font = love.graphics.newFont(12)
    self.boldFont = love.graphics.newFont(13)
    self.titleFont = love.graphics.newFont(24)
    
    self.posts = {
        {id=123456, name="Anonymous", time="04/28/26(Tue)09:12:05", content=">be me\n>making a desktop simulator in lua\n>it actually works\nfeelsgoodman.jpg", type="op"},
        {id=123457, name="Anonymous", time="04/28/26(Tue)09:15:22", content=">>123456\nBased and lua-pilled.", type="reply"},
        {id=123458, name="Anonymous", time="04/28/26(Tue)09:20:01", content=">using love2d\n>not writing your own rendering engine in raw C\nngmi", type="reply"},
        {id=123459, name="Anonymous", time="04/28/26(Tue)09:25:33", content=">>123458\nShut up nerd, at least he ships games.", type="reply"},
    }
    
    self.scroll = 0
    self.maxScroll = 0
    self.title = "/g/ - Technology - 4chan"
    return self
end

function FourChan:draw(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    
    -- Yotsuba B light cream theme
    love.graphics.setColor(1, 1, 0.9)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Banner
    love.graphics.setColor(0.5, 0, 0)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("/g/ - Technology", x, y + 20, w, "center")
    
    love.graphics.setScissor(x, y + 60, w, h - 60)
    local cy = y + 70 - self.scroll
    local totalH = 70
    
    for i, p in ipairs(self.posts) do
        local px = x + 20
        local ph = 80
        local pw = w - 60
        
        -- Text wrap calculation
        local wrapW = pw - 40
        local _, lines = self.font:getWrap(p.content, wrapW)
        ph = 40 + (#lines * 16)
        
        if p.type == "reply" then
            px = px + 40
            pw = pw - 40
            love.graphics.setColor(0.85, 0.8, 0.75)
            love.graphics.rectangle("fill", px, cy, pw, ph, 4)
            love.graphics.setColor(0.7, 0.6, 0.6)
            love.graphics.rectangle("line", px, cy, pw, ph, 4)
        end
        
        -- Header
        love.graphics.setFont(self.boldFont)
        love.graphics.setColor(0.06, 0.46, 0.24)
        love.graphics.print(p.name, px + 10, cy + 8)
        
        local nw = self.boldFont:getWidth(p.name)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(self.font)
        love.graphics.print(p.time, px + 15 + nw, cy + 8)
        
        local tw = self.font:getWidth(p.time)
        love.graphics.setColor(0.5, 0, 0)
        love.graphics.print("No." .. p.id, px + 20 + nw + tw, cy + 8)
        
        -- Content
        local lineY = cy + 30
        for line in p.content:gmatch("([^\n]+)") do
            if line:sub(1,1) == ">" and line:sub(1,2) ~= ">>" then
                love.graphics.setColor(0.47, 0.6, 0.13)
            elseif line:sub(1,2) == ">>" then
                love.graphics.setColor(0.8, 0.1, 0.1)
            else
                love.graphics.setColor(0, 0, 0)
            end
            
            -- Simplified wrap for drawing
            local _, wrappedLines = self.font:getWrap(line, wrapW)
            for _, wl in ipairs(wrappedLines) do
                love.graphics.print(wl, px + 15, lineY)
                lineY = lineY + 15
            end
        end
        
        cy = cy + ph + 10
        totalH = totalH + ph + 10
    end
    
    self.maxScroll = math.max(0, totalH - (h - 60))
    love.graphics.setScissor()
end

function FourChan:wheelmoved(wx, wy)
    if self.maxScroll > 0 then
        self.scroll = math.max(0, math.min(self.maxScroll, self.scroll - wy * 40))
    end
end

return FourChan
