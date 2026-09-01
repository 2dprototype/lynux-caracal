-- src/desktop/notifications.lua
-- Windows 10 Style Toast Notifications (Action Center Popup) - Light theme

local AudioManager = require("src.core.audio_manager")
local Viewport = require("src.core.viewport")

local Notifications = {
    list = {},
    maxCount = 4,
    font = nil,
    smallFont = nil
}

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

function Notifications.init()
    Notifications.list = {}
    Notifications.font = loadCustomFont("font/IBMPlexSans-Bold.ttf", 14) or loadCustomFont("font/Nunito-Regular.ttf", 14)
    Notifications.smallFont = loadCustomFont("font/Nunito-Regular.ttf", 12)
end

function Notifications.add(title, message, icon, duration, onClick)
    local notif = {
        id = love.timer.getTime() + math.random(),
        title = title or "System Notification",
        message = message or "",
        icon = icon,
        timer = 0,
        duration = duration or 4.5,
        onClick = onClick,
        alpha = 0,
        height = 60,
        width = 280
    }
    table.insert(Notifications.list, 1, notif)
    if #Notifications.list > Notifications.maxCount then
        table.remove(Notifications.list)
    end
    AudioManager.playSFX("notification")
    return notif
end

function Notifications.update(dt)
    for i = #Notifications.list, 1, -1 do
        local n = Notifications.list[i]
        n.timer = n.timer + dt
        
        if n.timer < 0.25 then
            n.alpha = n.timer / 0.25
        elseif n.timer > n.duration - 0.4 then
            n.alpha = math.max(0, (n.duration - n.timer) / 0.4)
        else
            n.alpha = 1.0
        end

        if n.timer >= n.duration then
            table.remove(Notifications.list, i)
        end
    end
end

function Notifications.mousepressed(x, y, button)
    if button ~= 1 then return false end
    local screenW, screenH = Viewport.getWidth(), Viewport.getHeight()
    local marginX = 16
    local startY = screenH - 45 -- Above bottom taskbar
    local currentY = startY

    for i, n in ipairs(Notifications.list) do
        local notifX = screenW - n.width - marginX
        local notifY = currentY - n.height
        if x >= notifX and x <= notifX + n.width and y >= notifY and y <= notifY + n.height then
            if n.onClick then
                n.onClick(n)
            end
            table.remove(Notifications.list, i)
            AudioManager.playSFX("click")
            return true
        end
        currentY = currentY - n.height - 8
    end
    return false
end

function Notifications.draw()
    local screenW, screenH = Viewport.getWidth(), Viewport.getHeight()
    local marginX = 16
    local startY = screenH - 45
    local currentY = startY

    love.graphics.push()

    for _, n in ipairs(Notifications.list) do
        local notifX = screenW - n.width - marginX
        local notifY = currentY - n.height

        -- Light theme toast
        love.graphics.setColor(0, 0, 0, 0.08 * n.alpha)
        love.graphics.rectangle("fill", notifX + 2, notifY + 2, n.width, n.height)

        love.graphics.setColor(1, 1, 1, 0.98 * n.alpha)
        love.graphics.rectangle("fill", notifX, notifY, n.width, n.height)

        -- Windows Left Accent Bar (blue)
        love.graphics.setColor(0.0, 0.47, 0.83, 0.9 * n.alpha)
        love.graphics.rectangle("fill", notifX, notifY, 3, n.height)

        -- Title
        love.graphics.setFont(Notifications.font or love.graphics.getFont())
        love.graphics.setColor(0.1, 0.12, 0.16, n.alpha)
        love.graphics.print(n.title, notifX + 12, notifY + 8)

        -- Message
        love.graphics.setFont(Notifications.smallFont or love.graphics.getFont())
        love.graphics.setColor(0.3, 0.32, 0.36, 0.9 * n.alpha)
        love.graphics.printf(n.message, notifX + 12, notifY + 30, n.width - 24, "left")

        currentY = currentY - n.height - 8
    end

    love.graphics.pop()
end

return Notifications