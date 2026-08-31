-- chat.lua
local utf8 = require("utf8")
local ChatApp = {}
ChatApp.__index = ChatApp

-- Google Material Design 2018/19 color palette
local colors = {
    background = {0.95, 0.96, 0.97},        -- Google gray background
    header = {1, 1, 1},                     -- White header
    headerText = {0.2, 0.2, 0.2},           -- Dark gray text
    primary = {0.13, 0.59, 0.95},           -- Google Blue (#2196F3)
    primaryDark = {0.09, 0.47, 0.76},       -- Darker blue for hover
    accent = {0.96, 0.27, 0.31},            -- Google Red accent
    inboxBg = {1, 1, 1},
    inputBg = {1, 1, 1},
    userBubble = {0.87, 0.92, 1.0},         -- Light blue for user (Google style)
    aiBubble = {1, 1, 1},                   -- White for others
    userText = {0.13, 0.13, 0.13},
    aiText = {0.13, 0.13, 0.13},
    border = {0.85, 0.85, 0.85},
    divider = {0.9, 0.9, 0.9},
    timeText = {0.6, 0.6, 0.6},
    online = {0.27, 0.8, 0.4},              -- Google Green
    hover = {0.96, 0.96, 0.98},
    searchBg = {0.96, 0.96, 0.97},
    shadow = {0, 0, 0, 0.08},
    scrollbarBg = {0, 0, 0, 0.1},
    scrollbarFg = {0, 0, 0, 0.3}
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
        { id = 1, name = "NexusBot", color = {0.13, 0.59, 0.95}, online = true, messages = { {text="Hello! I'm NexusBot.", sender="ai", time="10:00", seen=true} } },
        { id = 2, name = "Alice", color = {0.96, 0.27, 0.31}, online = true, messages = { {text="Hey there!", sender="ai", time="09:15", seen=true}, {text="Are we still meeting?", sender="ai", time="09:16", seen=false} } },
        { id = 3, name = "Bob", color = {1, 0.61, 0}, online = false, messages = { {text="Send me the files when you can.", sender="ai", time="Yesterday", seen=true} } },
        { id = 4, name = "Charlie", color = {0.47, 0.33, 0.28}, online = false, messages = { {text="Haha yeah.", sender="ai", time="Tuesday", seen=true} } },
        { id = 5, name = "Dave", color = {0.6, 0.27, 0.88}, online = false, messages = { {text="Ok.", sender="ai", time="Monday", seen=true} } },
        { id = 6, name = "Eve", color = {0.0, 0.67, 0.55}, online = true, messages = { {text="Call me!", sender="ai", time="May 1", seen=false} } }
    }
    
    self.currentView = "inbox" -- "inbox" or "chat"
    self.activeUserId = nil
    
    self.inputText = ""
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.titleFont = love.graphics.newFont("font/Nunito-Regular.ttf", 16) or love.graphics.newFont(16)
    self.timeFont = love.graphics.newFont("font/Nunito-Regular.ttf", 11) or love.graphics.newFont(11)
    
    self.inboxScroll = 0
    self.inboxMaxScroll = 0
    
    self.chatScroll = 0
    self.chatMaxScroll = 0
    
    self.cursorVisible = true
    self.cursorTimer = 0
    
    -- Scrollbar dragging
    self.draggingScrollbar = false
    self.draggingInbox = false
    self.scrollDragStart = 0
    self.scrollStartValue = 0
    
    -- Search
    self.searchText = ""
    self.searchActive = false
    
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
            table.insert(self.typingUser.messages, {
                text = dummyResponses[math.random(#dummyResponses)],
                sender = "ai",
                time = os.date("%H:%M"),
                seen = false
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
        local filteredUsers = self:getFilteredUsers()
        local itemHeight = 72
        local totalHeight = #filteredUsers * itemHeight
        local viewHeight = self.windowHeight - 80 -- Reduced from 116 (removed title)
        self.inboxMaxScroll = math.max(0, totalHeight - viewHeight)
        if not self.draggingScrollbar then
            self.inboxScroll = math.max(0, math.min(self.inboxScroll, self.inboxMaxScroll))
        end
    elseif self.currentView == "chat" then
        local user = self:getActiveUser()
        if not user then return end
        
        local totalHeight = 20
        local chatWidth = self.windowWidth
        local maxWidth = chatWidth * 0.7
        
        for _, msg in ipairs(user.messages) do
            local _, wrapped = self.font:getWrap(msg.text, maxWidth - 28)
            local textHeight = #wrapped * self.font:getHeight()
            local bubbleHeight = textHeight + 24
            totalHeight = totalHeight + bubbleHeight + 8
        end
        
        local viewHeight = self.windowHeight - 60 - 70
        self.chatMaxScroll = math.max(0, totalHeight - viewHeight)
        if not self.draggingScrollbar then
            self.chatScroll = math.max(0, math.min(self.chatScroll, self.chatMaxScroll))
        end
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

function ChatApp:getFilteredUsers()
    if self.searchText == "" then
        return self.users
    end
    local filtered = {}
    local searchLower = self.searchText:lower()
    for _, user in ipairs(self.users) do
        if user.name:lower():find(searchLower, 1, true) then
            table.insert(filtered, user)
        end
    end
    return filtered
end

function ChatApp:getUnreadCount(user)
    local unread = 0
    for _, msg in ipairs(user.messages) do
        if msg.sender == "ai" and not msg.seen then
            unread = unread + 1
        end
    end
    return unread
end

function ChatApp:markMessagesSeen(user)
    for _, msg in ipairs(user.messages) do
        if msg.sender == "ai" and not msg.seen then
            msg.seen = true
        end
    end
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
    love.graphics.setColor(colors.background)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Header (just separator line, no title)
    love.graphics.setColor(colors.divider)
    love.graphics.line(x, y + 0, x + width, y + 0)
    
    -- Search Bar (moved up)
    local searchY = y + 16 -- Reduced from 64 to 16
    local searchX = x + 16
    local searchWidth = width - 32
    
    -- Search shadow
    love.graphics.setColor(colors.shadow)
    love.graphics.rectangle("fill", searchX, searchY + 2, searchWidth, 40, 8)
    
    love.graphics.setColor(colors.searchBg)
    love.graphics.rectangle("fill", searchX, searchY, searchWidth, 40, 8)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setFont(self.font)
    
    -- Search icon
    if self.searchText == "" and not self.searchActive then
        love.graphics.printf("Search", searchX + 16, searchY + 12, searchWidth - 32, "left")
    else
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.printf(self.searchText, searchX + 16, searchY + 12, searchWidth - 32, "left")
    end
    
    -- Content (moved up)
    local viewY = y + 68 -- Reduced from 116 to 68
    local viewHeight = height - 68 -- Reduced from 116 to 68
    love.graphics.setScissor(x, viewY, width, viewHeight)
    
    local itemHeight = 72
    local currentY = viewY - self.inboxScroll
    
    local mx, my = love.mouse.getPosition()
    local filteredUsers = self:getFilteredUsers()
    
    for i, user in ipairs(filteredUsers) do
        local itemRect = {x = x, y = currentY, w = width, h = itemHeight}
        
        -- Hover effect
        if mx >= itemRect.x and mx <= itemRect.x + itemRect.w and 
           my >= itemRect.y and my < itemRect.y + itemRect.h and
           my >= viewY and my <= viewY + viewHeight then
            love.graphics.setColor(colors.hover)
            love.graphics.rectangle("fill", itemRect.x, itemRect.y, itemRect.w, itemRect.h)
        end
        
        -- Avatar with Google-style colors
        love.graphics.setColor(user.color)
        love.graphics.circle("fill", x + 40, currentY + 36, 22)
        
        -- Online indicator
        if user.online then
            love.graphics.setColor(colors.online)
            love.graphics.circle("fill", x + 54, currentY + 50, 7)
            love.graphics.setColor(colors.inboxBg)
            love.graphics.circle("fill", x + 54, currentY + 50, 5)
            love.graphics.setColor(colors.online)
            love.graphics.circle("fill", x + 54, currentY + 50, 4)
        end
        
        -- Name
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.setFont(self.titleFont)
        love.graphics.print(user.name, x + 78, currentY + 14)
        
        -- Last Message
        local lastMsg = user.messages[#user.messages]
        if lastMsg then
            local unread = self:getUnreadCount(user)
            if unread > 0 then
                love.graphics.setColor(colors.primary)
                love.graphics.setFont(self.titleFont)
            else
                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.setFont(self.font)
            end
            local txt = lastMsg.text
            if #txt > 35 then txt = txt:sub(1, 32) .. "..." end
            if lastMsg.sender == "user" then txt = "You: " .. txt end
            love.graphics.print(txt, x + 78, currentY + 38)
            
            -- Time
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.setFont(self.timeFont)
            love.graphics.printf(lastMsg.time, x + width - 44, currentY + 16, 40, "right")
            
            -- Unread badge
            if unread > 0 then
                local badgeX = x + width - 28
                love.graphics.setColor(colors.primary)
                love.graphics.circle("fill", badgeX, currentY + 48, 10)
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(self.timeFont)
                love.graphics.printf(tostring(unread), badgeX - 5, currentY + 43, 10, "center")
            end
        end
        
        -- Divider
        love.graphics.setColor(colors.divider)
        love.graphics.line(x + 16, currentY + itemHeight - 1, x + width - 16, currentY + itemHeight - 1)
        
        currentY = currentY + itemHeight
    end
    
    love.graphics.setScissor()
    
    -- Scrollbar
    self:drawScrollbar(x + width - 8, viewY, 4, viewHeight, self.inboxScroll, self.inboxMaxScroll)
end

function ChatApp:drawChat(x, y, width, height)
    local user = self:getActiveUser()
    if not user then return end
    
    self:markMessagesSeen(user)
    
    -- Background
    love.graphics.setColor(colors.background)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Header with shadow
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", x, y, width, 60)
    
    -- Back button (Google style)
    local mx, my = love.mouse.getPosition()
    local backHovered = mx >= x and mx <= x + 56 and my >= y and my <= y + 60
    if backHovered then
        love.graphics.setColor(colors.hover)
        love.graphics.rectangle("fill", x + 8, y + 8, 48, 44, 22)
    end
    
    love.graphics.setColor(colors.primary)
    love.graphics.setFont(self.font)
    love.graphics.print("<", x + 28, y + 22)
    
    -- User Name
    love.graphics.setColor(colors.headerText)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf(user.name, x + 70, y + 16, width - 140, "left")
    
    -- Online status text
    love.graphics.setFont(self.timeFont)
    if user.online then
        love.graphics.setColor(colors.online)
        love.graphics.printf("Active now", x + 70, y + 38, width - 140, "left")
    else
        love.graphics.setColor(colors.timeText)
        love.graphics.printf("Offline", x + 70, y + 38, width - 140, "left")
    end
    
    -- Avatar in header
    love.graphics.setColor(user.color)
    love.graphics.circle("fill", x + width - 40, y + 30, 20)
    
    -- Chat area
    local chatY = y + 60
    local chatHeight = height - 130
    love.graphics.setScissor(x, chatY, width, chatHeight)
    
    local maxWidth = width * 0.7
    local currentY = chatY + 16 - self.chatScroll
    
    for i, msg in ipairs(user.messages) do
        local _, wrapped = self.font:getWrap(msg.text, maxWidth - 32)
        local textHeight = #wrapped * self.font:getHeight()
        local bubbleWidth = 0
        for _, line in ipairs(wrapped) do
            local w = self.font:getWidth(line)
            if w > bubbleWidth then bubbleWidth = w end
        end
        bubbleWidth = math.max(bubbleWidth + 32, 60)
        local bubbleHeight = textHeight + 24
        
        if currentY + bubbleHeight >= chatY and currentY <= chatY + chatHeight then
            if msg.sender == "ai" then
                -- Avatar for AI messages
                love.graphics.setColor(user.color)
                love.graphics.circle("fill", x + 32, currentY + 18, 16)
                
                -- Bubble with shadow
                love.graphics.setColor(colors.shadow)
                love.graphics.rectangle("fill", x + 52 + 2, currentY + 2, bubbleWidth, bubbleHeight, 18)
                love.graphics.setColor(colors.aiBubble)
                love.graphics.rectangle("fill", x + 52, currentY, bubbleWidth, bubbleHeight, 18)
                
                -- Text
                love.graphics.setColor(colors.aiText)
                love.graphics.setFont(self.font)
                love.graphics.printf(msg.text, x + 64, currentY + 12, bubbleWidth - 24, "left")
                
                -- Time
                love.graphics.setColor(colors.timeText)
                love.graphics.setFont(self.timeFont)
                love.graphics.print(msg.time, x + 52 + bubbleWidth + 8, currentY + bubbleHeight - 16)
            else
                -- User bubble (light blue)
                local bX = x + width - bubbleWidth - 16
                
                -- Bubble with shadow
                love.graphics.setColor(colors.shadow)
                love.graphics.rectangle("fill", bX + 2, currentY + 2, bubbleWidth, bubbleHeight, 18)
                love.graphics.setColor(colors.userBubble)
                love.graphics.rectangle("fill", bX, currentY, bubbleWidth, bubbleHeight, 18)
                
                -- Text
                love.graphics.setColor(colors.userText)
                love.graphics.setFont(self.font)
                love.graphics.printf(msg.text, bX + 16, currentY + 12, bubbleWidth - 24, "left")
                
                -- Time and seen indicator
                love.graphics.setColor(colors.timeText)
                love.graphics.setFont(self.timeFont)
                local tw = self.timeFont:getWidth(msg.time)
                love.graphics.print(msg.time, bX - tw - 8, currentY + bubbleHeight - 16)
                
                -- Seen checkmark
                if i == #user.messages and msg.sender == "user" then
                    love.graphics.setColor(colors.primary)
                    love.graphics.print("Vv", bX - tw - 8 - 20, currentY + bubbleHeight - 16)
                end
            end
        end
        
        currentY = currentY + bubbleHeight + 8
    end
    
    -- Typing indicator
    if self.isTyping and self.typingUser == user then
        love.graphics.setColor(colors.shadow)
        love.graphics.rectangle("fill", x + 52 + 2, currentY + 2, 56, 36, 18)
        love.graphics.setColor(colors.aiBubble)
        love.graphics.rectangle("fill", x + 52, currentY, 56, 36, 18)
        love.graphics.setColor(colors.aiText)
        love.graphics.setFont(self.font)
        love.graphics.print("Typing...", x + 64, currentY + 12)
        currentY = currentY + 44
    end
    
    love.graphics.setScissor()
    self:drawScrollbar(x + width - 8, chatY, 4, chatHeight, self.chatScroll, self.chatMaxScroll)
    
    -- Input Area (Google style)
    local inputY = y + height - 70
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", x, inputY, width, 70)
    love.graphics.setColor(colors.divider)
    love.graphics.line(x, inputY, x + width, inputY)
    
    -- Input Box with shadow
    local inputBoxX = x + 16
    local inputBoxW = width - 100
    
    love.graphics.setColor(colors.shadow)
    love.graphics.rectangle("fill", inputBoxX, inputY + 12 + 2, inputBoxW, 44, 22)
    love.graphics.setColor(colors.inputBg)
    love.graphics.rectangle("fill", inputBoxX, inputY + 12, inputBoxW, 44, 22)
    love.graphics.setColor(colors.border)
    love.graphics.rectangle("line", inputBoxX, inputY + 12, inputBoxW, 44, 22)
    
    -- Text
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setFont(self.font)
    
    local inputX = inputBoxX + 16
    love.graphics.setScissor(inputX, inputY + 12, inputBoxW - 24, 44)
    love.graphics.print(self.inputText, inputX, inputY + 24)
    
    if self.cursorVisible then
        local cw = self.font:getWidth(self.inputText)
        love.graphics.line(inputX + cw + 2, inputY + 22, inputX + cw + 2, inputY + 44)
    end
    love.graphics.setScissor()
    
    -- Send Button (Google style)
    local sendHovered = mx >= x + width - 68 and mx <= x + width - 20 and my >= inputY + 14 and my <= inputY + 54
    if sendHovered then
        love.graphics.setColor(colors.primaryDark)
    else
        love.graphics.setColor(colors.primary)
    end
    love.graphics.rectangle("fill", x + width - 68, inputY + 14, 48, 40, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Send", x + width - 68, inputY + 26, 48, "center")
end

function ChatApp:drawScrollbar(scrollX, viewY, thumbWidth, viewHeight, scroll, maxScroll)
    if maxScroll <= 0 then return end
    
    local trackHeight = viewHeight
    local visibleRatio = viewHeight / (maxScroll + viewHeight)
    local thumbHeight = math.max(40, trackHeight * visibleRatio)
    local thumbY = viewY + (scroll / maxScroll) * (trackHeight - thumbHeight)
    
    -- Scrollbar track
    love.graphics.setColor(colors.scrollbarBg)
    love.graphics.rectangle("fill", scrollX, viewY, thumbWidth, trackHeight, 4)
    
    -- Scrollbar thumb
    love.graphics.setColor(colors.scrollbarFg)
    love.graphics.rectangle("fill", scrollX, thumbY, thumbWidth, thumbHeight, 4)
end

function ChatApp:mousepressed(mx, my, button, wx, wy)
    if button == 1 then
        if self.currentView == "inbox" then
            local viewY = 68 -- Updated from 116
            local viewHeight = self.windowHeight - 68 -- Updated from 116
            
            -- Check scrollbar first
            local scrollX = self.windowX + self.windowWidth - 8
            if mx >= scrollX and mx <= scrollX + 4 and my >= viewY and my <= viewY + viewHeight then
                self.draggingScrollbar = true
                self.draggingInbox = true
                self.scrollDragStart = my
                self.scrollStartValue = self.inboxScroll
                return
            end
            
            -- Search bar click
            local searchY = 16 -- Updated from 64
            if my >= searchY and my <= searchY + 40 and mx >= 16 and mx <= self.windowWidth - 16 then
                self.searchActive = true
            else
                self.searchActive = false
            end
            
            -- Inbox items
            if my >= viewY and my <= viewY + viewHeight then
                local relativeY = my - viewY + self.inboxScroll
                local idx = math.floor(relativeY / 72) + 1
                local filteredUsers = self:getFilteredUsers()
                if idx >= 1 and idx <= #filteredUsers then
                    self.activeUserId = filteredUsers[idx].id
                    self.currentView = "chat"
                    self:scrollToBottom()
                end
            end
        elseif self.currentView == "chat" then
            local viewY = 60
            local chatHeight = self.windowHeight - 130
            
            -- Check scrollbar first
            local scrollX = self.windowX + self.windowWidth - 8
            if mx >= scrollX and mx <= scrollX + 4 and my >= viewY and my <= viewY + chatHeight then
                self.draggingScrollbar = true
                self.draggingInbox = false
                self.scrollDragStart = my
                self.scrollStartValue = self.chatScroll
                return
            end
            
            -- Back button
            if my >= 8 and my <= 52 and mx >= 8 and mx <= 56 then
                self.currentView = "inbox"
                self.activeUserId = nil
                self.searchActive = false
                return
            end
            
            -- Send button
            local inputY = self.windowHeight - 70
            if mx >= self.windowWidth - 68 and mx <= self.windowWidth - 20 and 
               my >= inputY + 14 and my <= inputY + 54 then
                self:sendMessage()
                return
            end
        end
    end
end

function ChatApp:mousereleased(mx, my, button)
    if button == 1 then
        self.draggingScrollbar = false
    end
end

function ChatApp:wheelmoved(x, y)
    if self.currentView == "inbox" then
        self.inboxScroll = math.max(0, math.min(self.inboxScroll - y * 30, self.inboxMaxScroll))
    elseif self.currentView == "chat" then
        self.chatScroll = math.max(0, math.min(self.chatScroll - y * 30, self.chatMaxScroll))
    end
end

function ChatApp:mousemoved(mx, my, dx, dy)
    if self.draggingScrollbar then
        local viewHeight = self.currentView == "inbox" and (self.windowHeight - 68) or (self.windowHeight - 130)
        local maxScroll = self.currentView == "inbox" and self.inboxMaxScroll or self.chatMaxScroll
        
        if maxScroll > 0 then
            local trackHeight = viewHeight
            local visibleRatio = viewHeight / (maxScroll + viewHeight)
            local thumbHeight = math.max(40, trackHeight * visibleRatio)
            local scrollRange = trackHeight - thumbHeight
            
            local dragDelta = my - self.scrollDragStart
            local scrollPercent = self.scrollStartValue / maxScroll
            local thumbPosition = scrollPercent * scrollRange
            local newThumbPosition = thumbPosition + dragDelta
            local newScrollPercent = newThumbPosition / scrollRange
            local newScroll = newScrollPercent * maxScroll
            
            if self.draggingInbox then
                self.inboxScroll = math.max(0, math.min(newScroll, maxScroll))
            else
                self.chatScroll = math.max(0, math.min(newScroll, maxScroll))
            end
        end
    end
end

function ChatApp:textinput(text)
    if self.searchActive and self.currentView == "inbox" then
        self.searchText = self.searchText .. text
        self.inboxScroll = 0
    elseif self.currentView == "chat" then
        self.inputText = self.inputText .. text
    end
end

function ChatApp:keypressed(key)
    if self.searchActive and self.currentView == "inbox" then
        if key == "backspace" then
            local byteoffset = utf8.offset(self.searchText, -1)
            if byteoffset then
                self.searchText = string.sub(self.searchText, 1, byteoffset - 1)
            end
        elseif key == "escape" then
            self.searchActive = false
            self.searchText = ""
        end
    elseif self.currentView == "chat" then
        if key == "backspace" then
            local byteoffset = utf8.offset(self.inputText, -1)
            if byteoffset then
                self.inputText = string.sub(self.inputText, 1, byteoffset - 1)
            end
        elseif key == "return" then
            self:sendMessage()
        elseif key == "escape" then
            self.currentView = "inbox"
            self.activeUserId = nil
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
        time = os.date("%H:%M"),
        seen = true
    })
    
    self.inputText = ""
    self:scrollToBottom()
    
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