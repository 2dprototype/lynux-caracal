-- src/desktop/taskbar.lua
-- Windows 10 Style Bottom Taskbar & System Tray - Light theme
-- No search bar, level bar on the right

local PlayerStats = require("src.core.player_stats")
local TaskManager = require("src.tasks.task_manager")
local AudioManager = require("src.core.audio_manager")

local Taskbar = {
    bottomBarHeight = 38,
    font = nil,
    smallFont = nil,
    boldFont = nil,
    startHover = false
}

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

function Taskbar.init()
    Taskbar.font = loadCustomFont("font/Nunito-Regular.ttf", 14)
    Taskbar.smallFont = loadCustomFont("font/Nunito-Regular.ttf", 12)
    Taskbar.boldFont = loadCustomFont("font/IBMPlexSans-Bold.ttf", 13) or loadCustomFont("font/Nunito-Regular.ttf", 13)
end

function Taskbar.drawBottomBar()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local h = Taskbar.bottomBarHeight
    local y = screenH - h

    love.graphics.push()

    -- Light taskbar background
    love.graphics.setColor(0.98, 0.98, 0.99, 0.98)
    love.graphics.rectangle("fill", 0, y, screenW, h)
    love.graphics.setColor(0.85, 0.88, 0.92)
    love.graphics.line(0, y, screenW, y)

    -- Windows Start Button (Bottom-Left)
    local startW = 44
    if Taskbar.startHover then
        love.graphics.setColor(0.9, 0.92, 0.95)
        love.graphics.rectangle("fill", 0, y, startW, h)
    end

    -- Windows 4-Square Flat Logo (blue)
    love.graphics.setColor(Taskbar.startHover and {0.0, 0.47, 0.83} or {0.3, 0.32, 0.36})
    local winLogoX = 14
    local winLogoY = y + 11
    love.graphics.rectangle("fill", winLogoX, winLogoY, 6, 6)
    love.graphics.rectangle("fill", winLogoX + 8, winLogoY, 6, 6)
    love.graphics.rectangle("fill", winLogoX, winLogoY + 8, 6, 6)
    love.graphics.rectangle("fill", winLogoX + 8, winLogoY + 8, 6, 6)

    -- Right-Side System Tray - Clock and Date
    local timeStr = os.date("%H:%M")
    local dateStr = os.date("%m/%d/%Y")
    
    -- Calculate level bar width and position
    local xpProgress = PlayerStats.getLevelProgress()
    local levelText = "Lv." .. tostring(PlayerStats.level) .. " " .. PlayerStats.title
    
    -- Determine if we need to shrink based on available space
    local clockWidth = 80
    local minLevelWidth = 80
    local maxLevelWidth = 150
    local margin = 12
    
    local availableForLevel = screenW - clockWidth - margin * 2
    local levelWidth = math.min(maxLevelWidth, math.max(minLevelWidth, availableForLevel - 40))
    local levelX = screenW - clockWidth - levelWidth - margin
    
    -- Clock
    love.graphics.setFont(Taskbar.smallFont)
    love.graphics.setColor(0.1, 0.12, 0.16)
    love.graphics.print(timeStr, screenW - clockWidth + 10, y + 4)
    love.graphics.setColor(0.4, 0.42, 0.46)
    love.graphics.print(dateStr, screenW - clockWidth + 10, y + 19)

    -- Player Level & XP Indicator
    local lvlY = y + 8
    local lvlH = 22

    -- Only draw level bar if there's enough space
    if levelWidth > minLevelWidth then
        love.graphics.setColor(0.94, 0.95, 0.96)
        love.graphics.rectangle("fill", levelX, lvlY, levelWidth, lvlH, 2, 2)
        if xpProgress > 0 then
            love.graphics.setColor(0.0, 0.47, 0.83, 0.3)
            love.graphics.rectangle("fill", levelX, lvlY, levelWidth * xpProgress, lvlH, 2, 2)
        end
        love.graphics.setColor(0.7, 0.72, 0.76)
        love.graphics.rectangle("line", levelX, lvlY, levelWidth, lvlH, 2, 2)

        love.graphics.setFont(Taskbar.smallFont)
        love.graphics.setColor(0.1, 0.12, 0.16)
        love.graphics.printf(levelText, levelX, lvlY + 3, levelWidth, "center")
    else
        -- Fallback: just show level number
        love.graphics.setFont(Taskbar.smallFont)
        love.graphics.setColor(0.1, 0.12, 0.16)
        love.graphics.print("Lv." .. tostring(PlayerStats.level), levelX, lvlY + 3)
    end

    love.graphics.pop()
end

function Taskbar.mousepressed(x, y, button)
    return false
end

function Taskbar.mousemoved(x, y)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local taskbarY = screenH - Taskbar.bottomBarHeight

    if y >= taskbarY and x >= 0 and x <= 44 then
        Taskbar.startHover = true
    else
        Taskbar.startHover = false
    end
end

return Taskbar