local utf8 = require("utf8")
local Bing = {}
Bing.__index = Bing

function Bing.new(browser)
    local self = setmetatable({}, Bing)
    self.browser = browser
    self.font = love.graphics.newFont(16)
    self.logoFont = love.graphics.newFont(48)
    
    self.query = ""
    self.inputActive = false
    self.title = "Microsoft Bing"
    
    return self
end

function Bing:draw(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    
    -- Professional teal/blue gradient background
    love.graphics.setColor(0, 0.5, 0.5)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Sublte background texture (circles)
    love.graphics.setColor(1, 1, 1, 0.05)
    love.graphics.circle("fill", x + w * 0.8, y + h * 0.2, 200)
    love.graphics.circle("fill", x + w * 0.1, y + h * 0.7, 150)
    
    local cy = y + h * 0.3
    
    -- Logo
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.logoFont)
    love.graphics.printf("Microsoft Bing", x, cy, w, "center")
    
    cy = cy + 80
    
    -- Search Box
    local inputW = math.min(600, w - 80)
    local inputX = x + (w - inputW) / 2
    local inputH = 48
    
    self.ui_input = { x = inputX, y = cy, w = inputW, h = inputH }
    
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.rectangle("fill", inputX, cy, inputW, inputH, 24)
    
    local mx, my = love.mouse.getPosition()
    local hovered = mx >= inputX and mx <= inputX + inputW and my >= cy and my <= cy + inputH
    
    if self.inputActive or hovered then
        love.graphics.setColor(0, 0.7, 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", inputX, cy, inputW, inputH, 24)
        love.graphics.setLineWidth(1)
    end
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setFont(self.font)
    local drawText = self.query
    if self.query == "" and not self.inputActive then
        love.graphics.setColor(0.5, 0.5, 0.5)
        drawText = "Ask me anything..."
    end
    love.graphics.print(drawText, inputX + 25, cy + 14)
    
    if self.inputActive and math.floor(love.timer.getTime() * 2) % 2 == 0 then
        local tw = self.font:getWidth(self.query)
        love.graphics.setColor(0, 0.5, 0.5)
        love.graphics.line(inputX + 25 + tw, cy + 12, inputX + 25 + tw, cy + 36)
    end
end

function Bing:mousepressed(mx, my, button)
    if button ~= 1 and button ~= "l" then return end
    
    if self.ui_input and mx >= self.ui_input.x and mx <= self.ui_input.x + self.ui_input.w 
       and my >= self.ui_input.y and my <= self.ui_input.y + self.ui_input.h then
        self.inputActive = true
    else
        self.inputActive = false
    end
end

function Bing:keypressed(key)
    if self.inputActive then
        if key == "backspace" then
            local bo = utf8.offset(self.query, -1)
            if bo then self.query = self.query:sub(1, bo - 1) end
        elseif key == "return" and self.query ~= "" then
            self.browser:loadURL(self.query)
        end
    end
end

function Bing:textinput(text)
    if self.inputActive then
        self.query = self.query .. text
    end
end

return Bing
