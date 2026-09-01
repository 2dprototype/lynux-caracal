-- dlc/calculator/calculator.lua
-- Modern Desktop Calculator App with keyboard input, full math operations, and display tape

local Calculator = {}
Calculator.__index = Calculator

function Calculator.new()
    local self = setmetatable({}, Calculator)
    self.display = "0"
    self.prevValue = nil
    self.operation = nil
    self.resetOnNextInput = false
    self.history = ""
    self.font = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 22) or love.graphics.newFont(22)
    self.smallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 12) or love.graphics.newFont(12)
    self.btnFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 15) or love.graphics.newFont(15)

    -- Button grid definition
    self.buttons = {
        { "C", "±", "%", "÷" },
        { "7", "8", "9", "×" },
        { "4", "5", "6", "-" },
        { "1", "2", "3", "+" },
        { "0", ".", "DEL", "=" }
    }
    return self
end

function Calculator:inputDigit(digit)
    if self.resetOnNextInput or self.display == "0" or self.display == "Error" then
        self.display = digit
        self.resetOnNextInput = false
    else
        if #self.display < 14 then
            self.display = self.display .. digit
        end
    end
end

function Calculator:inputDot()
    if self.resetOnNextInput then
        self.display = "0."
        self.resetOnNextInput = false
    elseif not self.display:find("%.") then
        self.display = self.display .. "."
    end
end

function Calculator:setOperator(op)
    local cur = tonumber(self.display)
    if not cur then return end

    if self.prevValue and self.operation and not self.resetOnNextInput then
        self:calculate()
    end

    self.prevValue = tonumber(self.display)
    self.operation = op
    self.history = tostring(self.prevValue) .. " " .. op
    self.resetOnNextInput = true
end

function Calculator:calculate()
    if not self.prevValue or not self.operation then return end

    local a = self.prevValue
    local b = tonumber(self.display) or 0
    local result = 0

    if self.operation == "+" then
        result = a + b
    elseif self.operation == "-" then
        result = a - b
    elseif self.operation == "×" or self.operation == "*" then
        result = a * b
    elseif self.operation == "÷" or self.operation == "/" then
        if b == 0 then
            self.display = "Error"
            self.prevValue = nil
            self.operation = nil
            self.history = "Division by zero"
            self.resetOnNextInput = true
            return
        else
            result = a / b
        end
    end

    -- Format result cleanly
    if math.floor(result) == result and math.abs(result) < 1e12 then
        self.display = tostring(math.floor(result))
    else
        self.display = string.format("%.6g", result)
    end

    self.history = tostring(a) .. " " .. self.operation .. " " .. tostring(b) .. " ="
    self.prevValue = nil
    self.operation = nil
    self.resetOnNextInput = true
end

function Calculator:clear()
    self.display = "0"
    self.prevValue = nil
    self.operation = nil
    self.history = ""
    self.resetOnNextInput = false
end

function Calculator:backspace()
    if self.resetOnNextInput or self.display == "Error" then
        self.display = "0"
        self.resetOnNextInput = false
        return
    end
    if #self.display > 1 then
        self.display = self.display:sub(1, -2)
    else
        self.display = "0"
    end
end

function Calculator:pressButton(lbl)
    local AudioManager = require("src.core.audio_manager")
    AudioManager.playSFX("tick", 1.2, 0.4)

    if tonumber(lbl) then
        self:inputDigit(lbl)
    elseif lbl == "." then
        self:inputDot()
    elseif lbl == "C" then
        self:clear()
    elseif lbl == "DEL" then
        self:backspace()
    elseif lbl == "±" then
        local val = tonumber(self.display)
        if val then
            self.display = tostring(-val)
        end
    elseif lbl == "%" then
        local val = tonumber(self.display)
        if val then
            self.display = tostring(val / 100)
        end
    elseif lbl == "=" then
        self:calculate()
    elseif lbl == "+" or lbl == "-" or lbl == "×" or lbl == "÷" then
        self:setOperator(lbl)
    end
end

function Calculator:update(dt)
end

function Calculator:draw(x, y, width, height)
    -- Background
    love.graphics.setColor(0.96, 0.97, 0.98)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Display Screen (Top)
    local screenMargin = 12
    local screenH = 68
    local screenW = width - screenMargin * 2
    local screenX = x + screenMargin
    local screenY = y + 10

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", screenX, screenY, screenW, screenH, 4, 4)
    love.graphics.setColor(0.85, 0.88, 0.92)
    love.graphics.rectangle("line", screenX, screenY, screenW, screenH, 4, 4)

    -- History text
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.5, 0.55, 0.65)
    love.graphics.printf(self.history, screenX + 8, screenY + 8, screenW - 16, "right")

    -- Main result display
    love.graphics.setFont(self.font)
    love.graphics.setColor(0.1, 0.13, 0.2)
    love.graphics.printf(self.display, screenX + 8, screenY + 28, screenW - 16, "right")

    -- Keypad
    local keypadY = screenY + screenH + 12
    local keypadH = height - (keypadY - y) - 12
    local rows = #self.buttons
    local cols = 4
    local btnGap = 6
    local btnW = math.floor((screenW - btnGap * (cols - 1)) / cols)
    local btnH = math.floor((keypadH - btnGap * (rows - 1)) / rows)

    love.graphics.setFont(self.btnFont)

    for r, row in ipairs(self.buttons) do
        for c, lbl in ipairs(row) do
            local bx = screenX + (c - 1) * (btnW + btnGap)
            local by = keypadY + (r - 1) * (btnH + btnGap)

            -- Color themes for button types
            if lbl == "=" then
                love.graphics.setColor(0.12, 0.55, 0.95)
                love.graphics.rectangle("fill", bx, by, btnW, btnH, 4, 4)
                love.graphics.setColor(1, 1, 1)
            elseif lbl == "+" or lbl == "-" or lbl == "×" or lbl == "÷" then
                love.graphics.setColor(0.88, 0.92, 0.98)
                love.graphics.rectangle("fill", bx, by, btnW, btnH, 4, 4)
                love.graphics.setColor(0.15, 0.45, 0.85)
            elseif lbl == "C" or lbl == "DEL" or lbl == "±" or lbl == "%" then
                love.graphics.setColor(0.90, 0.92, 0.95)
                love.graphics.rectangle("fill", bx, by, btnW, btnH, 4, 4)
                love.graphics.setColor(0.3, 0.35, 0.45)
            else
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("fill", bx, by, btnW, btnH, 4, 4)
                love.graphics.setColor(0.86, 0.89, 0.93)
                love.graphics.rectangle("line", bx, by, btnW, btnH, 4, 4)
                love.graphics.setColor(0.12, 0.15, 0.22)
            end

            love.graphics.printf(lbl, bx, by + math.floor((btnH - 18) / 2), btnW, "center")
        end
    end
end

function Calculator:mousepressed(mx, my, button)
    if button ~= 1 then return false end
    -- Check button clicks
    local screenMargin = 12
    local screenH = 68
    local screenW = 340 - screenMargin * 2
    local screenX = screenMargin
    local keypadY = 10 + screenH + 12
    local rows = #self.buttons
    local cols = 4
    local btnGap = 6
    local btnW = math.floor((screenW - btnGap * (cols - 1)) / cols)
    local btnH = math.floor((440 - keypadY - 12 - btnGap * (rows - 1)) / rows)

    for r, row in ipairs(self.buttons) do
        for c, lbl in ipairs(row) do
            local bx = screenX + (c - 1) * (btnW + btnGap)
            local by = keypadY + (r - 1) * (btnH + btnGap)
            if mx >= bx and mx <= bx + btnW and my >= by and my <= by + btnH then
                self:pressButton(lbl)
                return true
            end
        end
    end
    return false
end

function Calculator:keypressed(key)
    if tonumber(key) then
        self:pressButton(key)
        return true
    elseif key == "+" or key == "-" or key == "*" or key == "/" then
        local map = { ["*"] = "×", ["/"] = "÷" }
        self:pressButton(map[key] or key)
        return true
    elseif key == "return" or key == "kpenter" or key == "=" then
        self:pressButton("=")
        return true
    elseif key == "backspace" then
        self:pressButton("DEL")
        return true
    elseif key == "escape" or key == "c" then
        self:pressButton("C")
        return true
    elseif key == "." or key == "kp." then
        self:pressButton(".")
        return true
    end
    return false
end

return Calculator
