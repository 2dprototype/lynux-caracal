local utf8 = require("utf8")
local Bing = {}
Bing.__index = Bing

function Bing.new(browser)
    local self = setmetatable({}, Bing)
    self.browser = browser
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 16) or love.graphics.newFont(16)
    self.logoFont = love.graphics.newFont("font/Nunito-Regular.ttf", 48) or love.graphics.newFont(48)
    
    self.query = ""
    self.inputActive = false
    
    return self
end

function Bing:draw(x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    -- Background Image Mock
    love.graphics.setColor(0.1, 0.6, 0.6)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Gradient overlay
    for i = 0, h, 2 do
        local alpha = i / h
        love.graphics.setColor(0, 0, 0, alpha * 0.8)
        love.graphics.rectangle("fill", x, y + i, w, 2)
    end
    
    local cy = y + h * 0.3
    
    -- Logo
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.logoFont)
    love.graphics.printf("Microsoft Bing", x, cy, w, "center")
    
    cy = cy + 80
    
    -- Search Box
    local inputW = 600
    local inputX = x + (w - inputW) / 2
    
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.rectangle("fill", inputX, cy, inputW, 50, 25)
    
    if self.inputActive then
        love.graphics.setColor(0.2, 0.8, 0.8)
        love.graphics.rectangle("line", inputX, cy, inputW, 50, 25)
    end
    
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setFont(self.font)
    local drawText = self.query
    if self.query == "" and not self.inputActive then
        love.graphics.setColor(0.5, 0.5, 0.5)
        drawText = "Ask me anything..."
    end
    love.graphics.print(drawText, inputX + 25, cy + 15)
    
    if self.inputActive and math.floor(love.timer.getTime() * 2) % 2 == 0 then
        local tw = self.font:getWidth(self.query)
        love.graphics.line(inputX + 25 + tw, cy + 10, inputX + 25 + tw, cy + 40)
    end
end

function Bing:mousepressed(mx, my, button)
    local w = self.w
    local inputW = 600
    local inputX = self.x + (w - inputW) / 2
    local cy = self.y + self.h * 0.3 + 80
    
    if mx >= inputX and mx <= inputX + inputW and my >= cy and my <= cy + 50 then
        self.inputActive = true
    else
        self.inputActive = false
    end
end

function Bing:keypressed(key)
    if self.inputActive then
        if key == "backspace" then
            local bo = utf8.offset(self.query, -1)
            if bo then
                self.query = self.query:sub(1, bo - 1)
            end
        elseif key == "return" then
            if self.query ~= "" then
                self.browser:loadURL("http://google.com/search?q=" .. self.query)
            end
        end
    end
end

function Bing:textinput(text)
    if self.inputActive then
        self.query = self.query .. text
    end
end

return Bing
