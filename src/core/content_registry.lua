-- src/core/content_registry.lua
-- Centralized system for dynamic story content injection

local EventBus = require("src.core.event_bus")
local PlayerStats = require("src.core.player_stats")
local Notifications = require("src.desktop.notifications")
local AudioManager = require("src.core.audio_manager")

local ContentRegistry = {
    -- Pending content that hasn't been injected yet
    pendingEmails = {},
    pendingChatMessages = {},
    pendingFiles = {},
    pendingNotifications = {},
    pendingTasks = {},
    
    -- Track what's been injected (metadata)
    injected = {
        emails = {},      -- id -> true
        chatMessages = {},
        files = {},
        notifications = {},
        tasks = {}
    },
    
    -- Store actual email data for new app instances to load
    injectedEmailData = {},  -- id -> emailData table
    
    -- Flag to prevent recursion
    _checking = false
}

function ContentRegistry.init()
    ContentRegistry.pendingEmails = {}
    ContentRegistry.pendingChatMessages = {}
    ContentRegistry.pendingFiles = {}
    ContentRegistry.pendingNotifications = {}
    ContentRegistry.pendingTasks = {}
    ContentRegistry.injected = {
        emails = {},
        chatMessages = {},
        files = {},
        notifications = {},
        tasks = {}
    }
    ContentRegistry.injectedEmailData = {}
    ContentRegistry._checking = false
end

-- Register content to be injected when a flag is set
-- Supports both single items and arrays
function ContentRegistry.registerOnFlag(flagName, content)
    if not ContentRegistry.pendingEmails[flagName] then
        ContentRegistry.pendingEmails[flagName] = {}
    end
    
    -- If content is a table with an 'id' field, it's a single email
    if content.id then
        table.insert(ContentRegistry.pendingEmails[flagName], content)
    -- If content is a table and the first element has an 'id', it's an array
    elseif type(content) == "table" and #content > 0 and content[1].id then
        for _, item in ipairs(content) do
            table.insert(ContentRegistry.pendingEmails[flagName], item)
        end
    else
        -- For other types (chat messages, etc.), store as-is
        if not ContentRegistry.pendingChatMessages[flagName] then
            ContentRegistry.pendingChatMessages[flagName] = {}
        end
        if type(content) == "table" and #content > 0 then
            for _, item in ipairs(content) do
                table.insert(ContentRegistry.pendingChatMessages[flagName], item)
            end
        else
            table.insert(ContentRegistry.pendingChatMessages[flagName], content)
        end
    end
end

-- Register chat messages
function ContentRegistry.registerChatOnFlag(flagName, messages)
    if not ContentRegistry.pendingChatMessages[flagName] then
        ContentRegistry.pendingChatMessages[flagName] = {}
    end
    if type(messages) == "table" and #messages > 0 then
        for _, msg in ipairs(messages) do
            table.insert(ContentRegistry.pendingChatMessages[flagName], msg)
        end
    else
        table.insert(ContentRegistry.pendingChatMessages[flagName], messages)
    end
end

-- Check and inject content when flags change
function ContentRegistry.checkFlags()
    if ContentRegistry._checking then return end
    ContentRegistry._checking = true
    
    -- Check for pending emails
    for flagName, emails in pairs(ContentRegistry.pendingEmails) do
        if PlayerStats.getFlag(flagName) then
            for _, emailData in ipairs(emails) do
                if not ContentRegistry.injected.emails[emailData.id] then
                    print("[ContentRegistry] Injecting email: " .. emailData.subject)
                    ContentRegistry.injectEmail(emailData)
                    ContentRegistry.injected.emails[emailData.id] = true
                end
            end
            ContentRegistry.pendingEmails[flagName] = nil
        end
    end
    
    -- Check for pending chat messages
    for flagName, messages in pairs(ContentRegistry.pendingChatMessages) do
        if PlayerStats.getFlag(flagName) then
            for _, msgData in ipairs(messages) do
                local key = (msgData.userId or "unknown") .. "_" .. (msgData.timestamp or os.time())
                if not ContentRegistry.injected.chatMessages[key] then
                    print("[ContentRegistry] Injecting chat message for user: " .. (msgData.senderName or "unknown"))
                    ContentRegistry.injectChatMessage(msgData)
                    ContentRegistry.injected.chatMessages[key] = true
                end
            end
            ContentRegistry.pendingChatMessages[flagName] = nil
        end
    end
    
    ContentRegistry._checking = false
end

function ContentRegistry.injectEmail(emailData)
    -- Emit event for currently open email app instances
    EventBus.emit("email:incoming", emailData)
    -- Store for future instances
    ContentRegistry.injectedEmailData[emailData.id] = emailData
end

function ContentRegistry.injectChatMessage(msgData)
    -- Emit event for chat app
    EventBus.emit("chat:incoming", msgData)
end

-- Get all injected email data (for new app instances)
function ContentRegistry.getInjectedEmailData()
    local result = {}
    for id, data in pairs(ContentRegistry.injectedEmailData) do
        table.insert(result, data)
    end
    -- Sort by id descending (newest first)
    table.sort(result, function(a, b) return (a.id or 0) > (b.id or 0) end)
    return result
end

-- Force check all flags (useful after loading save)
function ContentRegistry.forceCheck()
    ContentRegistry._checking = false
    ContentRegistry.checkFlags()
end

return ContentRegistry