-- src/core/game_manager.lua
local EventBus = require("src.core.event_bus")
local AudioManager = require("src.core.audio_manager")
local PlayerStats = require("src.core.player_stats")
local Transitions = require("src.core.transitions")
local TaskManager = require("src.tasks.task_manager")
local StoryEngine = require("src.story.story_engine")
local DesktopManager = require("src.desktop.desktop_mgr")
local Notifications = require("src.desktop.notifications")
local PauseMenu = require("src.ui.pause_menu")

local GameManager = {
    mode = "story", -- "story", "desktop"
    previousMode = nil,
    currentChapter = nil
}

function GameManager.init()
    AudioManager.init()
    PlayerStats.init()
    TaskManager.init()
    StoryEngine.init()
    DesktopManager.init()
    PauseMenu.init()

    -- Listen to switch mode requests
    EventBus.on("game:request_switch_mode", function(data)
        local targetMode = (type(data) == "table" and data.mode) or data or (GameManager.mode == "story" and "desktop" or "story")
        local transType = (type(data) == "table" and data.transition) or "fade"
        GameManager.switchMode(targetMode, transType)
    end, "gm_switch_mode")

    -- Listen to task completion events
    EventBus.on("task:completed", function(task)
        Notifications.add("Objective Completed!", task.title .. " (+ " .. tostring(task.xp) .. " XP)")
    end, "gm_task_completed")

    -- Load the default story script
    local ok, script = pcall(require, "data.stories.prologue")
    if ok and script then
        StoryEngine.loadScript(script)
    end
end

function GameManager.switchMode(targetMode, transitionType, onComplete)
    if GameManager.mode == targetMode and not Transitions.isActive() then return end

    AudioManager.playSFX(transitionType == "crt_zoom" and "switch" or "click")

    Transitions.start(transitionType or "fade", 0.5, function()
        GameManager.previousMode = GameManager.mode
        GameManager.mode = targetMode
        EventBus.emit("game:mode_switched", { from = GameManager.previousMode, to = targetMode })
    end, function()
        if onComplete then onComplete() end
    end)
end

function GameManager.update(dt)
    Transitions.update(dt)
    TaskManager.update(dt)

    -- If pause menu is open, pause game background updates
    if not PauseMenu.isOpen then
        if GameManager.mode == "story" then
            StoryEngine.update(dt)
        elseif GameManager.mode == "desktop" then
            DesktopManager.update(dt)
        end
    end
end

function GameManager.draw()
    if GameManager.mode == "story" then
        StoryEngine.draw()
    elseif GameManager.mode == "desktop" then
        DesktopManager.draw()
    end

    -- Draw Quest / Level-Up Celebration Banner
    TaskManager.drawCelebrationBanner()

    -- Draw Pause Menu overlay (when active)
    PauseMenu.draw()

    -- Draw Cinematic Transition (Topmost overlay)
    Transitions.draw()
end

function GameManager.mousepressed(x, y, button)
    if Transitions.isActive() then return end
    if PauseMenu.mousepressed(x, y, button) then return end

    if GameManager.mode == "story" then
        StoryEngine.mousepressed(x, y, button)
    elseif GameManager.mode == "desktop" then
        DesktopManager.mousepressed(x, y, button)
    end
end

function GameManager.mousemoved(x, y, dx, dy)
    if Transitions.isActive() then return end
    if PauseMenu.isOpen then
        PauseMenu.mousemoved(x, y)
        return
    end

    if GameManager.mode == "story" then
        StoryEngine.mousemoved(x, y, dx, dy)
    elseif GameManager.mode == "desktop" then
        DesktopManager.mousemoved(x, y, dx, dy)
    end
end

function GameManager.mousereleased(x, y, button)
    if Transitions.isActive() or PauseMenu.isOpen then return end

    if GameManager.mode == "desktop" then
        DesktopManager.mousereleased(x, y, button)
    end
end

function GameManager.wheelmoved(x, y)
    if Transitions.isActive() or PauseMenu.isOpen then return end

    if GameManager.mode == "story" then
        StoryEngine.wheelmoved(x, y)
    elseif GameManager.mode == "desktop" then
        DesktopManager.wheelmoved(x, y)
    end
end

function GameManager.textinput(text)
    if Transitions.isActive() or PauseMenu.isOpen then return end

    if GameManager.mode == "desktop" then
        DesktopManager.textinput(text)
    end
end

function GameManager.keypressed(key)
    if Transitions.isActive() then return end

    -- Check Pause Menu keypress first (handles ESC, Up/Down, Enter)
    if PauseMenu.keypressed(key) then return end

    if GameManager.mode == "story" then
        StoryEngine.keypressed(key)
    elseif GameManager.mode == "desktop" then
        DesktopManager.keypressed(key)
    end
end

function GameManager.resize(w, h)
    if DesktopManager.resize then
        DesktopManager.resize(w, h)
    end
end

return GameManager
