-- src/desktop/taskbar.lua
local PlayerStats = require("src.core.player_stats")
local TaskManager = require("src.tasks.task_manager")
local EventBus = require("src.core.event_bus")
local AudioManager = require("src.core.audio_manager")

local Taskbar = {
    topBarHeight = 28,
    bottomBarHeight = 42,
    font = nil,
    smallFont = nil,
    boldFont = nil,
    startIcon = nil,
    ellipsisIcon = nil,
    storyBtnHover = false
}

function Taskbar.init()
    Taskbar.font = love.graphics.newFont("font/Nunito-Regular.ttf", 13) or love.graphics.newFont(13)
    Taskbar.smallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 11) or love.graphics.newFont(11)
    Taskbar.boldFont = love.graphics.newFont("font/Nunito-Regular.ttf", 12) or love.graphics.newFont(12)
    pcall(function()
        Taskbar.startIcon = love.graphics.newImage("assets/layers.png")
        Taskbar.ellipsisIcon = love.graphics.newImage("assets/option.png")
    end)
end

function Taskbar.drawTopBar()
    local screenW = love.graphics.getWidth()
    local h = Taskbar.topBarHeight

    love.graphics.push()

    -- Top bar warm dark retro slate background
    love.graphics.setColor(0.11, 0.1, 0.14, 0.96)
    love.graphics.rectangle("fill", 0, 0, screenW, h)
    love.graphics.setColor(1.0, 0.82, 0.25, 0.3) -- Sunny Yellow separator
    love.graphics.line(0, h, screenW, h)

    -- OS Brand (Cute Star & Gold Text)
    love.graphics.setColor(1.0, 0.85, 0.3) -- Sunny Yellow
    love.graphics.print("★", 12, 6)
    
    love.graphics.setFont(Taskbar.boldFont)
    love.graphics.setColor(1.0, 0.96, 0.88)
    love.graphics.print("Lynux", 26, 6)

    -- Player Level & XP Badge (Cute Retro Gaming Pill)
    local xpProgress = PlayerStats.getLevelProgress()
    local levelText = "♥ Lv." .. tostring(PlayerStats.level) .. " " .. PlayerStats.title
    local badgeX = 82
    local badgeW = 165
    local badgeH = 18
    local badgeY = 5
    
    love.graphics.setColor(0.18, 0.16, 0.22, 0.9)
    love.graphics.rectangle("fill", badgeX, badgeY, badgeW, badgeH, 4, 4)
    
    -- Progress fill (Warm Amber / Gold)
    if xpProgress > 0 then
        love.graphics.setColor(1.0, 0.75, 0.2, 0.75)
        love.graphics.rectangle("fill", badgeX, badgeY, badgeW * xpProgress, badgeH, 4, 4)
    end
    love.graphics.setColor(1.0, 0.85, 0.3, 0.6)
    love.graphics.rectangle("line", badgeX, badgeY, badgeW, badgeH, 4, 4)

    love.graphics.setFont(Taskbar.smallFont)
    love.graphics.setColor(1.0, 0.98, 0.94)
    love.graphics.printf(levelText, badgeX, badgeY + 2, badgeW, "center")

    -- Active Objective Badge (Center)
    local task = TaskManager.getCurrentTask()
    if task then
        local taskBadgeX = 255
        local taskBadgeW = 215
        if task.completed then
            love.graphics.setColor(0.14, 0.25, 0.18, 0.9)
        else
            love.graphics.setColor(0.24, 0.19, 0.12, 0.9)
        end
        love.graphics.rectangle("fill", taskBadgeX, badgeY, taskBadgeW, badgeH, 4, 4)
        
        if task.completed then
            love.graphics.setColor(0.2, 0.88, 0.55, 0.85) -- Mint
        else
            love.graphics.setColor(1.0, 0.82, 0.25, 0.85) -- Yellow
        end
        love.graphics.rectangle("line", taskBadgeX, badgeY, taskBadgeW, badgeH, 4, 4)
        
        love.graphics.setColor(1.0, 0.98, 0.92)
        love.graphics.setFont(Taskbar.smallFont)
        local statusPrefix = task.completed and "✓ " or "★ "
        love.graphics.printf(statusPrefix .. task.title, taskBadgeX + 6, badgeY + 2, taskBadgeW - 12, "left")
    end

    -- "Story Mode / Stand Up" Button (Right)
    local btnW = 125
    local btnX = screenW - btnW - 80
    local btnY = 4
    local btnH = 20

    if Taskbar.storyBtnHover then
        love.graphics.setColor(1.0, 0.82, 0.25, 0.95) -- Bright Yellow on hover
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
        love.graphics.setColor(0.12, 0.1, 0.15)
    else
        love.graphics.setColor(0.22, 0.18, 0.24, 0.9)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
        love.graphics.setColor(1.0, 0.82, 0.25, 0.8)
        love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 4, 4)
        love.graphics.setColor(1.0, 0.96, 0.88)
    end

    love.graphics.setFont(Taskbar.smallFont)
    love.graphics.printf("📖 Story Mode", btnX, btnY + 2, btnW, "center")

    -- Digital Clock (Far Right)
    local timeStr = os.date("%H:%M")
    love.graphics.setFont(Taskbar.font)
    love.graphics.setColor(1.0, 0.88, 0.5)
    love.graphics.print(timeStr, screenW - 55, 5)

    love.graphics.pop()
end

function Taskbar.mousepressed(x, y, button)
    if button ~= 1 then return false end
    local screenW = love.graphics.getWidth()

    if y >= 0 and y <= Taskbar.topBarHeight then
        local btnW = 125
        local btnX = screenW - btnW - 80
        if x >= btnX and x <= btnX + btnW then
            AudioManager.playSFX("switch")
            EventBus.emit("game:request_switch_mode", { mode = "story", transition = "fade" })
            return true
        end
        return true
    end
    return false
end

function Taskbar.mousemoved(x, y)
    local screenW = love.graphics.getWidth()
    local btnW = 125
    local btnX = screenW - btnW - 80
    if y >= 0 and y <= Taskbar.topBarHeight and x >= btnX and x <= btnX + btnW then
        Taskbar.storyBtnHover = true
    else
        Taskbar.storyBtnHover = false
    end
end

return Taskbar
