-- chat.lua
local utf8 = require("utf8")
local ChatApp = {}
ChatApp.__index = ChatApp

-- Modern color palette for LINE
local colors = {
    background = {0.6, 0.7, 0.8}, -- LINE background color is often light blueish/greyish
    header = {0.02, 0.78, 0.33},     -- LINE Green (#06C755)
    headerText = {1, 1, 1},
    inboxBg = {1, 1, 1},
    inputBg = {0.95, 0.95, 0.95},
    userBubble = {0.5, 0.9, 0.4},    -- Light green bubble for user
    aiBubble = {1, 1, 1},            -- White bubble for friends
    userText = {0.1, 0.1, 0.1},
    aiText = {0.1, 0.1, 0.1},
    border = {0.9, 0.9, 0.9},
    divider = {0.9, 0.9, 0.9},
    timeText = {0.4, 0.4, 0.4}
}

-- Dummy responses
local dummyResponses = {
    "Lol really?", "That's cool!", "I'm busy right now.", "Can we talk later?", 
    "Haha ok", "Sounds good to me.", "Wow!", "I didn't know that.", "Sure!",
    "Let me check on that.", "I'll let you know.", "Thanks!", "No way!", "Agreed."
}

function ChatApp.new()
    local self = setmetatable({}, ChatApp)
    
    self.users = {
        { id = 1, name = "NexusBot", color = {0.2, 0.6, 0.8}, messages = { {text="Hello! I'm NexusBot.", sender="ai", time="10:00"} } },
        { id = 2, name = "Alice", color = {0.9, 0.4, 0.4}, messages = { {text="Hey there!", sender="ai", time="09:15"}, {text="Are we still meeting?", sender="ai", time="09:16"} } },
        { id = 3, name = "Bob", color = {0.3, 0.8, 0.3}, messages = { {text="Send me the files when you can.", sender="ai", time="Yesterday"} } },
        { id = 4, name = "Charlie", color = {0.8, 0.6, 0.2}, messages = { {text="Haha yeah.", sender="ai", time="Tuesday"} } },
        { id = 5, name = "Dave", color = {0.5, 0.5, 0.8}, messages = { {text="Ok.", sender="ai", time="Monday"} } },
        { id = 6, name = "Eve", color = {0.8, 0.3, 0.8}, messages = { {text="Call me!", sender="ai", time="May 1"} } }
    }
    
    self.currentView = "inbox" -- "inbox" or "chat"
    self.activeUserId = nil
    
    self.inputText = ""
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 12) or love.graphics.newFont(12)
    self.titleFont = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.timeFont = love.graphics.newFont("font/Nunito-Regular.ttf", 10) or love.graphics.newFont(10)
    
    self.inboxScroll = 0
    self.inboxMaxScroll = 0
    
    self.chatScroll = 0
    self.chatMaxScroll = 0
    
    self.cursorVisible = true
    self.cursorTimer = 0
    
    -- Bot typing simulator
    self.typingTimer = 0
    self.isTyping = false
    self.typingUser = nil
    
    return self
end

function ChatApp:update(dt)
    self.cursorTimer = self.cursorTimer + dt
    if self.cursorTimer > 0.5 then
        self.cursorVisible = not self.cursorVisible
        self.cursorTimer = 0
    end
    
    if self.isTyping and self.typingUser then
        self.typingTimer = self.typingTimer - dt
        if self.typingTimer <= 0 then
            self.isTyping = false
            -- Bot sends message
            table.insert(self.typingUser.messages, {
                text = dummyResponses[math.random(#dummyResponses)],
                sender = "ai",
                time = os.date("%H:%M")
            })
            if self.currentView == "chat" and self.activeUserId == self.typingUser.id then
                self:scrollToBottom()
            end
            self.typingUser = nil
        end
    end
    
    if self.windowHeight then
        self:calculateScroll()
    end
end

function ChatApp:calculateScroll()
    if self.currentView == "inbox" then
        local itemHeight = 60
        local totalHeight = #self.users * itemHeight
        local viewHeight = self.windowHeight - 30 -- header
        self.inboxMaxScroll = math.max(0, totalHeight - viewHeight)
        self.inboxScroll = math.max(0, math.min(self.inboxScroll, self.inboxMaxScroll))
    elseif self.currentView == "chat" then
        local user = self:getActiveUser()
        if not user then return end
        
        local totalHeight = 10
        local chatWidth = self.windowWidth
        local maxWidth = chatWidth * 0.7
        
        for _, msg in ipairs(user.messages) do
            local _, wrapped = self.font:getWrap(msg.text, maxWidth - 20)
            local textHeight = #wrapped * self.font:getHeight()
            local bubbleHeight = textHeight + 20
            totalHeight = totalHeight + bubbleHeight + 10
        end
        
        local viewHeight = self.windowHeight - 30 - 50 -- header, input
        self.chatMaxScroll = math.max(0, totalHeight - viewHeight)
        -- Keep bounded
        self.chatScroll = math.max(0, math.min(self.chatScroll, self.chatMaxScroll))
    end
end

function ChatApp:scrollToBottom()
    self:calculateScroll()
    self.chatScroll = self.chatMaxScroll
end

function ChatApp:getActiveUser()
    for _, u in ipairs(self.users) do
        if u.id == self.activeUserId then return u end
    end
    return nil
end

function ChatApp:draw(x, y, width, height)
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = x, y, width, height
    
    if self.currentView == "inbox" then
        self:drawInbox(x, y, width, height)
    else
        self:drawChat(x, y, width, height)
    end
end

function ChatApp:drawInbox(x, y, width, height)
    -- Background
    love.graphics.setColor(colors.inboxBg)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Header
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", x, y, width, 30)
    love.graphics.setColor(colors.headerText)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Chats", x, y + 6, width, "center")
    
    -- Content
    local viewY = y + 30
    local viewHeight = height - 30
    love.graphics.setScissor(x, viewY, width, viewHeight)
    
    local itemHeight = 60
    local currentY = viewY - self.inboxScroll
    
    local mx, my = love.mouse.getPosition()
    
    for i, user in ipairs(self.users) do
        -- Hover effect
        if mx >= x and mx <= x + width and my >= currentY and my < currentY + itemHeight and my >= viewY and my <= viewY + viewHeight then
            love.graphics.setColor(0.96, 0.96, 0.96)
            love.graphics.rectangle("fill", x, currentY, width, itemHeight)
        end
        
        -- Avatar
        love.graphics.setColor(user.color)
        love.graphics.circle("fill", x + 30, currentY + 30, 20)
        
        -- Name
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.setFont(self.titleFont)
        love.graphics.print(user.name, x + 60, currentY + 10)
        
        -- Last Message
        local lastMsg = user.messages[#user.messages]
        if lastMsg then
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.setFont(self.font)
            local txt = lastMsg.text
            if #txt > 30 then txt = txt:sub(1, 27) .. "..." end
            love.graphics.print(txt, x + 60, currentY + 30)
            
            -- Time
            love.graphics.setFont(self.timeFont)
            love.graphics.printf(lastMsg.time, x + width - 60, currentY + 12, 50, "right")
        end
        
        -- Divider
        love.graphics.setColor(colors.divider)
        love.graphics.line(x + 60, currentY + itemHeight - 1, x + width, currentY + itemHeight - 1)
        
        currentY = currentY + itemHeight
    end
    
    love.graphics.setScissor()
    
    -- Scrollbar
    self:drawScrollbar(x, viewY, width, viewHeight, self.inboxScroll, self.inboxMaxScroll)
end

function ChatApp:drawChat(x, y, width, height)
    local user = self:getActiveUser()
    if not user then return end
    
    -- Background
    love.graphics.setColor(colors.background)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Header
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", x, y, width, 30)
    
    -- Back button
    local mx, my = love.mouse.getPosition()
    if mx >= x and mx <= x + 60 and my >= y and my <= y + 30 then
        love.graphics.setColor(0, 0, 0, 0.1)
        love.graphics.rectangle("fill", x, y, 60, 30)
    end
    
    love.graphics.setColor(colors.headerText)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("< Back", x + 10, y + 6)
    
    -- User Name
    love.graphics.printf(user.name, x, y + 6, width, "center")
    
    -- Chat area
    local chatY = y + 30
    local chatHeight = height - 80
    love.graphics.setScissor(x, chatY, width, chatHeight)
    
    local maxWidth = width * 0.7
    local currentY = chatY + 10 - self.chatScroll
    
    for i, msg in ipairs(user.messages) do
        local _, wrapped = self.font:getWrap(msg.text, maxWidth - 20)
        local textHeight = #wrapped * self.font:getHeight()
        local bubbleWidth = 0
        for _, line in ipairs(wrapped) do
            local w = self.font:getWidth(line)
            if w > bubbleWidth then bubbleWidth = w end
        end
        bubbleWidth = bubbleWidth + 20
        local bubbleHeight = textHeight + 20
        
        if currentY + bubbleHeight >= chatY and currentY <= chatY + chatHeight then
            if msg.sender == "ai" then
                -- Avatar
                love.graphics.setColor(user.color)
                love.graphics.circle("fill", x + 25, currentY + 15, 12)
                
                -- Bubble
                love.graphics.setColor(colors.aiBubble)
                love.graphics.rectangle("fill", x + 45, currentY, bubbleWidth, bubbleHeight, 8)
                
                -- Text
                love.graphics.setColor(colors.aiText)
                love.graphics.setFont(self.font)
                love.graphics.printf(msg.text, x + 55, currentY + 10, bubbleWidth - 20, "left")
                
                -- Time
                love.graphics.setColor(colors.timeText)
                love.graphics.setFont(self.timeFont)
                love.graphics.print(msg.time, x + 45 + bubbleWidth + 5, currentY + bubbleHeight - 15)
            else
                -- User bubble
                local bX = x + width - bubbleWidth - 10
                
                -- Bubble
                love.graphics.setColor(colors.userBubble)
                love.graphics.rectangle("fill", bX, currentY, bubbleWidth, bubbleHeight, 8)
                
                -- Text
                love.graphics.setColor(colors.userText)
                love.graphics.setFont(self.font)
                love.graphics.printf(msg.text, bX + 10, currentY + 10, bubbleWidth - 20, "left")
                
                -- Time
                love.graphics.setColor(colors.timeText)
                love.graphics.setFont(self.timeFont)
                local tw = self.timeFont:getWidth(msg.time)
                love.graphics.print(msg.time, bX - tw - 5, currentY + bubbleHeight - 15)
            end
        end
        
        currentY = currentY + bubbleHeight + 10
    end
    
    love.graphics.setScissor()
    self:drawScrollbar(x, chatY, width, chatHeight, self.chatScroll, self.chatMaxScroll)
    
    -- Input Area
    local inputY = y + height - 50
    love.graphics.setColor(colors.inputBg)
    love.graphics.rectangle("fill", x, inputY, width, 50)
    love.graphics.setColor(colors.divider)
    love.graphics.line(x, inputY, x + width, inputY)
    
    -- Input Box
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x + 10, inputY + 10, width - 80, 30, 15)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("line", x + 10, inputY + 10, width - 80, 30, 15)
    
    -- Text
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.setFont(self.font)
    
    local inputX = x + 20
    local inputWidth = width - 100
    love.graphics.setScissor(inputX, inputY + 10, inputWidth, 30)
    love.graphics.print(self.inputText, inputX, inputY + 17)
    
    if self.cursorVisible then
        local cw = self.font:getWidth(self.inputText)
        love.graphics.line(inputX + cw + 2, inputY + 15, inputX + cw + 2, inputY + 25)
    end
    love.graphics.setScissor()
    
    -- Send Button
    local isSendHovered = mx >= x + width - 60 and mx <= x + width - 10 and my >= inputY + 10 and my <= inputY + 40
    if isSendHovered then
        love.graphics.setColor(0.02, 0.68, 0.3)
    else
        love.graphics.setColor(colors.header)
    end
    love.graphics.rectangle("fill", x + width - 60, inputY + 10, 50, 30, 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Send", x + width - 60, inputY + 16, 50, "center")
end

function ChatApp:drawScrollbar(x, y, width, height, scroll, maxScroll)
    if maxScroll > 0 then
        local trackHeight = height
        local visibleRatio = height / (maxScroll + height)
        local thumbHeight = math.max(20, trackHeight * visibleRatio)
        local thumbY = y + (scroll / maxScroll) * (trackHeight - thumbHeight)
        
        love.graphics.setColor(0.8, 0.8, 0.8, 0.5)
        love.graphics.rectangle("fill", x + width - 8, thumbY, 6, thumbHeight, 3)
    end
end

function ChatApp:mousepressed(mx, my, button, wx, wy)
    if button == 1 then
        if self.currentView == "inbox" then
            local viewY = 30
            local viewHeight = self.windowHeight - 30
            if my >= viewY and my <= viewY + viewHeight then
                local relativeY = my - viewY + self.inboxScroll
                local idx = math.floor(relativeY / 60) + 1
                if idx >= 1 and idx <= #self.users then
                    self.activeUserId = self.users[idx].id
                    self.currentView = "chat"
                    self:scrollToBottom()
                end
            end
        elseif self.currentView == "chat" then
            -- Check back button
            if my >= 0 and my <= 30 and mx >= 0 and mx <= 60 then
                self.currentView = "inbox"
                self.activeUserId = nil
            end
            
            -- Check send button
            local inputY = self.windowHeight - 50
            if mx >= self.windowWidth - 60 and mx <= self.windowWidth - 10 and my >= inputY + 10 and my <= inputY + 40 then
                self:sendMessage()
            end
        end
    end
end

function ChatApp:wheelmoved(x, y)
    if self.currentView == "inbox" then
        self.inboxScroll = math.max(0, math.min(self.inboxScroll - y * 40, self.inboxMaxScroll))
    elseif self.currentView == "chat" then
        self.chatScroll = math.max(0, math.min(self.chatScroll - y * 40, self.chatMaxScroll))
    end
end

function ChatApp:textinput(text)
    if self.currentView == "chat" then
        self.inputText = self.inputText .. text
    end
end

function ChatApp:keypressed(key)
    if self.currentView == "chat" then
        if key == "backspace" then
            -- UTF8 robust backspace
            local byteoffset = utf8.offset(self.inputText, -1)
            if byteoffset then
                self.inputText = string.sub(self.inputText, 1, byteoffset - 1)
            end
        elseif key == "return" then
            self:sendMessage()
        end
    end
end

function ChatApp:sendMessage()
    if #self.inputText == 0 then return end
    
    local user = self:getActiveUser()
    if not user then return end
    
    table.insert(user.messages, {
        text = self.inputText,
        sender = "user",
        time = os.date("%H:%M")
    })
    
    self.inputText = ""
    self:scrollToBottom()
    
    -- Bot typing simulator
    if not self.isTyping then
        self.isTyping = true
        self.typingTimer = math.random() * 2 + 1
        self.typingUser = user
    end
end

function ChatApp:resize(w, h)
    if self.windowHeight then
        self:calculateScroll()
    end
end

return ChatApp