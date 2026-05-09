-- terminal.lua
local json = require "lib/json"  -- ensure you have a json module
local filesystem = require("filesystem")
local TerminalCommands = require("terminal_commands")

local THEMES = {
    default = {
        background = {0.0, 0.0, 0.0, 1.0},     -- Pure black background
        text       = {0.98, 0.98, 0.98},       -- Almost white text
        prompt     = {0.5, 0.8, 0.5},          -- Soft green prompt
        error      = {1.0, 0.3, 0.3},          -- Bright red error
        success    = {0.4, 0.9, 0.4},          -- Green success
        directory  = {0.6, 0.6, 1.0}           -- Light blue directory
    },
    unix = {
        background = {0.18, 0.02, 0.15, 0.98}, -- Classic Ubuntu Purple
        text       = {0.95, 0.95, 0.95},
        prompt     = {0.52, 0.89, 0.11},       -- Green prompt
        error      = {0.9, 0.2, 0.2},
        success    = {0.2, 0.9, 0.2},
        directory  = {0.3, 0.6, 1.0}
    },
    monokai = {
        background = {0.16, 0.17, 0.15, 0.98},
        text       = {0.97, 0.97, 0.95},
        prompt     = {0.64, 0.89, 0.14},       -- Lime
        error      = {0.97, 0.15, 0.45},       -- Pinkish red
        success    = {0.4, 0.86, 0.9},        -- Cyan
        directory  = {0.68, 0.51, 1.0}         -- Purple
    },
    one_dark = {
        background = {0.16, 0.18, 0.22, 0.98},
        text       = {0.67, 0.72, 0.8},
        prompt     = {0.59, 0.77, 0.45},
        error      = {0.88, 0.4, 0.44},
        success    = {0.37, 0.68, 0.53},
        directory  = {0.38, 0.69, 0.94}
    }
}


local Terminal = {}
Terminal.__index = Terminal

-- Helper functions
local function getPath(node)
    return filesystem.getPath(node)
end

local function generateTree(node, prefix)
    return filesystem.generateTree(node, prefix)
end

local function wrapText(text, width, font)
    local lines = {}
    local currentLine = ""
    local currentWidth = 0

    for i = 1, #text do
        local char = text:sub(i, i)
        local newLine = currentLine .. char
        local newWidth = font:getWidth(newLine)

        if newWidth > width then
            table.insert(lines, currentLine)
            currentLine = char
        else
            currentLine = newLine
        end
    end

    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end

    return lines
end

local function getWrappedLines(self)
    local wrapped = {}
    for i, line in ipairs(self.rawLines) do
        local linesWrapped = wrapText(line, self.wrapWidth, self.font)
        for _, wline in ipairs(linesWrapped) do
            table.insert(wrapped, wline)
        end
    end
    return wrapped
end

-- Terminal Module Methods
function Terminal.new()
    local self = setmetatable({}, Terminal)
    self.rawLines = {}           -- raw (unwrapped) lines
    self.inputBuffer = ""
    self.prompt = "user@lynux:~$ "
    self.font = love.graphics.newFont("font/consola.ttf", 12)
    love.graphics.setFont(self.font)
    self.cursorBlinkTimer = 0
    self.cursorVisible = true
    self.cursorBlinkInterval = 0.5
    self.scrollOffset = 0        -- 0 means bottom (newest lines)
    self.wrapWidth = 400 - 40
    self.autoScroll = true
    self.maxVisibleLines = math.floor((300 - 20) / self.font:getHeight()) - 2
    self.windowWidth, self.windowHeight = 0, 0
    self.title = "Terminal"
    self.colors = THEMES.default
    self.history = {}
    self.historyIndex = 0
    self.commandStartTime = 0
    self.scrollBarDragging = false
    self.scrollBarDragStartY = 0
    self.scrollBarDragStartOffset = 0
    
    table.insert(self.rawLines, "+- Lynux Terminal v2.0 --------------+")
    table.insert(self.rawLines, "| Type 'help' for available commands |")
    table.insert(self.rawLines, "+------------------------------------+")
    table.insert(self.rawLines, "")
    
    -- Use the shared file system.
    self.filesystem = filesystem.getFS()
    self.cwd = self.filesystem
    
    -- Load theme if exists
    self:loadTheme()
    
    return self
end

function Terminal:update(dt)
    self.cursorBlinkTimer = self.cursorBlinkTimer + dt
    if self.cursorBlinkTimer >= self.cursorBlinkInterval then
        self.cursorBlinkTimer = self.cursorBlinkTimer - self.cursorBlinkInterval
        self.cursorVisible = not self.cursorVisible
    end
end

function Terminal:draw(x, y, width, height)
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = x, y, width, height
    love.graphics.push()
    love.graphics.translate(x, y)
    
    -- Draw terminal background/header
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setFont(self.font)
    
    local wrapped = getWrappedLines(self)
    local totalWrapped = #wrapped
    local visibleLines = self.maxVisibleLines
    local maxScroll = math.max(0, totalWrapped - visibleLines) -- maxScroll = how many "lines up" you can go
    
    -- Auto-adjust scroll offset if content changed
    if self.autoScroll then
        self.scrollOffset = 0  -- 0 means bottom (newest lines)
    else
        -- clamp between 0 (bottom) and maxScroll (top)
        self.scrollOffset = math.max(0, math.min(self.scrollOffset, maxScroll))
    end

    -- Determine range to draw: bottom-aligned with scrollOffset
    -- startIndex should be the (totalWrapped - visibleLines + 1) - scrollOffset (clamped)
    local startIndex = math.max(1, (totalWrapped - visibleLines + 1) - self.scrollOffset)
    local endIndex = math.min(totalWrapped, startIndex + visibleLines - 1)
    
    -- Draw terminal content area
    local contentY = 5
    local contentHeight = height - contentY - 25
    
    local yPos = contentY
    for i = startIndex, endIndex do
        local line = wrapped[i]
        
        if line ~= nil then
            -- color logic (unchanged)
            if line:find("error") or line:find("Error") or line:find("not found") then
                love.graphics.setColor(self.colors.error)
            elseif line:find("success") or line:find("Success") or line:find("created") then
                love.graphics.setColor(self.colors.success)
            elseif line:match("%$ [^ ]+") then
                love.graphics.setColor(self.colors.prompt)
            elseif line:match("/$") or line:match("Directory") then
                love.graphics.setColor(self.colors.directory)
            else
                love.graphics.setColor(self.colors.text)
            end
            
            love.graphics.print(line, 10, yPos)
            yPos = yPos + self.font:getHeight()
        end
    end

    -- Draw input line (always after the visible lines)
    local inputY = contentY + (endIndex - startIndex + 1) * self.font:getHeight()
    local inputDisplay = self.prompt .. self.inputBuffer
    
    love.graphics.setColor(self.colors.prompt)
    love.graphics.print(self.prompt, 10, inputY)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(self.inputBuffer, 10 + self.font:getWidth(self.prompt), inputY)
    if self.cursorVisible then
        local cursorX = 10 + self.font:getWidth(inputDisplay)
        love.graphics.setColor(self.colors.text)
        love.graphics.rectangle("fill", cursorX, inputY, 8, self.font:getHeight())
    end

    -- Draw professional scrollbar if needed
    if totalWrapped > visibleLines then
        local scrollbarWidth = 6
        local scrollbarPadding = 4
        local scrollbarX = width - scrollbarWidth - scrollbarPadding
        local scrollbarHeight = height - 10
        local contentY = 5
        
        -- Subtle track
        love.graphics.setColor(0.5, 0.5, 0.5, 0.1)
        love.graphics.rectangle("fill", scrollbarX, contentY, scrollbarWidth, scrollbarHeight, 3, 3)

        local thumbHeight = math.max(30, (visibleLines / totalWrapped) * scrollbarHeight)
        local maxThumbTravel = scrollbarHeight - thumbHeight

        -- thumb position: scrollOffset=0 -> thumb at bottom; scrollOffset=maxScroll -> thumb at top
        local thumbY
        if maxScroll <= 0 then
            thumbY = contentY + maxThumbTravel
        else
            thumbY = contentY + ((maxScroll - self.scrollOffset) / maxScroll) * maxThumbTravel
        end

        -- Professional thumb color
        if self.scrollBarDragging then
            love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
        else
            -- Check for hover
            local mx, my = love.mouse.getPosition()
            local relX, relY = mx - self.windowX, my - self.windowY
            if relX >= scrollbarX - 2 and relX <= scrollbarX + scrollbarWidth + 2 and
               relY >= thumbY and relY <= thumbY + thumbHeight then
                love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
            else
                love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
            end
        end
        
        love.graphics.rectangle("fill", scrollbarX, thumbY, scrollbarWidth, thumbHeight, 3, 3)
    end

    love.graphics.pop()
end



function Terminal:textinput(text)
    self.inputBuffer = self.inputBuffer .. text
end

function Terminal:keypressed(key)
    local wrapped = getWrappedLines(self)
    local totalWrapped = #wrapped
    local visibleLines = self.maxVisibleLines
    local maxScroll = math.max(0, totalWrapped - visibleLines)
    
    if key == "backspace" then
        self.inputBuffer = self.inputBuffer:sub(1, -2)
    elseif key == "return" then
        if #self.inputBuffer > 0 then
            table.insert(self.history, self.inputBuffer)
            self.historyIndex = #self.history + 1
        end
        self:processCommand(self.inputBuffer)
        self.inputBuffer = ""
        self.autoScroll = true
    elseif key == "up" then
        if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
            -- Command history
            if #self.history > 0 then
                if self.historyIndex > 1 then
                    self.historyIndex = self.historyIndex - 1
                end
                self.inputBuffer = self.history[self.historyIndex] or ""
            else
                -- Scroll up without Ctrl when no history
                self.scrollOffset = math.min(self.scrollOffset + 1, maxScroll)
                self.autoScroll = false
            end
        else
            -- Scroll up with Ctrl (move towards older content)
            self.scrollOffset = math.min(self.scrollOffset + 1, maxScroll)
            self.autoScroll = false
        end
    elseif key == "down" then
        if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
            -- Command history
            if #self.history > 0 then
                if self.historyIndex < #self.history then
                    self.historyIndex = self.historyIndex + 1
                    self.inputBuffer = self.history[self.historyIndex] or ""
                else
                    self.historyIndex = #self.history + 1
                    self.inputBuffer = ""
                end
            else
                -- Scroll down without Ctrl when no history
                self.scrollOffset = math.max(self.scrollOffset - 1, 0)
                self.autoScroll = (self.scrollOffset == 0)
            end		
        else
            -- Scroll down with Ctrl (move towards newer content)
            self.scrollOffset = math.max(self.scrollOffset - 1, 0)
            self.autoScroll = (self.scrollOffset == 0)
        end
    elseif key == "pageup" then
        self.scrollOffset = math.min(self.scrollOffset + visibleLines, maxScroll)
        self.autoScroll = false
    elseif key == "pagedown" then
        self.scrollOffset = math.max(self.scrollOffset - visibleLines, 0)
        self.autoScroll = (self.scrollOffset == 0)
    elseif key == "home" then
        self.scrollOffset = maxScroll  -- Top of content
        self.autoScroll = false
    elseif key == "end" then
        self.scrollOffset = 0  -- Bottom of content
        self.autoScroll = true
    elseif key == "tab" then
        -- TODO: Implement tab completion
    end
end

function Terminal:wheelmoved(x, y)
    local wrapped = getWrappedLines(self)
    local totalWrapped = #wrapped
    local visibleLines = self.maxVisibleLines
    local maxScroll = math.max(0, totalWrapped - visibleLines)
    
    if y > 0 then
        -- Scroll up (towards older content)
        self.scrollOffset = math.min(self.scrollOffset + 3, maxScroll)
        self.autoScroll = false
    elseif y < 0 then
        -- Scroll down (towards newer content)
        self.scrollOffset = math.max(self.scrollOffset - 3, 0)
        self.autoScroll = (self.scrollOffset == 0)
    end
end

function Terminal:mousepressed(mx, my, button, wx, wy)
    if button == 1 then
        -- Convert to window-relative coordinates
        local relX, relY = mx, my
        
        -- Check if click is on scrollbar
        local wrapped = getWrappedLines(self)
        local totalWrapped = #wrapped
        local visibleLines = self.maxVisibleLines
        
        if totalWrapped > visibleLines then
            local scrollbarWidth = 10
            local scrollbarX = self.windowWidth - scrollbarWidth - 4
            local contentY = 5
            local contentHeight = self.windowHeight - 10
            
            local thumbHeight = math.max(30, (visibleLines / totalWrapped) * contentHeight)
            local maxThumbTravel = contentHeight - thumbHeight
            local maxScroll = math.max(0, totalWrapped - visibleLines)
            
            -- thumb position: scrollOffset=0 -> thumb at bottom; scrollOffset=maxScroll -> thumb at top
            local thumbY
            if maxScroll <= 0 then
                thumbY = contentY + maxThumbTravel
            else
                thumbY = contentY + ((maxScroll - self.scrollOffset) / maxScroll) * maxThumbTravel
            end
            
            if relX >= scrollbarX - 10 and relX <= self.windowWidth and
               relY >= contentY and relY <= contentY + contentHeight then
                
                self.scrollBarDragging = true
                self.autoScroll = false
                
                -- If clicking on the thumb, start dragging from that relative point
                if relY >= thumbY and relY <= thumbY + thumbHeight then
                    self.scrollBarDragStartY = relY
                    self.scrollBarDragStartOffset = self.scrollOffset
                else
                    -- Clicking on the track: jump to that position
                    local clickRatio = 1 - ((relY - contentY - thumbHeight/2) / maxThumbTravel)
                    self.scrollOffset = math.floor(math.max(0, math.min(clickRatio * maxScroll, maxScroll)))
                    self.scrollBarDragStartY = relY
                    self.scrollBarDragStartOffset = self.scrollOffset
                end
                
                return true
            end
        end
    end
    return false
end

function Terminal:mousemoved(mx, my, dx, dy, wx, wy)
    if self.scrollBarDragging then
        local relY = my
        
        local wrapped = getWrappedLines(self)
        local totalWrapped = #wrapped
        local visibleLines = self.maxVisibleLines
        local maxScroll = math.max(0, totalWrapped - visibleLines)
        
        local contentY = 5
        local contentHeight = self.windowHeight - 10
        local thumbHeight = math.max(30, (visibleLines / totalWrapped) * contentHeight)
        local maxThumbTravel = contentHeight - thumbHeight
        
        if maxThumbTravel > 0 then
            local deltaY = relY - self.scrollBarDragStartY
            local scrollDelta = (deltaY / maxThumbTravel) * maxScroll
            
            -- Dragging down (positive deltaY) should move thumb down, which means scrollOffset DECREASES (towards 0/bottom)
            self.scrollOffset = math.max(0, math.min(
                self.scrollBarDragStartOffset - scrollDelta,
                maxScroll
            ))
        end
        self.autoScroll = (self.scrollOffset <= 0)
    end
end

-- function Terminal:mousemoved(mx, my)
    -- if self.scrollBarDragging then
        -- local relY = my - (self.windowY or 0)
        -- local wrapped = getWrappedLines(self)
        -- local totalWrapped = #wrapped
        -- local maxScroll = math.max(0, totalWrapped - self.maxVisibleLines)
        
        -- local contentHeight = self.windowHeight - 10
        -- local thumbHeight = math.max(30, (self.maxVisibleLines / totalWrapped) * contentHeight)
        -- local maxThumbTravel = contentHeight - thumbHeight
        
        -- if maxThumbTravel > 0 then
            -- local deltaY = relY - self.scrollBarDragStartY
            -- -- Calculate new offset: dragging DOWN (positive delta) 
            -- -- should DECREASE scrollOffset to move toward newest lines (0).
            -- local scrollChange = (deltaY / maxThumbTravel) * maxScroll
            -- self.scrollOffset = math.max(0, math.min(maxScroll, self.scrollBarDragStartOffset - scrollChange))
        -- end
        -- self.autoScroll = (self.scrollOffset <= 0)
    -- end
-- end

function Terminal:mousereleased(mx, my, button, wx, wy)
    if button == 1 then
        self.scrollBarDragging = false
    end
    return false
end

function Terminal:resize(width, height)
    self.wrapWidth = width - 40
    self.maxVisibleLines = math.floor((height - 30) / self.font:getHeight())
    self.windowWidth = width
    self.windowHeight = height
end

-- Delegate command processing to terminal_commands.lua
function Terminal:processCommand(command)
    table.insert(self.rawLines, self.prompt .. command)
    self.commandStartTime = love.timer.getTime()
    TerminalCommands.process(self, command)
end

function Terminal:applyTheme(name)
    if THEMES[name] then
        self.colors = THEMES[name]
        self:saveTheme()
        return true
    end
    return false
end

function Terminal:print(str)
    -- Split the string by newline characters
    for line in str:gmatch("([^\n]+)") do
        local wrappedLines = wrapText(line, self.wrapWidth, self.font)
        for _, wline in ipairs(wrappedLines) do
            table.insert(self.rawLines, wline)
        end
    end
    if self.autoScroll then
        self.scrollOffset = 0  -- Auto-scroll to bottom
    end
end

function Terminal:setTitle(title)
    self.title = title or "Terminal"
end

function Terminal:setColors(colors)
    if colors.background then self.colors.background = colors.background end
    if colors.text then self.colors.text = colors.text end
    if colors.prompt then self.colors.prompt = colors.prompt end
    if colors.error then self.colors.error = colors.error end
    if colors.success then self.colors.success = colors.success end
    if colors.directory then self.colors.directory = colors.directory end
    if colors.file then self.colors.file = colors.file end
    
    self:saveTheme()
end

function Terminal:saveTheme()
    local theme = {
        colors = self.colors,
        title = self.title
    }
    local data = json.encode(theme)
    love.filesystem.write("terminal_theme.json", data)
end

function Terminal:loadTheme()
    if love.filesystem.getInfo("terminal_theme.json") then
        local data = love.filesystem.read("terminal_theme.json")
        local theme = json.decode(data)
        if theme then
            if theme.colors then
                self.colors = theme.colors
            end
            if theme.title then
                self.title = theme.title
            end
        end
    end
end

function Terminal:getCommandHistory()
    return self.history
end

function Terminal:clearHistory()
    self.history = {}
    self.historyIndex = 0
end

return Terminal