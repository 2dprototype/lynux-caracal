-- src/desktop/notifications.lua
local AudioManager = require("src.core.audio_manager")

local Notifications = {
    list = {},
    maxCount = 4
}

function Notifications.init()
    Notifications.list = {}
end

function Notifications.add(title, message, icon, duration, onClick)
    local notif = {
        id = love.timer.getTime() + math.random(),
        title = title or "Notification",
        message = message or "",
        icon = icon,
        timer = 0,
        duration = duration or 4.0,
        onClick = onClick,
        alpha = 0,
        height = 56,
        width = 270
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
    local screenW = love.graphics.getWidth()
    local marginX, startY = 20, 42
    local currentY = startY

    for i, n in ipairs(Notifications.list) do
        local notifX = screenW - n.width - marginX
        local notifY = currentY
        if x >= notifX and x <= notifX + n.width and y >= notifY and y <= notifY + n.height then
            if n.onClick then
                n.onClick(n)
            end
            table.remove(Notifications.list, i)
            AudioManager.playSFX("click")
            return true
        end
        currentY = currentY + n.height + 6
    end
    return false
end

function Notifications.draw()
    local screenW = love.graphics.getWidth()
    local marginX, startY = 20, 42
    local currentY = startY

    love.graphics.push()

    for _, n in ipairs(Notifications.list) do
        local notifX = screenW - n.width - marginX
        local notifY = currentY

        -- Drop shadow
        love.graphics.setColor(0, 0, 0, 0.3 * n.alpha)
        love.graphics.rectangle("fill", notifX + 2, notifY + 2, n.width, n.height, 5, 5)

        -- Panel background (Warm Dark Charcoal)
        love.graphics.setColor(0.13, 0.12, 0.16, 0.96 * n.alpha)
        love.graphics.rectangle("fill", notifX, notifY, n.width, n.height, 5, 5)

        -- Retro Sunny Yellow Border
        love.graphics.setColor(1.0, 0.82, 0.25, 0.9 * n.alpha)
        love.graphics.setLineWidth(1.3)
        love.graphics.rectangle("line", notifX, notifY, n.width, n.height, 5, 5)

        -- Kawaii Accent Star/Dot
        love.graphics.setColor(1.0, 0.85, 0.3, n.alpha)
        love.graphics.circle("fill", notifX + 16, notifY + 16, 4)

        -- Title
        love.graphics.setColor(1.0, 0.96, 0.9, n.alpha)
        love.graphics.print(n.title, notifX + 26, notifY + 8)

        -- Message
        love.graphics.setColor(0.85, 0.82, 0.78, 0.9 * n.alpha)
        love.graphics.printf(n.message, notifX + 14, notifY + 28, n.width - 24, "left")

        currentY = currentY + n.height + 6
    end

    love.graphics.pop()
end

return Notifications
