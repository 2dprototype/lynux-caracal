local Home = {}
Home.__index = Home

function Home.new(browser)
    local self = setmetatable({}, Home)
    self.browser = browser
    self.font = love.graphics.newFont(14)
    self.titleFont = love.graphics.newFont(42)
    self.query = ""
    self.inputActive = true
    
    self.scroll = 0
    self.maxScroll = 0
    
    self.ui = { sites = {} }
    
    self.sites = {
        {name="Google", url="http://google.com", color={0.26, 0.52, 0.96}},
        {name="Bing", url="http://bing.com", color={0, 0.5, 0.5}},
        {name="Twitter", url="http://twitter.com", color={0.11, 0.63, 0.95}},
        {name="Reddit", url="http://reddit.com", color={1, 0.27, 0}},
        {name="4CHAN", url="http://4chan.org", color={0.2, 0.4, 0.2}},
        {name="News", url="http://news.com", color={0.7, 0, 0}},
        {name="Github", url="http://github.com", color={0.15, 0.15, 0.15}},
        {name="YouTube", url="http://youtube.com", color={1, 0, 0}},
        {name="HTML Home", url="http://lynux.home", color={0.4, 0.4, 0.4}},
        {name="Directory", url="http://links.lynux", color={0.2, 0.6, 0.2}},
    }
    
    self.title = "New Tab"
    
    return self
end

function Home:draw(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    
    -- Clean white background
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    
    love.graphics.push()
    love.graphics.setScissor(x, y, w, h)
    
    -- Content area with scroll
    local cy = y + 80 - self.scroll
    
    -- Logo / Title
    love.graphics.setFont(self.titleFont)
    local letters = {"G", "o", "o", "g", "l", "e"}
    local colors = {
        {0.26, 0.52, 0.96}, -- blue
        {0.92, 0.26, 0.21}, -- red
        {0.98, 0.73, 0.02}, -- yellow
        {0.26, 0.52, 0.96}, -- blue
        {0.2, 0.66, 0.33},  -- green
        {0.92, 0.26, 0.21}, -- red
    }
    
    local totalW = 0
    for i, l in ipairs(letters) do totalW = totalW + self.titleFont:getWidth(l) end
    local lx = x + (w - totalW) / 2
    
    for i, l in ipairs(letters) do
        love.graphics.setColor(colors[i])
        love.graphics.print(l, lx, cy)
        lx = lx + self.titleFont:getWidth(l)
    end
    
    cy = cy + 80
    
    -- Search Input
    local inputW = math.min(500, w - 80)
    local inputX = x + (w - inputW) / 2
    local inputH = 44
    self.ui.input = { x = inputX, y = cy, w = inputW, h = inputH }
    
    local mx, my = love.mouse.getPosition()
    local inputHovered = mx >= inputX and mx <= inputX + inputW and my >= cy and my <= cy + inputH
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", inputX, cy, inputW, inputH, 22)
    
    if self.inputActive then
        love.graphics.setColor(0.26, 0.52, 0.96, 0.2)
        love.graphics.rectangle("fill", inputX, cy, inputW, inputH, 22)
        love.graphics.setColor(0.26, 0.52, 0.96)
    else
        love.graphics.setColor(0.85, 0.88, 0.9)
    end
    love.graphics.rectangle("line", inputX, cy, inputW, inputH, 22)
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setFont(self.font)
    local drawText = self.query
    if self.query == "" and not self.inputActive then
        love.graphics.setColor(0.6, 0.6, 0.6)
        drawText = "Search Google or type a URL"
    end
    love.graphics.print(drawText, inputX + 20, cy + 14)
    
    if self.inputActive and math.floor(love.timer.getTime() * 2) % 2 == 0 then
        local tw = self.font:getWidth(self.query)
        love.graphics.setColor(0.26, 0.52, 0.96)
        love.graphics.line(inputX + 20 + tw, cy + 12, inputX + 20 + tw, cy + 32)
    end
    
    cy = cy + 100
    
    -- Shortcuts
    local iconSize = 48
    local itemW = 110
    local itemH = 100
    local spacing = 20
    local cols = math.max(1, math.floor((w - 40) / (itemW + spacing)))
    if cols > #self.sites then cols = #self.sites end
    local rowW = (cols * itemW) + ((cols - 1) * spacing)
    local startX = x + (w - rowW) / 2
    
    self.ui.sites = {}
    
    for i, site in ipairs(self.sites) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local sx = startX + col * (itemW + spacing)
        local sy = cy + row * (itemH + spacing)
        
        table.insert(self.ui.sites, { x = sx, y = sy, w = itemW, h = itemH, url = site.url })
        
        local hovered = mx >= sx and mx <= sx + itemW and my >= sy and my <= sy + itemH
        
        if hovered then
            love.graphics.setColor(0.95, 0.96, 0.98)
            love.graphics.rectangle("fill", sx, sy, itemW, itemH, 12)
        end
        
        -- Icon circle
        love.graphics.setColor(site.color)
        love.graphics.circle("fill", sx + itemW/2, sy + 35, 24)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(site.name:sub(1,1), sx, sy + 23, itemW, "center")
        
        -- Label
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.setFont(self.font)
        love.graphics.printf(site.name, sx, sy + 70, itemW, "center")
    end
    
    local rows = math.ceil(#self.sites / cols)
    local totalContentHeight = (cy - (y - self.scroll)) + (rows * (itemH + spacing)) + 60
    self.maxScroll = math.max(0, totalContentHeight - h)
    
    love.graphics.setScissor()
    love.graphics.pop()
end

function Home:mousepressed(mx, my, button)
    if button ~= 1 and button ~= "l" then return end
    
    -- Inaccurate clicks fix: We use the UI bounds calculated in draw which are already absolute screen space
    if self.ui.input and mx >= self.ui.input.x and mx <= self.ui.input.x + self.ui.input.w 
       and my >= self.ui.input.y and my <= self.ui.input.y + self.ui.input.h then
        self.inputActive = true
    else
        self.inputActive = false
        for _, site in ipairs(self.ui.sites) do
            if mx >= site.x and mx <= site.x + site.w and my >= site.y and my <= site.y + site.h then
                self.browser:loadURL(site.url)
                return
            end
        end
    end
end

function Home:keypressed(key)
    if self.inputActive then
        if key == "backspace" then
            local utf8 = require("utf8")
            local bo = utf8.offset(self.query, -1)
            if bo then self.query = self.query:sub(1, bo - 1) end
        elseif key == "return" and self.query ~= "" then
            self.browser:loadURL(self.query)
        end
    end
end

function Home:textinput(text)
    if self.inputActive then
        self.query = self.query .. text
    end
end

return Home