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
        {name = "Inbox", icon = "📥", count = 1},
        {name = "Starred", icon = "⭐"},
        {name = "Sent", icon = "📤"},
        {name = "Drafts", icon = "📝"}
    }
    
    -- Dimensions & Layout
    self.width = 0
    self.height = 0
    self.sidebarWidth = 160
    
    -- State Variables
    self.mouseX = -1
    self.mouseY = -1
    self.mousePressed = false
    
    -- Scroll properties for Email Detail View
    self.scrollOffset = 0
    self.maxScroll = 0
    self.isDraggingScrollbar = false
    self.scrollDragOffset = 0
    
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
    
    -- 2. Draw Left Sidebar (Folders & Gmail logo)
    self:drawSidebar()
    
    -- 3. Draw Split Panes (Inbox Middle List vs Right Detailed View)
    local leftRemainingWidth = width - self.sidebarWidth
    local emailListWidth = math.floor(leftRemainingWidth * 0.42)
    local contentWidth = leftRemainingWidth - emailListWidth
    
    self:drawEmailList(self.sidebarWidth, emailListWidth)
    self:drawEmailDetail(self.sidebarWidth + emailListWidth, contentWidth, x, y)
    
    love.graphics.pop()
end

function EmailApp:drawSidebar()
    -- Header / Logo Area
    love.graphics.setColor(self.colors.accentRed)
    love.graphics.rectangle("fill", 15, 12, 28, 20, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font12)
    love.graphics.printf("M", 15, 15, 28, "center")
    
    love.graphics.setColor(self.colors.primaryText)
    love.graphics.setFont(self.font16)
    love.graphics.print("Mail", 50, 13)
    
    -- Folder List
    local folderY = 55
    local itemHeight = 32
    love.graphics.setFont(self.font13)
    
    for _, folder in ipairs(self.folders) do
        local isSelected = self.activeFolder == folder.name
        local isHovered = self.mouseX >= 8 and self.mouseX <= self.sidebarWidth - 8 and
                          self.mouseY >= folderY and self.mouseY <= folderY + itemHeight
                          
        if isSelected then
            love.graphics.setColor(0.92, 0.2, 0.16, 0.12) -- Transparent red highlight
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
        love.graphics.print(folder.name, 45, folderY + 8)
        
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

function EmailApp:drawEmailList(startX, listWidth)
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
    
    -- Sub-header
    love.graphics.setColor(self.colors.secondaryText)
    love.graphics.setFont(self.font12)
    love.graphics.print("INBOX", innerX + 16, innerY + 16)
    
    -- Email Row Items
    local rowY = innerY + 40
    local rowHeight = 75
    
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
            love.graphics.setFont(self.font13) -- bold if native, fallback regular
        else
            love.graphics.setColor(self.colors.secondaryText)
            love.graphics.setFont(self.font13)
        end
        love.graphics.print(email.sender, innerX + 16, rowY + 10)
        
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
            love.graphics.print("-", innerX + innerW - 22, rowY + 36)
        end
        
        -- Subject Line
        love.graphics.setColor(self.colors.primaryText)
        love.graphics.setFont(self.font12)
        local dispSubject = email.subject
        if #dispSubject > 28 then dispSubject = string.sub(dispSubject, 1, 26) .. "..." end
        love.graphics.print(dispSubject, innerX + 16, rowY + 30)
        
        -- Body Excerpt snippet
        love.graphics.setColor(self.colors.secondaryText)
        love.graphics.setFont(self.font11)
        local bodyExcerpt = email.body:gsub("\n", " ")
        if #bodyExcerpt > 38 then bodyExcerpt = string.sub(bodyExcerpt, 1, 36) .. "..." end
        love.graphics.print(bodyExcerpt, innerX + 16, rowY + 48)
        
        rowY = rowY + rowHeight
    end
end

function EmailApp:drawEmailDetail(startX, detailWidth, absX, absY)
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
    local contentPadding = 24
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
    
    -- Subject title
    love.graphics.setColor(self.colors.primaryText)
    love.graphics.setFont(self.font20)
    love.graphics.printf(email.subject, innerX + contentPadding, drawY, readerWidth, "left")
    
    drawY = drawY + 45
    
    -- Star Action / Marker
    love.graphics.setFont(self.font16)
    if email.starred then
        love.graphics.setColor(0.95, 0.65, 0)
        love.graphics.print("★", innerX + contentPadding, drawY + 8)
    else
        love.graphics.setColor(0.75, 0.75, 0.75)
        love.graphics.print("☆", innerX + contentPadding, drawY + 8)
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
    love.graphics.print(email.sender, innerX + contentPadding + 65, drawY + 4)
    
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
    
    -- 1. Folder Click Handler
    local folderY = 55
    local itemHeight = 32
    for _, folder in ipairs(self.folders) do
        if self.mouseX >= 8 and self.mouseX <= self.sidebarWidth - 8 and
           self.mouseY >= folderY and self.mouseY <= folderY + itemHeight then
            self.activeFolder = folder.name
            return
        end
        folderY = folderY + itemHeight + 2
    end
    
    -- 2. Inbox List Click Handler
    local leftRemainingWidth = self.width - self.sidebarWidth
    local emailListWidth = math.floor(leftRemainingWidth * 0.42)
    local padding = 8
    local innerX = self.sidebarWidth + padding
    local innerW = emailListWidth - (padding * 2)
    
    local rowY = padding + 40
    local rowHeight = 75
    
    for i, email in ipairs(self.emails) do
        -- Check click inside row item
        if self.mouseX >= innerX and self.mouseX <= innerX + innerW and
           self.mouseY >= rowY and self.mouseY <= rowY + rowHeight - 1 then
           
            -- Dynamic click to Star inside email row
            if self.mouseX >= innerX + innerW - 30 and self.mouseX <= innerX + innerW - 5 then
                email.starred = not email.starred
            else
                self.selected = i
                email.unread = false
                self.scrollOffset = 0 -- Reset reading pane scroll on new mail select
            end
            return
        end
        rowY = rowY + rowHeight
    end
    
    -- 3. Detail Reading Scrollbar Click Drag
    local contentWidth = leftRemainingWidth - emailListWidth
    local rx = self.sidebarWidth + emailListWidth
    local rw = contentWidth - padding
    local rh = self.height - (padding * 2)
    
    if self.maxScroll > 0 then
        local scrollbarWidth = 8
        local trackX = rx + rw - scrollbarWidth - 4
        if self.mouseX >= trackX and self.mouseX <= trackX + scrollbarWidth then
            local trackHeight = rh - 8
            
            -- Recompute values to match rendering
            local textFont = self.font14
            local headerSize = 145
            local email = self.emails[self.selected]
            local _, lines = textFont:getWrap(email.body, rw - 48 - 20)
            local totalContentHeight = headerSize + (#lines * textFont:getHeight()) + 60
            
            local thumbHeight = math.max(30, (rh / totalContentHeight) * trackHeight)
            local thumbY = (padding + 4) + (self.scrollOffset / self.maxScroll) * (trackHeight - thumbHeight)
            
            if self.mouseY >= thumbY and self.mouseY <= thumbY + thumbHeight then
                self.isDraggingScrollbar = true
                self.scrollDragOffset = self.mouseY - thumbY
            else
                -- Scroll directly jumping to cursor
                local targetFraction = (self.mouseY - (padding + 4) - (thumbHeight / 2)) / (trackHeight - thumbHeight)
                self.scrollOffset = targetFraction * self.maxScroll
                self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
            end
            return
        end
    end
    
    -- Interactive star click in detailed reading view
    local starY = padding + 24 + 45
    if self.mouseX >= rx + 24 and self.mouseX <= rx + 50 and
       self.mouseY >= starY + 5 and self.mouseY <= starY + 25 then
        local email = self.emails[self.selected]
        if email then email.starred = not email.starred end
    end
end

function EmailApp:mousemoved(mx, my, dx, dy)
    self.mouseX = mx
    self.mouseY = my
    
    -- Handle scrollbar dragging calculations
    if self.isDraggingScrollbar and self.maxScroll > 0 then
        local leftRemainingWidth = self.width - self.sidebarWidth
        local emailListWidth = math.floor(leftRemainingWidth * 0.42)
        local contentWidth = leftRemainingWidth - emailListWidth
        
        local padding = 8
        local rh = self.height - (padding * 2)
        local trackHeight = rh - 8
        
        -- Recompute content bounds
        local textFont = self.font14
        local headerSize = 145
        local email = self.emails[self.selected]
        local _, lines = textFont:getWrap(email.body, contentWidth - padding - 48 - 20)
        local totalContentHeight = headerSize + (#lines * textFont:getHeight()) + 60
        
        local thumbHeight = math.max(30, (rh / totalContentHeight) * trackHeight)
        local relativeY = self.mouseY - self.scrollDragOffset - (padding + 4)
        
        local scrollFraction = relativeY / (trackHeight - thumbHeight)
        self.scrollOffset = scrollFraction * self.maxScroll
        self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
    end
end

function EmailApp:mousereleased(mx, my, button)
    self.mousePressed = false
    self.isDraggingScrollbar = false
end

function EmailApp:wheelmoved(x, y)
    -- Zoom / Scroll reading panel on wheel scroll
    if self.maxScroll > 0 then
        self.scrollOffset = self.scrollOffset - (y * 30)
        self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
    end
end

function EmailApp:keypressed(key)
    if key == "up" then
        self.selected = math.max(1, self.selected - 1)
        self.scrollOffset = 0
    elseif key == "down" then
        self.selected = math.min(#self.emails, self.selected + 1)
        self.scrollOffset = 0
    end
end

function EmailApp:update(dt) end
function EmailApp:textinput(text) end
function EmailApp:resize(w, h) end

return EmailApp