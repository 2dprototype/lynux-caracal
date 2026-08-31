-- src/desktop/taskbar.lua
-- Windows 10 Style Bottom Taskbar & System Tray

local PlayerStats = require("src.core.player_stats")
local TaskManager = require("src.tasks.task_manager")
local EventBus = require("src.core.event_bus")
local AudioManager = require("src.core.audio_manager")

local Taskbar = {
    bottomBarHeight = 38,
    font = nil,
    smallFont = nil,
    boldFont = nil,
    storyBtnHover = false,
    startHover = false
}

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

function Taskbar.init()
    Taskbar.font = loadCustomFont("font/x14y24pxHeadUpDaisy.ttf", 18)
    Taskbar.smallFont = loadCustomFont("font/x14y24pxHeadUpDaisy.ttf", 15)
    Taskbar.boldFont = loadCustomFont("font/x14y24pxHeadUpDaisy.ttf", 18)
end

function Taskbar.drawBottomBar()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local h = Taskbar.bottomBarHeight
    local y = screenH - h

    love.graphics.push()

    -- Windows 10 Dark Taskbar Surface
    love.graphics.setColor(0.1, 0.1, 0.12, 0.98)
    love.graphics.rectangle("fill", 0, y, screenW, h)
    love.graphics.setColor(0.18, 0.18, 0.22)
    love.graphics.line(0, y, screenW, y)

    -- Windows Start Button (Bottom-Left)
    local startW = 44
    if Taskbar.startHover then
        love.graphics.setColor(0.2, 0.22, 0.26)
        love.graphics.rectangle("fill", 0, y, startW, h)
    end

    -- Windows 4-Square Flat Logo
    love.graphics.setColor(Taskbar.startHover and {0.0, 0.47, 0.83} or {0.85, 0.88, 0.92})
    local winLogoX = 14
    local winLogoY = y + 11
    love.graphics.rectangle("fill", winLogoX, winLogoY, 6, 6)
    love.graphics.rectangle("fill", winLogoX + 8, winLogoY, 6, 6)
    love.graphics.rectangle("fill", winLogoX, winLogoY + 8, 6, 6)
    love.graphics.rectangle("fill", winLogoX + 8, winLogoY + 8, 6, 6)

    -- Search Box Mockup (Windows 10 style)
    local searchX = 48
    local searchW = 140
    local searchH = 28
    local searchY = y + 5
    love.graphics.setColor(0.16, 0.16, 0.18)
    love.graphics.rectangle("fill", searchX, searchY, searchW, searchH)
    love.graphics.setFont(Taskbar.smallFont)
    love.graphics.setColor(0.55, 0.55, 0.6)
    love.graphics.print("Type here to search", searchX + 10, searchY + 4)

    -- Right-Side System Tray
    local rightX = screenW - 10

    -- Clock and Date (Far Right)
    local timeStr = os.date("%H:%M")
    local dateStr = os.date("%m/%d/%Y")
    love.graphics.setFont(Taskbar.smallFont)
    love.graphics.setColor(0.9, 0.92, 0.96)
    love.graphics.print(timeStr, screenW - 65, y + 4)
    love.graphics.setColor(0.65, 0.68, 0.72)
    love.graphics.print(dateStr, screenW - 65, y + 19)

    -- "Story Mode" Switch Button (Windows Tray Tool Button)
    local btnW = 105
    local btnH = 26
    local btnX = screenW - 180
    local btnY = y + 6

    if Taskbar.storyBtnHover then
        love.graphics.setColor(0.0, 0.47, 0.83, 0.9) -- Windows Accent Blue
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 2, 2)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.16, 0.18, 0.22, 0.9)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 2, 2)
        love.graphics.setColor(0.28, 0.3, 0.36)
        love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 2, 2)
        love.graphics.setColor(0.85, 0.88, 0.92)
    end
    love.graphics.setFont(Taskbar.smallFont)
    love.graphics.printf("Story Mode", btnX, btnY + 4, btnW, "center")

    -- Player Level & XP Indicator (Tray badge)
    local xpProgress = PlayerStats.getLevelProgress()
    local levelText = "Lv." .. tostring(PlayerStats.level) .. " " .. PlayerStats.title
    local lvlW = 125
    local lvlX = btnX - lvlW - 10
    local lvlY = y + 8
    local lvlH = 22

    love.graphics.setColor(0.15, 0.16, 0.2)
    love.graphics.rectangle("fill", lvlX, lvlY, lvlW, lvlH, 2, 2)
    if xpProgress > 0 then
        love.graphics.setColor(0.0, 0.47, 0.83, 0.6)
        love.graphics.rectangle("fill", lvlX, lvlY, lvlW * xpProgress, lvlH, 2, 2)
    end
    love.graphics.setColor(0.25, 0.28, 0.34)
    love.graphics.rectangle("line", lvlX, lvlY, lvlW, lvlH, 2, 2)

    love.graphics.setFont(Taskbar.smallFont)
    love.graphics.setColor(0.92, 0.94, 0.98)
    love.graphics.printf(levelText, lvlX, lvlY + 2, lvlW, "center")

    love.graphics.pop()
end

function Taskbar.mousepressed(x, y, button)
    if button ~= 1 then return false end
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local taskbarY = screenH - Taskbar.bottomBarHeight

    if y >= taskbarY then
        local btnW = 105
        local btnX = screenW - 180
        if x >= btnX and x <= btnX + btnW then
            AudioManager.playSFX("switch")
            EventBus.emit("game:request_switch_mode", { mode = "story", transition = "fade" })
            return true
        end
        return false
    end
    return false
end

function Taskbar.mousemoved(x, y)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local taskbarY = screenH - Taskbar.bottomBarHeight
    local btnW = 105
    local btnX = screenW - 180

    if y >= taskbarY and x >= btnX and x <= btnX + btnW then
        Taskbar.storyBtnHover = true
    else
        Taskbar.storyBtnHover = false
    end

    if y >= taskbarY and x >= 0 and x <= 44 then
        Taskbar.startHover = true
    else
        Taskbar.startHover = false
    end
end

return Taskbar
