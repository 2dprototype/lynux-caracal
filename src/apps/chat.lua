-- src/apps/chat.lua
local utf8 = require("utf8")
local PlayerStats = require("src.core.player_stats")
local EventBus = require("src.core.event_bus")
local Notifications = require("src.desktop.notifications")
local AudioManager = require("src.core.audio_manager")

local ChatApp = {}
ChatApp.__index = ChatApp

-- Google Material Design color palette
local colors = {
    background = {0.95, 0.96, 0.97},
    header = {1, 1, 1},
    headerText = {0.2, 0.2, 0.2},
    primary = {0.13, 0.59, 0.95},
    primaryDark = {0.09, 0.47, 0.76},
    disabledBtn = {0.82, 0.84, 0.88},
    accent = {0.96, 0.27, 0.31},
    inboxBg = {1, 1, 1},
    inputBg = {1, 1, 1},
    userBubble = {0.87, 0.92, 1.0},
    aiBubble = {1, 1, 1},
    userText = {0.13, 0.13, 0.13},
    aiText = {0.13, 0.13, 0.13},
    border = {0.85, 0.85, 0.85},
    divider = {0.9, 0.9, 0.9},
    timeText = {0.6, 0.6, 0.6},
    online = {0.27, 0.8, 0.4},
    offline = {0.65, 0.68, 0.72},
    hover = {0.96, 0.96, 0.98},
    searchBg = {0.96, 0.96, 0.97},
    shadow = {0, 0, 0, 0.08},
    scrollbarBg = {0, 0, 0, 0.1},
    scrollbarFg = {0, 0, 0, 0.3}
}

function ChatApp.new()
    local self = setmetatable({}, ChatApp)
    
    self.users = {
        {
            id = 1,
            name = "Suzumia (Vice President)",
            color = {0.94, 0.48, 0.58},
            online = false,
            messages = {
                { text = "Good luck assembling the dual-cover tonight, Aki-kun! Let me know when you check the draft notes.", sender = "ai", time = "10:30", seen = true }
            }
        },
        {
            id = 2,
            name = "Hoshida (Club Member)",
            color = {0.32, 0.72, 0.48},
            online = false,
            messages = {
                { text = "Yo Aki! Catching the late-night stream. Ping me if you need tech archives.", sender = "ai", time = "10:15", seen = true }
            }
        },
        {
            id = 3,
            name = "Nagahashi (President)",
            color = {0.95, 0.65, 0.22},
            online = true,
            messages = {
                { text = "Aki! The fate of the Newspaper Club rests upon our shoulders tonight!", sender = "ai", time = "10:40", seen = true },
                { text = "Make that Mystery Report headline sensational! The Student Council shall tremble!", sender = "ai", time = "10:41", seen = true }
            }
        },
        {
            id = 4,
            name = "Hiko (Sister)",
            color = {0.22, 0.78, 0.85},
            online = true,
            messages = {
                { text = "Hey, don't forget to put away the curry dishes.", sender = "ai", time = "11:20", seen = true },
                { text = "And buy milk on your way home tomorrow! -_-", sender = "ai", time = "11:21", seen = true }
            }
        }
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
    
    self.draggingScrollbar = false
    self.draggingInbox = false
    self.scrollDragStart = 0
    self.scrollStartValue = 0
    
    self.searchText = ""
    self.searchActive = false
    
    self.typingTimer = 0
    self.isTyping = false
    self.typingUser = nil
    self.pendingReply = nil
    self.onReplyComplete = nil
    
    return self
end

-- Determine story-based dynamic chat progression
function ChatApp:syncStoryState()
    local hasBrowsedCatCafe = PlayerStats.getFlag("browser_visited:cat") or 
                              PlayerStats.getFlag("browsed_cat_cafe") or
                              PlayerStats.getFlag("task_cat_cafe_done")
                              
    local hasChattedSuzumia = PlayerStats.getFlag("chat_sent:suzumia") or
                              PlayerStats.getFlag("suzumia_chat_completed")

    -- 1. Suzumia's state
    local suzumia = self.users[1]
    if hasBrowsedCatCafe and not suzumia.stageTriggered then
        suzumia.stageTriggered = true
        suzumia.online = true
        table.insert(suzumia.messages, {
            text = "Aki-kun! Did you get a chance to check the Meow Latte photos on their site? :)",
            sender = "ai",
            time = "11:45",
            seen = false
        })
        table.insert(suzumia.messages, {
            text = "Mochi (the white Scottish Fold) looked so peaceful in the bay window sunlight... what do you think of making him the main cover photo?",
            sender = "ai",
            time = "11:46",
            seen = false
        })
        Notifications.add("Chat - Suzumia", "New message from Vice President Suzumia", nil, 5.0)
        AudioManager.playSFX("notification", 1.2)
    elseif hasBrowsedCatCafe then
        suzumia.online = true
    end

    -- 2. Hoshida's state
    local hoshida = self.users[2]
    if hasChattedSuzumia and not hoshida.stageTriggered then
        hoshida.stageTriggered = true
        hoshida.online = true
        table.insert(hoshida.messages, {
            text = "[URGENT] Aki, check your Downloads folder right now.",
            sender = "ai",
            time = "11:50",
            seen = false
        })
        table.insert(hoshida.messages, {
            text = "I dumped the raw packets from the 3rd floor repeater rack ('school_server_dump.log'). There is an encrypted XOR stream active on port 8080. Someone is using the school network as an unauthorized relay bridge.",
            sender = "ai",
            time = "11:51",
            seen = false
        })
        PlayerStats.setFlag("hoshida_alert", true)
        PlayerStats.setFlag("email_unlocked:105", true)
        Notifications.add("Hoshida [Root]", "URGENT: Port 8080 anomaly detected on school subnet!", nil, 6.0)
        AudioManager.playSFX("notification", 1.2)
    elseif hasChattedSuzumia then
        hoshida.online = true
    end
end

-- Get the scripted reply for Aki based on active user and story progression
function ChatApp:getScriptedInputForUser(user)
    if not user then return "", nil, nil end

    if user.id == 1 then -- Suzumia
        local hasBrowsedCatCafe = PlayerStats.getFlag("browser_visited:cat") or 
                                  PlayerStats.getFlag("browsed_cat_cafe") or
                                  PlayerStats.getFlag("task_cat_cafe_done")
        local hasChatted = PlayerStats.getFlag("chat_sent:suzumia") or PlayerStats.getFlag("suzumia_chat_completed")

        if hasBrowsedCatCafe and not hasChatted then
            return "The photos are fantastic! Mochi and Chobi are going to look amazing on our front cover. I'll make sure the layout highlights the 10% student discount too!",
                   "Yay! (///_///) I knew we'd agree! I'm so excited for tomorrow. Thank you so much, Aki-kun! Let's make this our best issue ever!",
                   function()
                       PlayerStats.setFlag("chat_sent:suzumia", true)
                       PlayerStats.setFlag("suzumia_chat_completed", true)
                       self:syncStoryState()
                   end
        else
            return "", nil, nil
        end

    elseif user.id == 2 then -- Hoshida
        local hasChattedSuzumia = PlayerStats.getFlag("chat_sent:suzumia") or PlayerStats.getFlag("suzumia_chat_completed")
        local hasChattedHoshida = PlayerStats.getFlag("chat_sent:hoshida") or PlayerStats.getFlag("hoshida_chat_completed")

        if hasChattedSuzumia and not hasChattedHoshida then
            return "Port 8080? I'll open 'school_server_dump.log' and extract the encryption token right away.",
                   "Find the XOR token. If you save it into 'cipher.txt' in your home folder, my firewall script will sever their proxy tunnel immediately.",
                   function()
                       PlayerStats.setFlag("chat_sent:hoshida", true)
                       PlayerStats.setFlag("hoshida_chat_completed", true)
                   end
        else
            return "", nil, nil
        end

    elseif user.id == 3 then -- Nagahashi
        local hasRepliedNagahashi = PlayerStats.getFlag("chat_sent:nagahashi")
        if not hasRepliedNagahashi then
            return "Understood, President. I'm balancing the Cat Cafe spotlight with the mystery report right now.",
                   "SPLENDID! The twin truth of youth and conspiracy shall triumph!",
                   function()
                       PlayerStats.setFlag("chat_sent:nagahashi", true)
                   end
        else
            return "", nil, nil
        end

    elseif user.id == 4 then -- Hiko
        local hasRepliedHiko = PlayerStats.getFlag("chat_sent:hiko")
        if not hasRepliedHiko then
            return "Got it. I'll microwave the curry and get the milk on my way home from school tomorrow.",
                   "Good. Don't stay up all night clattering on your mechanical keyboard.",
                   function()
                       PlayerStats.setFlag("chat_sent:hiko", true)
                   end
        else
            return "", nil, nil
        end
    end

    return "", nil, nil
end

function ChatApp:update(dt)
    self:syncStoryState()

    self.cursorTimer = self.cursorTimer + dt
    if self.cursorTimer > 0.5 then
        self.cursorVisible = not self.cursorVisible
        self.cursorTimer = 0
    end
    
    if self.isTyping and self.typingUser then
        self.typingTimer = self.typingTimer - dt
        if self.typingTimer <= 0 then
            self.isTyping = false
            local replyText = self.pendingReply or "Sounds good!"
            table.insert(self.typingUser.messages, {
                text = replyText,
                sender = "ai",
                time = os.date("%H:%M"),
                seen = false
            })
            AudioManager.playSFX("notification", 1.1)

            if self.onReplyComplete then
                self.onReplyComplete()
                self.onReplyComplete = nil
            end

            if self.currentView == "chat" and self.activeUserId == self.typingUser.id then
                self:scrollToBottom()
            end
            self.typingUser = nil
            self.pendingReply = nil
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
        local viewHeight = self.windowHeight - 80
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
    love.graphics.setColor(colors.background)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(colors.divider)
    love.graphics.line(x, y + 0, x + width, y + 0)
    
    local searchY = y + 16
    local searchX = x + 16
    local searchWidth = width - 32
    
    love.graphics.setColor(colors.shadow)
    love.graphics.rectangle("fill", searchX, searchY + 2, searchWidth, 40, 8)
    
    love.graphics.setColor(colors.searchBg)
    love.graphics.rectangle("fill", searchX, searchY, searchWidth, 40, 8)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setFont(self.font)
    
    if self.searchText == "" and not self.searchActive then
        love.graphics.printf("Search contacts...", searchX + 16, searchY + 12, searchWidth - 32, "left")
    else
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.printf(self.searchText, searchX + 16, searchY + 12, searchWidth - 32, "left")
    end
    
    local viewY = y + 68
    local viewHeight = height - 68
    love.graphics.setScissor(x, viewY, width, viewHeight)
    
    local itemHeight = 72
    local currentY = viewY - self.inboxScroll
    local mx, my = love.mouse.getPosition()
    local filteredUsers = self:getFilteredUsers()
    
    for _, user in ipairs(filteredUsers) do
        local itemRect = {x = x, y = currentY, w = width, h = itemHeight}
        
        if mx >= itemRect.x and mx <= itemRect.x + itemRect.w and 
           my >= itemRect.y and my < itemRect.y + itemRect.h and
           my >= viewY and my <= viewY + viewHeight then
            love.graphics.setColor(colors.hover)
            love.graphics.rectangle("fill", itemRect.x, itemRect.y, itemRect.w, itemRect.h)
        end
        
        love.graphics.setColor(user.color)
        love.graphics.circle("fill", x + 40, currentY + 36, 22)
        
        -- Online / Offline dot
        if user.online then
            love.graphics.setColor(colors.online)
            love.graphics.circle("fill", x + 54, currentY + 50, 7)
            love.graphics.setColor(colors.inboxBg)
            love.graphics.circle("fill", x + 54, currentY + 50, 5)
            love.graphics.setColor(colors.online)
            love.graphics.circle("fill", x + 54, currentY + 50, 4)
        else
            love.graphics.setColor(colors.offline)
            love.graphics.circle("fill", x + 54, currentY + 50, 5)
        end
        
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.setFont(self.titleFont)
        love.graphics.print(user.name, x + 78, currentY + 14)
        
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
            
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.setFont(self.timeFont)
            love.graphics.printf(lastMsg.time, x + width - 44, currentY + 16, 40, "right")
            
            if unread > 0 then
                local badgeX = x + width - 28
                love.graphics.setColor(colors.primary)
                love.graphics.circle("fill", badgeX, currentY + 48, 10)
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(self.timeFont)
                love.graphics.printf(tostring(unread), badgeX - 5, currentY + 43, 10, "center")
            end
        end
        
        love.graphics.setColor(colors.divider)
        love.graphics.line(x + 16, currentY + itemHeight - 1, x + width - 16, currentY + itemHeight - 1)
        
        currentY = currentY + itemHeight
    end
    
    love.graphics.setScissor()
    self:drawScrollbar(x + width - 8, viewY, 4, viewHeight, self.inboxScroll, self.inboxMaxScroll)
end

function ChatApp:drawChat(x, y, width, height)
    local user = self:getActiveUser()
    if not user then return end
    
    self:markMessagesSeen(user)
    
    love.graphics.setColor(colors.background)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Header Bar
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", x, y, width, 60)
    
    -- Back button
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
    
    -- Status
    love.graphics.setFont(self.timeFont)
    if user.online then
        love.graphics.setColor(colors.online)
        love.graphics.printf("Active now", x + 70, y + 38, width - 140, "left")
    else
        love.graphics.setColor(colors.offline)
        love.graphics.printf("Offline", x + 70, y + 38, width - 140, "left")
    end
    
    -- Avatar
    love.graphics.setColor(user.color)
    love.graphics.circle("fill", x + width - 40, y + 30, 20)
    
    -- Messages Area
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
                love.graphics.setColor(user.color)
                love.graphics.circle("fill", x + 32, currentY + 18, 16)
                
                love.graphics.setColor(colors.shadow)
                love.graphics.rectangle("fill", x + 52 + 2, currentY + 2, bubbleWidth, bubbleHeight, 18)
                love.graphics.setColor(colors.aiBubble)
                love.graphics.rectangle("fill", x + 52, currentY, bubbleWidth, bubbleHeight, 18)
                
                love.graphics.setColor(colors.aiText)
                love.graphics.setFont(self.font)
                love.graphics.printf(msg.text, x + 64, currentY + 12, bubbleWidth - 24, "left")
                
                love.graphics.setColor(colors.timeText)
                love.graphics.setFont(self.timeFont)
                love.graphics.print(msg.time, x + 52 + bubbleWidth + 8, currentY + bubbleHeight - 16)
            else
                local bX = x + width - bubbleWidth - 16
                
                love.graphics.setColor(colors.shadow)
                love.graphics.rectangle("fill", bX + 2, currentY + 2, bubbleWidth, bubbleHeight, 18)
                love.graphics.setColor(colors.userBubble)
                love.graphics.rectangle("fill", bX, currentY, bubbleWidth, bubbleHeight, 18)
                
                love.graphics.setColor(colors.userText)
                love.graphics.setFont(self.font)
                love.graphics.printf(msg.text, bX + 16, currentY + 12, bubbleWidth - 24, "left")
                
                love.graphics.setColor(colors.timeText)
                love.graphics.setFont(self.timeFont)
                local tw = self.timeFont:getWidth(msg.time)
                love.graphics.print(msg.time, bX - tw - 8, currentY + bubbleHeight - 16)
            end
        end
        
        currentY = currentY + bubbleHeight + 8
    end
    
    if self.isTyping and self.typingUser == user then
        love.graphics.setColor(colors.shadow)
        love.graphics.rectangle("fill", x + 52 + 2, currentY + 2, 80, 36, 18)
        love.graphics.setColor(colors.aiBubble)
        love.graphics.rectangle("fill", x + 52, currentY, 80, 36, 18)
        love.graphics.setColor(colors.primary)
        love.graphics.setFont(self.font)
        love.graphics.print("Typing...", x + 64, currentY + 12)
        currentY = currentY + 44
    end
    
    love.graphics.setScissor()
    self:drawScrollbar(x + width - 8, chatY, 4, chatHeight, self.chatScroll, self.chatMaxScroll)
    
    -- SCRIPTED INPUT AREA
    local inputY = y + height - 70
    love.graphics.setColor(colors.header)
    love.graphics.rectangle("fill", x, inputY, width, 70)
    love.graphics.setColor(colors.divider)
    love.graphics.line(x, inputY, x + width, inputY)
    
    local inputBoxX = x + 16
    local sendBtnW = 70
    local inputBoxW = width - sendBtnW - 40
    
    -- Get current scripted response
    local scriptedMsg, replyText, onComplete = self:getScriptedInputForUser(user)
    local canSend = (scriptedMsg ~= "" and not self.isTyping)
    self.inputText = scriptedMsg
    
    love.graphics.setColor(colors.shadow)
    love.graphics.rectangle("fill", inputBoxX, inputY + 12 + 2, inputBoxW, 44, 22)
    love.graphics.setColor(colors.inputBg)
    love.graphics.rectangle("fill", inputBoxX, inputY + 12, inputBoxW, 44, 22)
    
    if canSend then
        love.graphics.setColor(0.0, 0.47, 0.83, 0.4)
    else
        love.graphics.setColor(colors.border)
    end
    love.graphics.rectangle("line", inputBoxX, inputY + 12, inputBoxW, 44, 22)
    
    love.graphics.setFont(self.font)
    local inputX = inputBoxX + 16
    love.graphics.setScissor(inputX, inputY + 12, inputBoxW - 24, 44)
    
    if canSend then
        love.graphics.setColor(0.12, 0.14, 0.18)
        love.graphics.print(self.inputText, inputX, inputY + 24)
    else
        love.graphics.setColor(0.65, 0.68, 0.72)
        love.graphics.print("(No message to send right now)", inputX, inputY + 24)
    end
    love.graphics.setScissor()
    
    -- Send Button
    local sendBtnX = x + width - sendBtnW - 16
    local sendBtnY = inputY + 14
    local sendBtnH = 40
    
    local sendHovered = mx >= sendBtnX and mx <= sendBtnX + sendBtnW and
                        my >= sendBtnY and my <= sendBtnY + sendBtnH
                        
    if canSend then
        if sendHovered then
            love.graphics.setColor(colors.primaryDark)
        else
            love.graphics.setColor(colors.primary)
        end
    else
        love.graphics.setColor(colors.disabledBtn)
    end
    
    love.graphics.rectangle("fill", sendBtnX, sendBtnY, sendBtnW, sendBtnH, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Send", sendBtnX, sendBtnY + 11, sendBtnW, "center")
end

function ChatApp:drawScrollbar(scrollX, viewY, thumbWidth, viewHeight, scroll, maxScroll)
    if maxScroll <= 0 then return end
    
    local trackHeight = viewHeight
    local visibleRatio = viewHeight / (maxScroll + viewHeight)
    local thumbHeight = math.max(40, trackHeight * visibleRatio)
    local thumbY = viewY + (scroll / maxScroll) * (trackHeight - thumbHeight)
    
    love.graphics.setColor(colors.scrollbarBg)
    love.graphics.rectangle("fill", scrollX, viewY, thumbWidth, trackHeight, 4)
    
    love.graphics.setColor(colors.scrollbarFg)
    love.graphics.rectangle("fill", scrollX, thumbY, thumbWidth, thumbHeight, 4)
end

function ChatApp:mousepressed(mx, my, button, wx, wy)
    if button == 1 then
        if self.currentView == "inbox" then
            local viewY = 68
            local viewHeight = self.windowHeight - 68
            
            local scrollX = self.windowX + self.windowWidth - 8
            if mx >= scrollX and mx <= scrollX + 4 and my >= viewY and my <= viewY + viewHeight then
                self.draggingScrollbar = true
                self.draggingInbox = true
                self.scrollDragStart = my
                self.scrollStartValue = self.inboxScroll
                return
            end
            
            local searchY = 16
            if my >= searchY and my <= searchY + 40 and mx >= 16 and mx <= self.windowWidth - 16 then
                self.searchActive = true
            else
                self.searchActive = false
            end
            
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
            local sendBtnW = 70
            local sendBtnX = self.windowWidth - sendBtnW - 16
            if mx >= sendBtnX and mx <= sendBtnX + sendBtnW and 
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
    -- Freeform typing is disabled in chat to preserve narrative story integrity
    if self.searchActive and self.currentView == "inbox" then
        self.searchText = self.searchText .. text
        self.inboxScroll = 0
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
        if key == "return" or key == "space" then
            self:sendMessage()
        elseif key == "escape" then
            self.currentView = "inbox"
            self.activeUserId = nil
        end
    end
end

function ChatApp:sendMessage()
    local user = self:getActiveUser()
    if not user or self.isTyping then return end
    
    local scriptedMsg, replyText, onComplete = self:getScriptedInputForUser(user)
    if not scriptedMsg or scriptedMsg == "" then return end
    
    table.insert(user.messages, {
        text = scriptedMsg,
        sender = "user",
        time = os.date("%H:%M"),
        seen = true
    })
    
    AudioManager.playSFX("click", 1.2)
    self:scrollToBottom()
    
    EventBus.emit("chat:sent", {
        user = user.name,
        userId = user.id,
        text = scriptedMsg
    })
    
    if replyText and replyText ~= "" then
        self.isTyping = true
        self.typingTimer = 1.2
        self.typingUser = user
        self.pendingReply = replyText
        self.onReplyComplete = onComplete
    elseif onComplete then
        onComplete()
    end
end

function ChatApp:resize(w, h)
    if self.windowHeight then
        self:calculateScroll()
    end
end

return ChatApp