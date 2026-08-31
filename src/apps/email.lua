-- email.lua
local EmailApp = {}
EmailApp.__index = EmailApp

function EmailApp.new()
    local self = setmetatable({}, EmailApp)
    self.font10 = love.graphics.newFont(10)
    self.font11 = love.graphics.newFont(11)
    self.font12 = love.graphics.newFont(12)
    self.font13 = love.graphics.newFont(13)
    self.font14 = love.graphics.newFont(14)
    self.font16 = love.graphics.newFont(16)
    self.font20 = love.graphics.newFont(20)
    
    -- Mock Email Data
    self.emails = {
        {
            id = 1,
            subject = "Welcome to Our Workspace",
            sender = "Goooole Workspace Team",
            email = "workspace-noreply@Goooole.com",
            time = "9:41 AM",
            body = "Welcome to your new inbox!\n\nWe are excited to have you on board. Discover new integrations, customized shortcuts, and smart search queries designed to make your development workflow seamless.",
            unread = true,
            starred = false
        },
        {
            id = 2,
            subject = "Urgent: Project status review & code freeze",
            sender = "Tech Lead",
            email = "boss@company.com",
            time = "Yesterday",
            body = "Hi Team,\n\nJust a reminder that our code freeze starts tonight at 10:00 PM. Please ensure all pull requests are reviewed, approved, and merged before then.\n\nMeeting at 10 AM in Conference Room A for status updates.",
            unread = false,
            starred = true
        },
        {
            id = 3,
            subject = "Weekly Newsletter: The Love2D & Lua Roadmap",
            sender = "Lua Weekly",
            email = "news@lua-weekly.org",
            time = "May 4",
            body = "Here's what happened this week in game dev & systems programming:\n\n1. Love2D release candidates and performance boosts.\n2. Writing a modern UI with pure canvas rendering.\n3. Tips on avoiding coordinate transformations bugs.\n\nKeep on coding!",
            unread = false,
            starred = false
        },
        {
            id = 4,
            subject = "Your Firebase Authentication Config update",
            sender = "Firebase",
            email = "no-reply@firebase.Goooole.com",
            time = "Apr 28",
            body = "Your Firebase project database security rules have been updated successfully.\n\nIf you did not authorize this change, please check your Firebase console security settings immediately and update your administrative credentials.",
            unread = false,
            starred = false
        },
        {
            id = 5,
            subject = "Meeting Notes: Q2 Planning",
            sender = "Project Manager",
            email = "pm@company.com",
            time = "Apr 27",
            body = "Here are the notes from our Q2 planning meeting.\n\nKey points:\n- Launch timeline adjusted\n- New feature priorities set\n- Team capacity reviewed",
            unread = false,
            starred = false
        },
        {
            id = 6,
            subject = "Your invoice is ready",
            sender = "Billing System",
            email = "billing@company.com",
            time = "Apr 26",
            body = "Your monthly invoice has been generated and is ready for review.\n\nAmount: $299.99\nDue Date: May 15, 2026",
            unread = true,
            starred = false
        },
        {
            id = 7,
            subject = "System maintenance scheduled",
            sender = "IT Department",
            email = "it@company.com",
            time = "Apr 25",
            body = "We will be performing system maintenance this weekend.\n\nDowntime: Saturday 2 AM - 6 AM EST\nAffected services: All internal tools",
            unread = false,
            starred = false
        }
    }
    
    -- UI Theme Colors (Gmail Style)
    self.colors = {
        bg = {0.96, 0.97, 0.98},            -- Light grayish blue outer background
        paneBg = {1, 1, 1},                 -- White cards
        primaryText = {0.12, 0.12, 0.13},   -- Near black
        secondaryText = {0.36, 0.38, 0.41}, -- Slate grey
        accentRed = {0.85, 0.18, 0.14},     -- Gmail Red
        accentBlueHover = {0.93, 0.95, 0.99},-- Selection hover blue
        border = {0.88, 0.89, 0.91}         -- Soft border separator
    }
    
    self.selected = 1
    self.activeFolder = "Inbox"
    self.folders = {
        {name = "Inbox", icon = "i", count = 2},
        {name = "Starred", icon = "*"},
        {name = "Sent", icon = "v"},
        {name = "Drafts", icon = "#"}
    }
    
    -- Dimensions & Layout
    self.width = 0
    self.height = 0
    self.sidebarWidth = 120
    self.minWidthForDetail = 700 -- Threshold for showing detail pane
    
    -- State Variables
    self.mouseX = -1
    self.mouseY = -1
    self.mousePressed = false
    self.showingDetailMobile = false -- Track if showing detail on mobile
    
    -- Scroll properties for Email Detail View
    self.scrollOffset = 0
    self.maxScroll = 0
    self.isDraggingScrollbar = false
    self.scrollDragOffset = 0
    
    -- Scroll properties for Email List View
    self.listScrollOffset = 0
    self.listMaxScroll = 0
    self.isDraggingListScrollbar = false
    self.listScrollDragOffset = 0
    
    return self
end

function EmailApp:draw(x, y, width, height)
    self.width = width
    self.height = height
    
    -- Push transformation to render everything using relative coordinates
    love.graphics.push()
    love.graphics.translate(x, y)
    
    -- 1. Outer App Background
    love.graphics.setColor(self.colors.bg)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Determine if we're in compact mode
    local isCompact = width < self.minWidthForDetail
    
    -- 2. Draw Left Sidebar (Folders & Gmail logo)
    self:drawSidebar(isCompact)
    
    -- 3. Draw Split Panes based on mode
    local leftRemainingWidth = width - self.sidebarWidth
    
    if isCompact then
        -- Compact mode: Show either list or detail, not both
        if self.showingDetailMobile then
            self:drawEmailDetail(self.sidebarWidth, leftRemainingWidth, x, y, true)
        else
            self:drawEmailList(self.sidebarWidth, leftRemainingWidth, x, y, true)
        end
    else
        -- Full mode: Show both panes
        local emailListWidth = math.floor(leftRemainingWidth * 0.42)
        local contentWidth = leftRemainingWidth - emailListWidth
        
        self:drawEmailList(self.sidebarWidth, emailListWidth, x, y, false)
        self:drawEmailDetail(self.sidebarWidth + emailListWidth, contentWidth, x, y, false)
    end
    
    love.graphics.pop()
end

function EmailApp:drawSidebar(isCompact)
    -- Header / Logo Area
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
    
    -- Folder List
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
        
        -- Icon and text
        love.graphics.print(folder.icon, 20, folderY + 8)
        love.graphics.print(folder.name, 35, folderY + 8)
        
        -- Badge count
        if folder.count and folder.count > 0 then
            love.graphics.setColor(self.colors.secondaryText)
            love.graphics.setFont(self.font11)
            love.graphics.printf(tostring(folder.count), self.sidebarWidth - 35, folderY + 9, 20, "right")
            love.graphics.setFont(self.font13)
        end
        
        folderY = folderY + itemHeight + 2
    end
end

function EmailApp:drawEmailList(startX, listWidth, absX, absY, isCompact)
    -- Content Card container
    local padding = 8
    local innerX = startX + padding
    local innerY = padding
    local innerW = listWidth - (padding * 2)
    local innerH = self.height - (padding * 2)
    
    love.graphics.setColor(self.colors.paneBg)
    love.graphics.rectangle("fill", innerX, innerY, innerW, innerH, 8)
    
    love.graphics.setColor(self.colors.border)
    love.graphics.rectangle("line", innerX, innerY, innerW, innerH, 8)
    
    -- Calculate list scroll properties
    local headerHeight = 40
    local rowHeight = 75
    local totalListHeight = headerHeight + (#self.emails * rowHeight)
    self.listMaxScroll = math.max(0, totalListHeight - innerH)
    self.listScrollOffset = math.max(0, math.min(self.listScrollOffset, self.listMaxScroll))
    
    -- Render list content with scissor
    love.graphics.setScissor(absX + innerX, absY + innerY, innerW, innerH)
    
    -- Sub-header (fixed)
    local drawY = innerY + 16 - self.listScrollOffset
    
    love.graphics.setColor(self.colors.secondaryText)
    love.graphics.setFont(self.font12)
    
    if isCompact and self.showingDetailMobile then
        -- Back button for mobile
        love.graphics.print("Back", innerX + 16, drawY)
    else
        love.graphics.print("INBOX", innerX + 16, drawY)
    end
    
    -- Email Row Items
    local rowY = innerY + headerHeight - self.listScrollOffset
    
    for i, email in ipairs(self.emails) do
        local isSelected = i == self.selected
        local isHovered = self.mouseX >= innerX and self.mouseX <= innerX + innerW and
                          self.mouseY >= rowY and self.mouseY <= rowY + rowHeight - 1
                          
        -- Row Background
        if isSelected then
            love.graphics.setColor(self.colors.accentBlueHover)
            love.graphics.rectangle("fill", innerX + 2, rowY, innerW - 4, rowHeight - 2, 4)
        elseif isHovered then
            love.graphics.setColor(0.97, 0.97, 0.98)
            love.graphics.rectangle("fill", innerX + 2, rowY, innerW - 4, rowHeight - 2, 4)
        end
        
        -- Border Bottom separator
        love.graphics.setColor(self.colors.border)
        love.graphics.line(innerX + 12, rowY + rowHeight - 1, innerX + innerW - 12, rowY + rowHeight - 1)
        
        -- Sender Title
        if email.unread then
            love.graphics.setColor(self.colors.primaryText)
            love.graphics.setFont(self.font13)
        else
            love.graphics.setColor(self.colors.secondaryText)
            love.graphics.setFont(self.font13)
        end
        
        -- Truncate sender name for compact mode
        local senderName = email.sender
        if isCompact and #senderName > 20 then
            senderName = string.sub(senderName, 1, 18) .. "..."
        end
        love.graphics.print(senderName, innerX + 16, rowY + 10)
        
        -- Time stamp
        love.graphics.setColor(self.colors.secondaryText)
        love.graphics.setFont(self.font11)
        love.graphics.printf(email.time, innerX + innerW - 80, rowY + 12, 65, "right")
        
        -- Star status
        love.graphics.setFont(self.font12)
        if email.starred then
            love.graphics.setColor(0.95, 0.65, 0)
            love.graphics.print("*", innerX + innerW - 22, rowY + 36)
        else
            love.graphics.setColor(0.75, 0.75, 0.75)
            love.graphics.print("*", innerX + innerW - 22, rowY + 36)
        end
        
        -- Subject Line
        love.graphics.setColor(self.colors.primaryText)
        love.graphics.setFont(self.font12)
        local maxSubjectLen = isCompact and 22 or 28
        local dispSubject = email.subject
        if #dispSubject > maxSubjectLen then dispSubject = string.sub(dispSubject, 1, maxSubjectLen - 2) .. "..." end
        love.graphics.print(dispSubject, innerX + 16, rowY + 30)
        
        -- Body Excerpt snippet
        love.graphics.setColor(self.colors.secondaryText)
        love.graphics.setFont(self.font11)
        local bodyExcerpt = email.body:gsub("\n", " ")
        local maxBodyLen = isCompact and 30 or 38
        if #bodyExcerpt > maxBodyLen then bodyExcerpt = string.sub(bodyExcerpt, 1, maxBodyLen - 2) .. "..." end
        love.graphics.print(bodyExcerpt, innerX + 16, rowY + 48)
        
        rowY = rowY + rowHeight
    end
    
    love.graphics.setScissor() -- clear scissor viewport
    
    -- Draw scrollbar for email list
    if self.listMaxScroll > 0 then
        local scrollbarWidth = 6
        local trackX = innerX + innerW - scrollbarWidth - 2
        local trackY = innerY + 2
        local trackHeight = innerH - 4
        
        local thumbHeight = math.max(30, (innerH / totalListHeight) * trackHeight)
        local thumbY = trackY + (self.listScrollOffset / self.listMaxScroll) * (trackHeight - thumbHeight)
        
        local isThumbHovered = self.mouseX >= trackX and self.mouseX <= trackX + scrollbarWidth and
                              self.mouseY >= thumbY and self.mouseY <= thumbY + thumbHeight
        
        -- Track
        love.graphics.setColor(0.93, 0.93, 0.94)
        love.graphics.rectangle("fill", trackX, trackY, scrollbarWidth, trackHeight, 3)
        
        -- Thumb
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

function EmailApp:drawEmailDetail(startX, detailWidth, absX, absY, isCompact)
    local padding = 8
    local innerX = startX
    local innerY = padding
    local innerW = detailWidth - padding
    local innerH = self.height - (padding * 2)
    
    -- Content Card Container
    love.graphics.setColor(self.colors.paneBg)
    love.graphics.rectangle("fill", innerX, innerY, innerW, innerH, 8)
    
    love.graphics.setColor(self.colors.border)
    love.graphics.rectangle("line", innerX, innerY, innerW, innerH, 8)
    
    local email = self.emails[self.selected]
    if not email then
        love.graphics.setColor(self.colors.secondaryText)
        love.graphics.setFont(self.font14)
        love.graphics.printf("No conversation selected", innerX, innerY + (innerH/2) - 10, innerW, "center")
        return
    end
    
    -- Layout margins inside the detailed reader
    local contentPadding = isCompact and 16 or 24
    local readerWidth = innerW - (contentPadding * 2)
    
    -- Dynamic height calculation for Scrollbar
    local textFont = self.font14
    local headerSize = 145
    local _, lines = textFont:getWrap(email.body, readerWidth - 20)
    local totalContentHeight = headerSize + (#lines * textFont:getHeight()) + 60
    
    self.maxScroll = math.max(0, totalContentHeight - innerH)
    self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
    
    -- Render Pane content safely using Scissor
    love.graphics.setScissor(absX + innerX, absY + innerY, innerW - 14, innerH)
    
    local drawY = innerY + contentPadding - self.scrollOffset
    
    -- Back button for compact mode
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
    
    -- Star Action / Marker
    love.graphics.setFont(self.font16)
    if email.starred then
        love.graphics.setColor(0.95, 0.65, 0)
        love.graphics.print("*", innerX + contentPadding, drawY + 8)
    else
        love.graphics.setColor(0.75, 0.75, 0.75)
        love.graphics.print("*", innerX + contentPadding, drawY + 8)
    end
    
    -- Sender avatar circle
    love.graphics.setColor(0.88, 0.92, 0.98)
    love.graphics.circle("fill", innerX + contentPadding + 40, drawY + 18, 16)
    love.graphics.setColor(self.colors.accentRed)
    love.graphics.setFont(self.font12)
    love.graphics.printf(string.upper(string.sub(email.sender, 1, 1)), innerX + contentPadding + 24, drawY + 12, 32, "center")
    
    -- Sender detail metadata
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
    drawY = drawY + 25
    love.graphics.setColor(self.colors.primaryText)
    love.graphics.setFont(textFont)
    love.graphics.printf(email.body, innerX + contentPadding, drawY, readerWidth - 20, "left")
    
    love.graphics.setScissor() -- clear scissor viewport
    
    -- Draw Custom interactive Scrollbar
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

-- ================= INTERACTION SYSTEMS =================

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
            return
        end
        folderY = folderY + itemHeight + 2
    end
    
    -- Get layout dimensions
    local leftRemainingWidth = self.width - self.sidebarWidth
    local padding = 8
    
    if isCompact then
        if self.showingDetailMobile then
            -- Check for back button in detail view
            local innerX = self.sidebarWidth
            local backButtonY = padding + 16
            if self.mouseY >= backButtonY - 5 and self.mouseY <= backButtonY + 25 and
               self.mouseX >= innerX + 16 and self.mouseX <= innerX + 80 then
                self.showingDetailMobile = false
                return
            end
            
            -- Handle detail interactions in compact mode
            self:handleDetailInteractions(leftRemainingWidth, padding)
        else
            -- Handle list interactions in compact mode
            local listWidth = leftRemainingWidth
            self:handleListInteractions(self.sidebarWidth, listWidth, padding, true)
        end
    else
        -- Full mode interactions
        local emailListWidth = math.floor(leftRemainingWidth * 0.42)
        local contentWidth = leftRemainingWidth - emailListWidth
        
        -- Handle list interactions
        self:handleListInteractions(self.sidebarWidth, emailListWidth, padding, false)
        
        -- Handle detail interactions
        self:handleDetailInteractions(contentWidth, padding)
    end
end

function EmailApp:handleListInteractions(startX, listWidth, padding, isCompact)
    local innerX = startX + padding
    local innerW = listWidth - (padding * 2)
    local innerY = padding
    
    -- Check for list scrollbar interaction first
    local headerHeight = 40
    local rowHeight = 75
    local totalListHeight = headerHeight + (#self.emails * rowHeight)
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
                -- Jump to position
                local targetFraction = (self.mouseY - trackY - (thumbHeight / 2)) / (trackHeight - thumbHeight)
                self.listScrollOffset = targetFraction * listMaxScroll
                self.listScrollOffset = math.max(0, math.min(self.listScrollOffset, listMaxScroll))
                return
            end
        end
    end
    
    -- Check back button in compact mode
    if isCompact and self.showingDetailMobile then
        if self.mouseX >= innerX + 16 and self.mouseX <= innerX + 80 and
           self.mouseY >= innerY + 16 - 5 and self.mouseY <= innerY + 16 + 25 then
            self.showingDetailMobile = false
            return
        end
        return
    end
    
    local rowY = innerY + headerHeight - self.listScrollOffset
    
    for i, email in ipairs(self.emails) do
        if self.mouseX >= innerX and self.mouseX <= innerX + innerW and
           self.mouseY >= rowY and self.mouseY <= rowY + rowHeight - 1 then
           
            -- Dynamic click to Star inside email row
            if self.mouseX >= innerX + innerW - 30 and self.mouseX <= innerX + innerW - 5 then
                email.starred = not email.starred
            else
                self.selected = i
                email.unread = false
                self.scrollOffset = 0
                
                -- In compact mode, switch to detail view
                if isCompact then
                    self.showingDetailMobile = true
                end
            end
            return
        end
        rowY = rowY + rowHeight
    end
end

function EmailApp:handleDetailInteractions(detailWidth, padding)
    local rx = self.width - detailWidth + padding
    local rw = detailWidth - padding * 2
    local rh = self.height - (padding * 2)
    
    -- Check for star toggle in detail view
    local isCompact = self.width < self.minWidthForDetail
    local contentPadding = isCompact and 16 or 24
    local starY = padding + contentPadding
    
    if isCompact then
        starY = starY + 30 -- Account for back button
    end
    
    if self.mouseX >= rx + contentPadding and self.mouseX <= rx + contentPadding + 50 and
       self.mouseY >= starY + 5 and self.mouseY <= starY + 25 then
        local email = self.emails[self.selected]
        if email then 
            email.starred = not email.starred
            return
        end
    end
    
    -- Scrollbar interaction
    if self.maxScroll > 0 then
        local scrollbarWidth = 8
        local trackX = rx + rw - scrollbarWidth - 4
        if self.mouseX >= trackX and self.mouseX <= trackX + scrollbarWidth then
            local trackHeight = rh - 8
            
            local textFont = self.font14
            local headerSize = 145
            local email = self.emails[self.selected]
            if email then
                local _, lines = textFont:getWrap(email.body, rw - (contentPadding * 2) - 20)
                local totalContentHeight = headerSize + (#lines * textFont:getHeight()) + 60
                
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
    
    -- Handle list scrollbar dragging
    if self.isDraggingListScrollbar and self.listMaxScroll > 0 then
        local padding = 8
        local innerH = self.height - (padding * 2)
        local trackHeight = innerH - 4
        
        local headerHeight = 40
        local rowHeight = 75
        local totalListHeight = headerHeight + (#self.emails * rowHeight)
        
        local thumbHeight = math.max(30, (innerH / totalListHeight) * trackHeight)
        local relativeY = self.mouseY - self.listScrollDragOffset - (padding + 2)
        
        local scrollFraction = relativeY / (trackHeight - thumbHeight)
        self.listScrollOffset = scrollFraction * self.listMaxScroll
        self.listScrollOffset = math.max(0, math.min(self.listScrollOffset, self.listMaxScroll))
    end
    
    -- Handle detail scrollbar dragging
    if self.isDraggingScrollbar and self.maxScroll > 0 then
        local isCompact = self.width < self.minWidthForDetail
        local leftRemainingWidth = self.width - self.sidebarWidth
        local padding = 8
        
        local detailWidth
        if isCompact then
            detailWidth = leftRemainingWidth
        else
            local emailListWidth = math.floor(leftRemainingWidth * 0.42)
            detailWidth = leftRemainingWidth - emailListWidth
        end
        
        local rh = self.height - (padding * 2)
        local trackHeight = rh - 8
        
        local contentPadding = isCompact and 16 or 24
        local textFont = self.font14
        local headerSize = 145
        local email = self.emails[self.selected]
        if email then
            local _, lines = textFont:getWrap(email.body, detailWidth - padding - (contentPadding * 2) - 20)
            local totalContentHeight = headerSize + (#lines * textFont:getHeight()) + 60
            
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
    -- Determine which panel to scroll based on mouse position
    local isCompact = self.width < self.minWidthForDetail
    local leftRemainingWidth = self.width - self.sidebarWidth
    
    if isCompact then
        if self.showingDetailMobile then
            -- Scroll detail view
            if self.maxScroll > 0 then
                self.scrollOffset = self.scrollOffset - (y * 30)
                self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
            end
        else
            -- Scroll list view
            if self.listMaxScroll > 0 then
                self.listScrollOffset = self.listScrollOffset - (y * 30)
                self.listScrollOffset = math.max(0, math.min(self.listScrollOffset, self.listMaxScroll))
            end
        end
    else
        -- Full mode: scroll based on which panel mouse is over
        local emailListWidth = math.floor(leftRemainingWidth * 0.42)
        local listEndX = self.sidebarWidth + emailListWidth
        
        if self.mouseX <= listEndX and self.mouseX >= self.sidebarWidth then
            -- Mouse is over list panel
            if self.listMaxScroll > 0 then
                self.listScrollOffset = self.listScrollOffset - (y * 30)
                self.listScrollOffset = math.max(0, math.min(self.listScrollOffset, self.listMaxScroll))
            end
        elseif self.mouseX > listEndX then
            -- Mouse is over detail panel
            if self.maxScroll > 0 then
                self.scrollOffset = self.scrollOffset - (y * 30)
                self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
            end
        end
    end
end

function EmailApp:keypressed(key)
    if key == "up" then
        self.selected = math.max(1, self.selected - 1)
        self.scrollOffset = 0
        -- Auto-scroll list to show selected item
        local rowHeight = 75
        local headerHeight = 40
        local targetY = headerHeight + (self.selected - 1) * rowHeight
        if targetY < self.listScrollOffset then
            self.listScrollOffset = targetY
        elseif targetY + rowHeight > self.listScrollOffset + self.height - 16 then
            self.listScrollOffset = targetY + rowHeight - self.height + 16
        end
    elseif key == "down" then
        self.selected = math.min(#self.emails, self.selected + 1)
        self.scrollOffset = 0
        -- Auto-scroll list to show selected item
        local rowHeight = 75
        local headerHeight = 40
        local targetY = headerHeight + (self.selected - 1) * rowHeight
        if targetY < self.listScrollOffset then
            self.listScrollOffset = targetY
        elseif targetY + rowHeight > self.listScrollOffset + self.height - 16 then
            self.listScrollOffset = targetY + rowHeight - self.height + 16
        end
    elseif key == "escape" then
        -- Back button functionality for compact mode
        if self.width < self.minWidthForDetail then
            self.showingDetailMobile = false
        end
    end
end

function EmailApp:update(dt) end
function EmailApp:textinput(text) end

function EmailApp:resize(w, h)
    -- Reset detail view when switching modes
    if self.width > 0 then
        local wasCompact = self.width < self.minWidthForDetail
        local isNowCompact = w < self.minWidthForDetail
        
        if wasCompact ~= isNowCompact then
            self.showingDetailMobile = false
        end
    end
end

return EmailApp