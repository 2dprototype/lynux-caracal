local FourChan = {}
FourChan.__index = FourChan

function FourChan.new(browser)
    local self = setmetatable({}, FourChan)
    self.browser = browser
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 12) or love.graphics.newFont(12)
    self.titleFont = love.graphics.newFont("font/Nunito-Regular.ttf", 16) or love.graphics.newFont(16)
    
    self.posts = {
        {id=123456, name="Anonymous", time="04/28/26(Tue)09:12:05", content=">be me\n>making a desktop simulator in lua\n>it actually works\nfeelsgoodman.jpg"},
        {id=123457, name="Anonymous", time="04/28/26(Tue)09:15:22", content=">>123456\nBased and lua-pilled."},
        {id=123458, name="Anonymous", time="04/28/26(Tue)09:20:01", content=">using love2d\n>not writing your own rendering engine in raw C\nngmi"},
        {id=123459, name="Anonymous", time="04/28/26(Tue)09:25:33", content=">>123458\nShut up nerd, at least he ships games."},
    }
    
    self.scroll = 0
    return self
end

function FourChan:draw(x, y, w, h)
    love.graphics.setColor(1, 1, 0.88) -- Yotsuba B background
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Banner
    love.graphics.setColor(0.5, 0, 0)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("/g/ - Technology", x, y + 20, w, "center")
    
    local contentY = y + 60
    local contentH = h - 60
    love.graphics.setScissor(x, contentY, w, contentH)
    
    local cy = contentY - self.scroll
    
    for i, p in ipairs(self.posts) do
        -- Draw post
        local px = x + 20
        if i > 1 then
            px = px + 40 -- Indent replies
            love.graphics.setColor(0.85, 0.8, 0.75) -- Reply bg
            love.graphics.rectangle("fill", px, cy, w - 80, 80)
            love.graphics.setColor(0.7, 0.6, 0.6)
            love.graphics.rectangle("line", px, cy, w - 80, 80)
        end
        
        love.graphics.setFont(self.font)
        
        -- Header (Name, Time, No.)
        love.graphics.setColor(0.06, 0.46, 0.24) -- Green name
        love.graphics.print(p.name, px + 10, cy + 10)
        
        local nameW = self.font:getWidth(p.name)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(p.time, px + 10 + nameW + 10, cy + 10)
        
        local timeW = self.font:getWidth(p.time)
        love.graphics.setColor(0.5, 0, 0)
        love.graphics.print("No." .. p.id, px + 10 + nameW + 10 + timeW + 10, cy + 10)
        
        -- Content
        local textY = cy + 30
        for line in p.content:gmatch("([^\n]+)") do
            if line:sub(1,1) == ">" and line:sub(1,2) ~= ">>" then
                love.graphics.setColor(0.47, 0.6, 0.13) -- Greentext
            elseif line:sub(1,2) == ">>" then
                love.graphics.setColor(0.8, 0.1, 0.1) -- Reply link
            else
                love.graphics.setColor(0, 0, 0)
            end
            love.graphics.print(line, px + 20, textY)
            textY = textY + 15
        end
        
        cy = cy + 90
    end
    
    love.graphics.setScissor()
end

function FourChan:wheelmoved(wx, wy)
    self.scroll = math.max(0, self.scroll - wy * 40)
end

return FourChan
