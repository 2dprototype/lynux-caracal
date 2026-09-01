-- src/apps/email.lua
local PlayerStats = require("src.core.player_stats")
local filesystem = require("src.core.filesystem")
local EventBus = require("src.core.event_bus")
local Notifications = require("src.desktop.notifications")
local AudioManager = require("src.core.audio_manager")

local EmailApp = {}
EmailApp.__index = EmailApp

function EmailApp.new()
    local self = setmetatable({}, EmailApp)
    self.font10 = love.graphics.newFont("font/Nunito-Regular.ttf", 10) or love.graphics.newFont(10)
    self.font11 = love.graphics.newFont("font/Nunito-Regular.ttf", 11) or love.graphics.newFont(11)
    self.font12 = love.graphics.newFont("font/Nunito-Regular.ttf", 12) or love.graphics.newFont(12)
    self.font13 = love.graphics.newFont("font/Nunito-Regular.ttf", 13) or love.graphics.newFont(13)
    self.font14 = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.font16 = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 16) or love.graphics.newFont(16)
    self.font20 = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 20) or love.graphics.newFont(20)
    
    -- Master Email Database with progressive unlock flags and attachments
    self.allEmails = {
        {
            id = 101,
            subject = "Dinner tonight + DON'T forget the laundry!",
            sender = "Hiko (Sister)",
            email = "hiko.akizuki@kamiyama.net",
            time = "11:15 PM",
            body = "Hey big brother!\n\nI left some leftover curry in the fridge with plastic wrap. Make sure you microwave it before eating instead of eating it cold like a savage.\n\nAlso, are you still staying up late on the computer? Mom called and said don't forget to buy milk on your way home from school tomorrow.\n\nBy the way, all the first-years in my class were whispering today about weird noises and blinking lights from the 3rd floor old server room after 6 PM... Is your Newspaper Club really investigating that? Don't get suspended, dummy!\n\n- Hiko",
            unread = true,
            starred = true,
            unlocked = true
        },
        {
            id = 102,
            subject = "Cat Cafe Draft Notes & Photo Selection [URGENT cute!]",
            sender = "Suzumia (Vice President)",
            email = "suzumia.y@kamiyama-press.org",
            time = "11:42 PM",
            body = "Hi Aki-kun,\n\nThank you so much for backing me up during the editorial meeting today when President Nagahashi started going overboard with his ghost story idea!\n\nI just organized my interview notes from the Meow Latte Cat Cafe. The owner was super nice and gave us permission to publish photos of Mochi (the white Scottish Fold) and Chobi (the calico)! Mochi actually climbed into my lap while I was writing notes... it was heaven. (///_///)\n\nI have attached my raw draft notes below ('cat_cafe_review.txt'). Please click the attachment below to download it to your Downloads folder, then check the formatting and menu pricing in TextEditor! I really want our front-cover feature to turn out amazing.\n\nSee you in the clubroom tomorrow!\n\n- Suzumia",
            unread = true,
            starred = true,
            unlocked = true,
            attachment = {
                filename = "cat_cafe_review.txt",
                size = "1.4 KB",
                content = "=== KAMIYAMA HIGH NEWSPAPER: SPECIAL FEATURE ===\nTITLE: A Whiskered Paradise: Visiting 'Meow Latte' Cat Cafe\nAUTHOR: Suzumia (VP) & Aki (Reporter)\n\n[HIGHLIGHTS]\n- Location: 3 minutes walking from Kamiyama Station South Exit.\n- Atmosphere: Warm wood interior, sunlight through large bay windows, relaxing jazz music.\n- Featured Stars:\n  * Mochi (White Scottish Fold) - Extremely friendly, curled up on our notes!\n  * Chobi (Calico Shorthair) - Playful and curious, loved our camera straps.\n- Recommended Treats: Strawberry Cat-Paw Parfait (¥680), Souffle Pancakes (¥750).\n- Student Special: 10% discount when presenting Kamiyama High ID card!\n\nNote from Suzumia: Aki-kun, let's make sure Mochi's picture is front and center on the main cover!"
            }
        },
        {
            id = 103,
            subject = "OPERATION GHOST SCOOP: Editorial Manifesto #42",
            sender = "Nagahashi (President)",
            email = "president.nagahashi@kamiyama-press.org",
            time = "10:30 PM",
            body = "ATTENTION ALL NEWSPAPER CLUB PERSONNEL:\n\nThe Student Council thinks they can intimidate us with their budget review threats. THEY ARE MISTAKEN.\n\nOur upcoming edition MUST be sensational. Aki, as Lead Layout Editor, I expect you to give the 'Midnight Server Room Urban Legend' article the most dramatic, spine-chilling headline possible! Use red ink borders if the school mimeograph allows it!\n\nI know Suzumia insisted on her cat cafe piece, so we will compromise with the Dual Cover format. But the Mystery Report will be our magnum opus!\n\nJournalistic glory awaits!\n\n- President Nagahashi",
            unread = true,
            starred = false,
            unlocked = true
        },
        {
            id = 104,
            subject = "Notice of Review: Newspaper Club Operating Budget",
            sender = "Student Council (Auditing)",
            email = "council-audit@kamiyama-hs.ed.jp",
            time = "04:15 PM",
            body = "To: Kamiyama High Newspaper Club Editorial Board\n\nThis is a formal notification regarding the upcoming Q3 Club Budget Allocation Review.\n\nDue to declining readership in recent issues, your allocated printing quota is subject to a 40% reduction unless circulation and verified student engagement show a marked increase in the upcoming Special Edition.\n\nPlease submit your publication draft by Friday afternoon.\n\nKamiyama High Student Council Auditing Committee",
            unread = false,
            starred = false,
            unlocked = true
        },
        {
            id = 105,
            subject = "Found that old server archive dump you asked for",
            sender = "Hoshida",
            email = "hoshida.tech@kamiyama-press.org",
            time = "09:50 PM",
            body = "Yo Aki,\n\nI dug through our club's old backup drive and found the raw network dump from last year's website server. I put it in your Downloads folder as 'school_server_dump.log'.\n\nNagahashi thinks he's just inventing spooky rumors to scare freshmen, but... honestly, there are some strange outbound packets logged on port 8080 from the old terminal. Take a look when you're at your desk.\n\nAnyway, back to watching my late-night anime stream. 2D cat maids > 3D drama any day.\n\n( ^ _ ^ )/\n- Hoshida",
            unread = true,
            starred = false,
            unlocked = false,
            unlockFlag = "email_unlocked:105",
            attachment = {
                filename = "school_server_dump.log",
                size = "2.8 KB",
                content = "[23:14:02] [ETH-0] INBOUND PACKET on Port 8080 from 192.168.1.144 (Old 3rd Floor Rack)\n[23:14:03] [PAYLOAD] Encrypted XOR stream detected [Length: 256 bytes]\n[23:14:04] [DECRYPTOR] Matching signature with Newspaper Club archive...\n[23:14:05] [KEY_FOUND] Secret Token: SHADOW-CAT-09\n[23:14:06] [STATUS] Remote node ping active. Traceroute bounces through 3 internal relays.\n[23:14:07] [NOTE] Hoshida: 'Aki, someone is definitely using the school old repeater as a proxy.'"
            }
        },
        {
            id = 106,
            subject = "[CONFIDENTIAL] Traceroute analysis & Basement Sub-Station Anomaly",
            sender = "Hoshida",
            email = "hoshida.tech@kamiyama-press.org",
            time = "07:15 AM",
            body = "Aki,\n\nI ran a subnet traceroute on the repeater while eating morning Pocky.\n\nThe packet route does not end on the 3rd floor. The signal is being re-routed down the elevator shaft into the locked basement power sub-station (IP: 192.168.1.254).\n\nCheck 'traceroute_dump.txt' in your Downloads folder.\n\nThe MAC address matches a commercial high-gain transceiver. Someone is piggybacking on our school grid to host an external server.\n\nKeep this between us until we pass the Student Council audit at 5 PM.\n\n- Hoshida [Root]",
            unread = true,
            starred = true,
            unlocked = false,
            unlockFlag = "email_unlocked:106",
            attachment = {
                filename = "traceroute_dump.txt",
                size = "1.8 KB",
                content = "=== KAMIYAMA HIGH INTRANET TRACEROUTE LOG ===\nTARGET: port8080.ghost-relay.local\n\nHOP 1: 192.168.1.1 (Kamiyama Gateway Router) [1.2ms]\nHOP 2: 192.168.1.144 (3rd Floor Switchboard 04) [4.5ms]\nHOP 3: 192.168.1.254 (Basement Electrical Conduit Sub-Station) [0.8ms]\n\nALERT: Target IP 192.168.1.254 responds with MAC: 00:1A:C2:7B:99:4F\nNOTE (Hoshida): This MAC address belongs to an external commercial mesh router, not school inventory!\nCIPHER VERIFIED: [SHADOW-CAT-09]"
            }
        }
    }
    
    self.colors = {
        bg = {0.96, 0.97, 0.98},
        paneBg = {1, 1, 1},
        primaryText = {0.12, 0.12, 0.13},
        secondaryText = {0.36, 0.38, 0.41},
        accentRed = {0.85, 0.18, 0.14},
        accentBlueHover = {0.93, 0.95, 0.99},
        border = {0.88, 0.89, 0.91}
    }
    
    self.selected = 1
    self.activeFolder = "Inbox"
    self.folders = {
        {name = "Inbox", icon = "i", count = 0},
        {name = "Starred", icon = "*"},
        {name = "Sent", icon = "v"},
        {name = "Drafts", icon = "#"}
    }
    
    self.width = 0
    self.height = 0
    self.sidebarWidth = 120
    self.minWidthForDetail = 700
    
    self.mouseX = -1
    self.mouseY = -1
    self.mousePressed = false
    self.showingDetailMobile = false
    
    self.scrollOffset = 0
    self.maxScroll = 0
    self.isDraggingScrollbar = false
    self.scrollDragOffset = 0
    
    self.listScrollOffset = 0
    self.listMaxScroll = 0
    self.isDraggingListScrollbar = false
    self.listScrollDragOffset = 0
    
    -- Hit box for attachment download button
    self.attachmentButtonRect = nil
    
    return self
end

function EmailApp:getVisibleEmails()
    local visible = {}
    for _, email in ipairs(self.allEmails) do
        local isUnlocked = email.unlocked
        if not isUnlocked and email.unlockFlag then
            if PlayerStats.getFlag(email.unlockFlag) or 
               (email.id == 105 and (PlayerStats.getFlag("hoshida_alert") or PlayerStats.getFlag("chat_sent:suzumia"))) or
               (email.id == 106 and (PlayerStats.getFlag("chapter_2_started") or PlayerStats.getFlag("task_chapter2_master_proof"))) then
                isUnlocked = true
                email.unlocked = true
            end
        end

        if isUnlocked then
            if self.activeFolder == "Inbox" then
                table.insert(visible, email)
            elseif self.activeFolder == "Starred" and email.starred then
                table.insert(visible, email)
            end
        end
    end
    
    -- Update unread count for Inbox
    local unreadCount = 0
    for _, e in ipairs(visible) do
        if e.unread then unreadCount = unreadCount + 1 end
    end
    self.folders[1].count = unreadCount
    
    return visible
end

function EmailApp:draw(x, y, width, height)
    self.width = width
    self.height = height
    self.attachmentButtonRect = nil
    
    love.graphics.push()
    love.graphics.translate(x, y)
    
    love.graphics.setColor(self.colors.bg)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    local isCompact = width < self.minWidthForDetail
    self:drawSidebar(isCompact)
    
    local leftRemainingWidth = width - self.sidebarWidth
    local visibleEmails = self:getVisibleEmails()
    
    if #visibleEmails == 0 then
        self.selected = 1
    elseif self.selected > #visibleEmails then
        self.selected = #visibleEmails
    end
    
    if isCompact then
        if self.showingDetailMobile then
            self:drawEmailDetail(self.sidebarWidth, leftRemainingWidth, x, y, true, visibleEmails)
        else
            self:drawEmailList(self.sidebarWidth, leftRemainingWidth, x, y, true, visibleEmails)
        end
    else
        local emailListWidth = math.floor(leftRemainingWidth * 0.42)
        local contentWidth = leftRemainingWidth - emailListWidth
        
        self:drawEmailList(self.sidebarWidth, emailListWidth, x, y, false, visibleEmails)
        self:drawEmailDetail(self.sidebarWidth + emailListWidth, contentWidth, x, y, false, visibleEmails)
    end
    
    love.graphics.pop()
end

function EmailApp:drawSidebar(isCompact)
    love.graphics.setColor(self.colors.accentRed)
    love.graphics.rectangle("fill", 15, 12, 28, 20, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font12)
    love.graphics.printf("M", 15, 15, 28, "center")
    
    if not isCompact then
        love.graphics.setColor(self.colors.primaryText)
        love.graphics.setFont(self.font16)
        love.graphics.print("Mail", 50, 13)
    end
    
    local folderY = 55
    local itemHeight = 32
    love.graphics.setFont(self.font13)
    
    for _, folder in ipairs(self.folders) do
        local isSelected = self.activeFolder == folder.name
        local isHovered = self.mouseX >= 8 and self.mouseX <= self.sidebarWidth - 8 and
                          self.mouseY >= folderY and self.mouseY <= folderY + itemHeight
                          
        if isSelected then
            love.graphics.setColor(0.92, 0.2, 0.16, 0.12)
            love.graphics.rectangle("fill", 8, folderY, self.sidebarWidth - 16, itemHeight, 16)
            love.graphics.setColor(self.colors.accentRed)
        elseif isHovered then
            love.graphics.setColor(0.9, 0.9, 0.92)
            love.graphics.rectangle("fill", 8, folderY, self.sidebarWidth - 16, itemHeight, 16)
            love.graphics.setColor(self.colors.primaryText)
        else
            love.graphics.setColor(self.colors.secondaryText)
        end
        
        love.graphics.print(folder.icon, 20, folderY + 8)
        love.graphics.print(folder.name, 35, folderY + 8)
        
        if folder.count and folder.count > 0 then
            love.graphics.setColor(self.colors.secondaryText)
            love.graphics.setFont(self.font11)
            love.graphics.printf(tostring(folder.count), self.sidebarWidth - 35, folderY + 9, 20, "right")
            love.graphics.setFont(self.font13)
        end
        
        folderY = folderY + itemHeight + 2
    end
end

function EmailApp:drawEmailList(startX, listWidth, absX, absY, isCompact, emails)
    local padding = 8
    local innerX = startX + padding
    local innerY = padding
    local innerW = listWidth - (padding * 2)
    local innerH = self.height - (padding * 2)
    
    love.graphics.setColor(self.colors.paneBg)
    love.graphics.rectangle("fill", innerX, innerY, innerW, innerH, 8)
    
    love.graphics.setColor(self.colors.border)
    love.graphics.rectangle("line", innerX, innerY, innerW, innerH, 8)
    
    local headerHeight = 40
    local rowHeight = 75
    local totalListHeight = headerHeight + (#emails * rowHeight)
    self.listMaxScroll = math.max(0, totalListHeight - innerH)
    self.listScrollOffset = math.max(0, math.min(self.listScrollOffset, self.listMaxScroll))
    
    love.graphics.setScissor(absX + innerX, absY + innerY, innerW, innerH)
    
    local drawY = innerY + 16 - self.listScrollOffset
    love.graphics.setColor(self.colors.secondaryText)
    love.graphics.setFont(self.font12)
    
    if isCompact and self.showingDetailMobile then
        love.graphics.print("Back", innerX + 16, drawY)
    else
        love.graphics.print(string.upper(self.activeFolder), innerX + 16, drawY)
    end
    
    local rowY = innerY + headerHeight - self.listScrollOffset
    
    for i, email in ipairs(emails) do
        local isSelected = i == self.selected
        local isHovered = self.mouseX >= innerX and self.mouseX <= innerX + innerW and
                          self.mouseY >= rowY and self.mouseY <= rowY + rowHeight - 1
                          
        if isSelected then
            love.graphics.setColor(self.colors.accentBlueHover)
            love.graphics.rectangle("fill", innerX + 2, rowY, innerW - 4, rowHeight - 2, 4)
        elseif isHovered then
            love.graphics.setColor(0.97, 0.97, 0.98)
            love.graphics.rectangle("fill", innerX + 2, rowY, innerW - 4, rowHeight - 2, 4)
        end
        
        love.graphics.setColor(self.colors.border)
        love.graphics.line(innerX + 12, rowY + rowHeight - 1, innerX + innerW - 12, rowY + rowHeight - 1)
        
        if email.unread then
            love.graphics.setColor(self.colors.primaryText)
            love.graphics.setFont(self.font13)
        else
            love.graphics.setColor(self.colors.secondaryText)
            love.graphics.setFont(self.font13)
        end
        
        local senderName = email.sender
        if isCompact and #senderName > 20 then
            senderName = string.sub(senderName, 1, 18) .. "..."
        end
        love.graphics.print(senderName, innerX + 16, rowY + 10)
        
        love.graphics.setColor(self.colors.secondaryText)
        love.graphics.setFont(self.font11)
        love.graphics.printf(email.time, innerX + innerW - 80, rowY + 12, 65, "right")
        
        love.graphics.setFont(self.font12)
        if email.starred then
            love.graphics.setColor(0.95, 0.65, 0)
            love.graphics.print("*", innerX + innerW - 22, rowY + 36)
        else
            love.graphics.setColor(0.75, 0.75, 0.75)
            love.graphics.print("*", innerX + innerW - 22, rowY + 36)
        end
        
        love.graphics.setColor(self.colors.primaryText)
        love.graphics.setFont(self.font12)
        local maxSubjectLen = isCompact and 22 or 28
        local dispSubject = email.subject
        if #dispSubject > maxSubjectLen then dispSubject = string.sub(dispSubject, 1, maxSubjectLen - 2) .. "..." end
        love.graphics.print(dispSubject, innerX + 16, rowY + 30)
        
        love.graphics.setColor(self.colors.secondaryText)
        love.graphics.setFont(self.font11)
        local bodyExcerpt = email.body:gsub("\n", " ")
        local maxBodyLen = isCompact and 30 or 38
        if #bodyExcerpt > maxBodyLen then bodyExcerpt = string.sub(bodyExcerpt, 1, maxBodyLen - 2) .. "..." end
        love.graphics.print(bodyExcerpt, innerX + 16, rowY + 48)
        
        rowY = rowY + rowHeight
    end
    
    love.graphics.setScissor()
    
    if self.listMaxScroll > 0 then
        local scrollbarWidth = 6
        local trackX = innerX + innerW - scrollbarWidth - 2
        local trackY = innerY + 2
        local trackHeight = innerH - 4
        
        local thumbHeight = math.max(30, (innerH / totalListHeight) * trackHeight)
        local thumbY = trackY + (self.listScrollOffset / self.listMaxScroll) * (trackHeight - thumbHeight)
        
        local isThumbHovered = self.mouseX >= trackX and self.mouseX <= trackX + scrollbarWidth and
                              self.mouseY >= thumbY and self.mouseY <= thumbY + thumbHeight
        
        love.graphics.setColor(0.93, 0.93, 0.94)
        love.graphics.rectangle("fill", trackX, trackY, scrollbarWidth, trackHeight, 3)
        
        if self.isDraggingListScrollbar then
            love.graphics.setColor(0.5, 0.5, 0.5)
        elseif isThumbHovered then
            love.graphics.setColor(0.65, 0.65, 0.65)
        else
            love.graphics.setColor(0.8, 0.8, 0.8)
        end
        love.graphics.rectangle("fill", trackX, thumbY, scrollbarWidth, thumbHeight, 3)
    end
end

function EmailApp:drawEmailDetail(startX, detailWidth, absX, absY, isCompact, emails)
    local padding = 8
    local innerX = startX
    local innerY = padding
    local innerW = detailWidth - padding
    local innerH = self.height - (padding * 2)
    
    love.graphics.setColor(self.colors.paneBg)
    love.graphics.rectangle("fill", innerX, innerY, innerW, innerH, 8)
    
    love.graphics.setColor(self.colors.border)
    love.graphics.rectangle("line", innerX, innerY, innerW, innerH, 8)
    
    local email = emails[self.selected]
    if not email then
        love.graphics.setColor(self.colors.secondaryText)
        love.graphics.setFont(self.font14)
        love.graphics.printf("No conversation selected", innerX, innerY + (innerH/2) - 10, innerW, "center")
        return
    end
    
    local contentPadding = isCompact and 16 or 24
    local readerWidth = innerW - (contentPadding * 2)
    
    local textFont = self.font14
    local headerSize = 145
    local _, lines = textFont:getWrap(email.body, readerWidth - 20)
    local bodyHeight = #lines * textFont:getHeight()
    local attachmentHeight = email.attachment and 80 or 0
    local totalContentHeight = headerSize + bodyHeight + attachmentHeight + 60
    
    self.maxScroll = math.max(0, totalContentHeight - innerH)
    self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
    
    love.graphics.setScissor(absX + innerX, absY + innerY, innerW - 14, innerH)
    
    local drawY = innerY + contentPadding - self.scrollOffset
    
    if isCompact then
        love.graphics.setColor(self.colors.accentRed)
        love.graphics.setFont(self.font13)
        love.graphics.print("Inbox", innerX + contentPadding, drawY)
        drawY = drawY + 30
    end
    
    -- Subject title
    love.graphics.setColor(self.colors.primaryText)
    love.graphics.setFont(isCompact and self.font16 or self.font20)
    love.graphics.printf(email.subject, innerX + contentPadding, drawY, readerWidth, "left")
    
    drawY = drawY + (isCompact and 35 or 45)
    
    -- Star Action
    love.graphics.setFont(self.font16)
    if email.starred then
        love.graphics.setColor(0.95, 0.65, 0)
        love.graphics.print("*", innerX + contentPadding, drawY + 8)
    else
        love.graphics.setColor(0.75, 0.75, 0.75)
        love.graphics.print("*", innerX + contentPadding, drawY + 8)
    end
    
    -- Sender Avatar Circle
    love.graphics.setColor(0.88, 0.92, 0.98)
    love.graphics.circle("fill", innerX + contentPadding + 40, drawY + 18, 16)
    love.graphics.setColor(self.colors.accentRed)
    love.graphics.setFont(self.font12)
    love.graphics.printf(string.upper(string.sub(email.sender, 1, 1)), innerX + contentPadding + 24, drawY + 12, 32, "center")
    
    -- Sender metadata
    love.graphics.setColor(self.colors.primaryText)
    love.graphics.setFont(self.font13)
    local senderName = email.sender
    if isCompact and #senderName > 25 then
        senderName = string.sub(senderName, 1, 23) .. "..."
    end
    love.graphics.print(senderName, innerX + contentPadding + 65, drawY + 4)
    
    love.graphics.setColor(self.colors.secondaryText)
    love.graphics.setFont(self.font11)
    love.graphics.print("<" .. email.email .. ">", innerX + contentPadding + 65, drawY + 20)
    
    -- Separator
    drawY = drawY + 50
    love.graphics.setColor(self.colors.border)
    love.graphics.line(innerX + contentPadding, drawY, innerX + innerW - contentPadding, drawY)
    
    -- Message Body
    drawY = drawY + 20
    love.graphics.setColor(self.colors.primaryText)
    love.graphics.setFont(textFont)
    love.graphics.printf(email.body, innerX + contentPadding, drawY, readerWidth - 20, "left")
    drawY = drawY + bodyHeight + 25
    
    -- ATTACHMENT CARD SECTION
    if email.attachment then
        local att = email.attachment
        local attCardX = innerX + contentPadding
        local attCardY = drawY
        local attCardW = readerWidth - 10
        local attCardH = 64
        
        -- Check if already downloaded
        local isDownloaded = PlayerStats.getFlag("downloaded:" .. att.filename:lower()) or 
                            TaskConditions_fileExists_check("home/user/Downloads/" .. att.filename)
        
        -- Card background with shadow
        love.graphics.setColor(0, 0, 0, 0.04)
        love.graphics.rectangle("fill", attCardX + 2, attCardY + 2, attCardW, attCardH, 6)
        
        if isDownloaded then
            love.graphics.setColor(0.93, 0.98, 0.94)
        else
            love.graphics.setColor(0.95, 0.96, 0.98)
        end
        love.graphics.rectangle("fill", attCardX, attCardY, attCardW, attCardH, 6)
        
        love.graphics.setColor(self.colors.border)
        love.graphics.rectangle("line", attCardX, attCardY, attCardW, attCardH, 6)
        
        -- File Icon Badge
        love.graphics.setColor(0.0, 0.47, 0.83)
        love.graphics.rectangle("fill", attCardX + 12, attCardY + 12, 40, 40, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.font11)
        love.graphics.printf("TXT", attCardX + 12, attCardY + 25, 40, "center")
        
        -- File info text
        love.graphics.setFont(self.font13)
        love.graphics.setColor(self.colors.primaryText)
        love.graphics.print(att.filename, attCardX + 62, attCardY + 14)
        
        love.graphics.setFont(self.font11)
        love.graphics.setColor(self.colors.secondaryText)
        love.graphics.print(att.size .. "  •  Attachment", attCardX + 62, attCardY + 34)
        
        -- Download / Status Button
        local btnW = 160
        local btnH = 34
        local btnX = attCardX + attCardW - btnW - 14
        local btnY = attCardY + 15
        
        local isBtnHovered = self.mouseX >= btnX and self.mouseX <= btnX + btnW and
                             self.mouseY >= btnY and self.mouseY <= btnY + btnH
        
        if isDownloaded then
            love.graphics.setColor(0.18, 0.65, 0.35, 0.9)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.font12)
            love.graphics.printf("✓ Saved in Downloads", btnX, btnY + 9, btnW, "center")
        else
            if isBtnHovered then
                love.graphics.setColor(0.0, 0.4, 0.75)
            else
                love.graphics.setColor(0.0, 0.47, 0.83)
            end
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.font12)
            love.graphics.printf("⬇ Download File", btnX, btnY + 9, btnW, "center")
        end
        
        self.attachmentButtonRect = {
            x = btnX,
            y = btnY,
            w = btnW,
            h = btnH,
            email = email,
            attachment = att,
            isDownloaded = isDownloaded
        }
    end
    
    love.graphics.setScissor()
    
    if self.maxScroll > 0 then
        local scrollbarWidth = 8
        local trackX = innerX + innerW - scrollbarWidth - 4
        local trackY = innerY + 4
        local trackHeight = innerH - 8
        
        local thumbHeight = math.max(30, (innerH / totalContentHeight) * trackHeight)
        local thumbY = trackY + (self.scrollOffset / self.maxScroll) * (trackHeight - thumbHeight)
        
        local isThumbHovered = self.mouseX >= trackX and self.mouseX <= trackX + scrollbarWidth and
                              self.mouseY >= thumbY and self.mouseY <= thumbY + thumbHeight
        
        love.graphics.setColor(0.93, 0.93, 0.94)
        love.graphics.rectangle("fill", trackX, trackY, scrollbarWidth, trackHeight, 4)
        
        if self.isDraggingScrollbar then
            love.graphics.setColor(0.5, 0.5, 0.5)
        elseif isThumbHovered then
            love.graphics.setColor(0.65, 0.65, 0.65)
        else
            love.graphics.setColor(0.8, 0.8, 0.8)
        end
        love.graphics.rectangle("fill", trackX, thumbY, scrollbarWidth, thumbHeight, 4)
    end
end

-- Helper check if file exists in FS
function TaskConditions_fileExists_check(targetPath)
    local fs = filesystem.getFS()
    if not fs then return false end
    targetPath = targetPath:gsub("^/", "")
    local parts = {}
    for part in targetPath:gmatch("[^/]+") do table.insert(parts, part) end
    local cur = fs
    for _, p in ipairs(parts) do
        if not cur.children or not cur.children[p] then return false end
        cur = cur.children[p]
    end
    return cur.type == "file"
end

function EmailApp:downloadAttachment(email, att)
    if not att then return end
    
    local fs = filesystem.getFS()
    -- Ensure home/user/Downloads exists
    local home = fs.children["home"]
    if not home then
        home = { name = "home", type = "directory", parent = fs, children = {} }
        fs.children["home"] = home
    end
    local user = home.children["user"]
    if not user then
        user = { name = "user", type = "directory", parent = home, children = {} }
        home.children["user"] = user
    end
    local downloads = user.children["Downloads"]
    if not downloads then
        downloads = { name = "Downloads", type = "directory", parent = user, children = {} }
        user.children["Downloads"] = downloads
    end
    
    -- Save file into Downloads directory
    downloads.children[att.filename] = {
        name = att.filename,
        type = "file",
        parent = downloads,
        content = att.content or "",
        created = os.time(),
        modified = os.time()
    }
    
    filesystem.save(fs)
    
    PlayerStats.setFlag("downloaded:" .. att.filename:lower(), true)
    PlayerStats.setFlag("email_downloaded:" .. tostring(email.id), true)
    
    AudioManager.playSFX("notification", 1.2)
    Notifications.add("Download Complete", "Saved '" .. att.filename .. "' to Downloads", nil, 5.0)
    
    EventBus.emit("email:attachment_downloaded", {
        filename = att.filename,
        emailId = email.id,
        path = "home/user/Downloads/" .. att.filename
    })
end

function EmailApp:mousepressed(mx, my, button)
    if button ~= 1 then return end
    self.mousePressed = true
    
    local isCompact = self.width < self.minWidthForDetail
    
    -- 1. Folder Click Handler
    local folderY = 55
    local itemHeight = 32
    for _, folder in ipairs(self.folders) do
        if self.mouseX >= 8 and self.mouseX <= self.sidebarWidth - 8 and
           self.mouseY >= folderY and self.mouseY <= folderY + itemHeight then
            self.activeFolder = folder.name
            self.showingDetailMobile = false
            self.listScrollOffset = 0
            self.selected = 1
            return
        end
        folderY = folderY + itemHeight + 2
    end
    
    -- Check Attachment download button click
    if self.attachmentButtonRect then
        local btn = self.attachmentButtonRect
        if self.mouseX >= btn.x and self.mouseX <= btn.x + btn.w and
           self.mouseY >= btn.y and self.mouseY <= btn.y + btn.h then
            self:downloadAttachment(btn.email, btn.attachment)
            return
        end
    end
    
    local leftRemainingWidth = self.width - self.sidebarWidth
    local padding = 8
    local visibleEmails = self:getVisibleEmails()
    
    if isCompact then
        if self.showingDetailMobile then
            local innerX = self.sidebarWidth
            local backButtonY = padding + 16
            if self.mouseY >= backButtonY - 5 and self.mouseY <= backButtonY + 25 and
               self.mouseX >= innerX + 16 and self.mouseX <= innerX + 80 then
                self.showingDetailMobile = false
                return
            end
            self:handleDetailInteractions(leftRemainingWidth, padding, visibleEmails)
        else
            local listWidth = leftRemainingWidth
            self:handleListInteractions(self.sidebarWidth, listWidth, padding, true, visibleEmails)
        end
    else
        local emailListWidth = math.floor(leftRemainingWidth * 0.42)
        local contentWidth = leftRemainingWidth - emailListWidth
        self:handleListInteractions(self.sidebarWidth, emailListWidth, padding, false, visibleEmails)
        self:handleDetailInteractions(contentWidth, padding, visibleEmails)
    end
end

function EmailApp:handleListInteractions(startX, listWidth, padding, isCompact, emails)
    local innerX = startX + padding
    local innerW = listWidth - (padding * 2)
    local innerY = padding
    
    local headerHeight = 40
    local rowHeight = 75
    local totalListHeight = headerHeight + (#emails * rowHeight)
    local innerH = self.height - (padding * 2)
    local listMaxScroll = math.max(0, totalListHeight - innerH)
    
    if listMaxScroll > 0 then
        local scrollbarWidth = 6
        local trackX = innerX + innerW - scrollbarWidth - 2
        local trackY = innerY + 2
        local trackHeight = innerH - 4
        
        if self.mouseX >= trackX and self.mouseX <= trackX + scrollbarWidth then
            local thumbHeight = math.max(30, (innerH / totalListHeight) * trackHeight)
            local thumbY = trackY + (self.listScrollOffset / listMaxScroll) * (trackHeight - thumbHeight)
            
            if self.mouseY >= thumbY and self.mouseY <= thumbY + thumbHeight then
                self.isDraggingListScrollbar = true
                self.listScrollDragOffset = self.mouseY - thumbY
                return
            else
                local targetFraction = (self.mouseY - trackY - (thumbHeight / 2)) / (trackHeight - thumbHeight)
                self.listScrollOffset = targetFraction * listMaxScroll
                self.listScrollOffset = math.max(0, math.min(self.listScrollOffset, listMaxScroll))
                return
            end
        end
    end
    
    if isCompact and self.showingDetailMobile then
        return
    end
    
    local rowY = innerY + headerHeight - self.listScrollOffset
    
    for i, email in ipairs(emails) do
        if self.mouseX >= innerX and self.mouseX <= innerX + innerW and
           self.mouseY >= rowY and self.mouseY <= rowY + rowHeight - 1 then
           
            if self.mouseX >= innerX + innerW - 30 and self.mouseX <= innerX + innerW - 5 then
                email.starred = not email.starred
            else
                self.selected = i
                email.unread = false
                self.scrollOffset = 0
                
                PlayerStats.setFlag("email_read:" .. tostring(email.id), true)
                if email.sender then
                    PlayerStats.setFlag("email_read_sender:" .. email.sender:lower(), true)
                end
                
                EventBus.emit("email:read", email)
                
                if isCompact then
                    self.showingDetailMobile = true
                end
            end
            return
        end
        rowY = rowY + rowHeight
    end
end

function EmailApp:handleDetailInteractions(detailWidth, padding, emails)
    local rx = self.width - detailWidth + padding
    local rw = detailWidth - padding * 2
    local rh = self.height - (padding * 2)
    
    local isCompact = self.width < self.minWidthForDetail
    local contentPadding = isCompact and 16 or 24
    local starY = padding + contentPadding
    
    if isCompact then
        starY = starY + 30
    end
    
    if self.mouseX >= rx + contentPadding and self.mouseX <= rx + contentPadding + 50 and
       self.mouseY >= starY + 5 and self.mouseY <= starY + 25 then
        local email = emails[self.selected]
        if email then 
            email.starred = not email.starred
            return
        end
    end
    
    if self.maxScroll > 0 then
        local scrollbarWidth = 8
        local trackX = rx + rw - scrollbarWidth - 4
        if self.mouseX >= trackX and self.mouseX <= trackX + scrollbarWidth then
            local trackHeight = rh - 8
            local email = emails[self.selected]
            if email then
                local textFont = self.font14
                local headerSize = 145
                local _, lines = textFont:getWrap(email.body, rw - (contentPadding * 2) - 20)
                local attachmentHeight = email.attachment and 80 or 0
                local totalContentHeight = headerSize + (#lines * textFont:getHeight()) + attachmentHeight + 60
                
                local thumbHeight = math.max(30, (rh / totalContentHeight) * trackHeight)
                local thumbY = (padding + 4) + (self.scrollOffset / self.maxScroll) * (trackHeight - thumbHeight)
                
                if self.mouseY >= thumbY and self.mouseY <= thumbY + thumbHeight then
                    self.isDraggingScrollbar = true
                    self.scrollDragOffset = self.mouseY - thumbY
                else
                    local targetFraction = (self.mouseY - (padding + 4) - (thumbHeight / 2)) / (trackHeight - thumbHeight)
                    self.scrollOffset = targetFraction * self.maxScroll
                    self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
                end
            end
        end
    end
end

function EmailApp:mousemoved(mx, my, dx, dy)
    self.mouseX = mx
    self.mouseY = my
    
    if self.isDraggingListScrollbar and self.listMaxScroll > 0 then
        local padding = 8
        local innerH = self.height - (padding * 2)
        local trackHeight = innerH - 4
        local visibleEmails = self:getVisibleEmails()
        local headerHeight = 40
        local rowHeight = 75
        local totalListHeight = headerHeight + (#visibleEmails * rowHeight)
        
        local thumbHeight = math.max(30, (innerH / totalListHeight) * trackHeight)
        local relativeY = self.mouseY - self.listScrollDragOffset - (padding + 2)
        
        local scrollFraction = relativeY / (trackHeight - thumbHeight)
        self.listScrollOffset = scrollFraction * self.listMaxScroll
        self.listScrollOffset = math.max(0, math.min(self.listScrollOffset, self.listMaxScroll))
    end
    
    if self.isDraggingScrollbar and self.maxScroll > 0 then
        local isCompact = self.width < self.minWidthForDetail
        local leftRemainingWidth = self.width - self.sidebarWidth
        local padding = 8
        
        local detailWidth = isCompact and leftRemainingWidth or (leftRemainingWidth - math.floor(leftRemainingWidth * 0.42))
        local rh = self.height - (padding * 2)
        local trackHeight = rh - 8
        
        local visibleEmails = self:getVisibleEmails()
        local email = visibleEmails[self.selected]
        if email then
            local contentPadding = isCompact and 16 or 24
            local textFont = self.font14
            local headerSize = 145
            local _, lines = textFont:getWrap(email.body, detailWidth - padding - (contentPadding * 2) - 20)
            local attachmentHeight = email.attachment and 80 or 0
            local totalContentHeight = headerSize + (#lines * textFont:getHeight()) + attachmentHeight + 60
            
            local thumbHeight = math.max(30, (rh / totalContentHeight) * trackHeight)
            local relativeY = self.mouseY - self.scrollDragOffset - (padding + 4)
            
            local scrollFraction = relativeY / (trackHeight - thumbHeight)
            self.scrollOffset = scrollFraction * self.maxScroll
            self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
        end
    end
end

function EmailApp:mousereleased(mx, my, button)
    self.mousePressed = false
    self.isDraggingScrollbar = false
    self.isDraggingListScrollbar = false
end

function EmailApp:wheelmoved(x, y)
    local isCompact = self.width < self.minWidthForDetail
    local leftRemainingWidth = self.width - self.sidebarWidth
    
    if isCompact then
        if self.showingDetailMobile then
            if self.maxScroll > 0 then
                self.scrollOffset = self.scrollOffset - (y * 30)
                self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
            end
        else
            if self.listMaxScroll > 0 then
                self.listScrollOffset = self.listScrollOffset - (y * 30)
                self.listScrollOffset = math.max(0, math.min(self.listScrollOffset, self.listMaxScroll))
            end
        end
    else
        local emailListWidth = math.floor(leftRemainingWidth * 0.42)
        local listEndX = self.sidebarWidth + emailListWidth
        
        if self.mouseX <= listEndX and self.mouseX >= self.sidebarWidth then
            if self.listMaxScroll > 0 then
                self.listScrollOffset = self.listScrollOffset - (y * 30)
                self.listScrollOffset = math.max(0, math.min(self.listScrollOffset, self.listMaxScroll))
            end
        elseif self.mouseX > listEndX then
            if self.maxScroll > 0 then
                self.scrollOffset = self.scrollOffset - (y * 30)
                self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
            end
        end
    end
end

function EmailApp:keypressed(key)
    local visibleEmails = self:getVisibleEmails()
    if key == "up" then
        self.selected = math.max(1, self.selected - 1)
        self.scrollOffset = 0
    elseif key == "down" then
        self.selected = math.min(#visibleEmails, self.selected + 1)
        self.scrollOffset = 0
    elseif key == "escape" then
        if self.width < self.minWidthForDetail then
            self.showingDetailMobile = false
        end
    end
end

function EmailApp:update(dt) end
function EmailApp:textinput(text) end

function EmailApp:resize(w, h)
    if self.width > 0 then
        local wasCompact = self.width < self.minWidthForDetail
        local isNowCompact = w < self.minWidthForDetail
        if wasCompact ~= isNowCompact then
            self.showingDetailMobile = false
        end
    end
end

return EmailApp