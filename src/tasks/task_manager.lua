-- src/tasks/task_manager.lua
local EventBus = require("src.core.event_bus")
local AudioManager = require("src.core.audio_manager")
local PlayerStats = require("src.core.player_stats")
local Viewport = require("src.core.viewport")

local TaskManager = {
    currentTask = nil,
    completedTasks = {},
    checkTimer = 0,
    checkInterval = 0.4, -- check every 400ms
    celebrationBanner = {
        active = false,
        timer = 0,
        duration = 3.5,
        title = "",
        xp = 0,
        subtext = ""
    }
}

function TaskManager.init()
    TaskManager.currentTask = nil
    TaskManager.completedTasks = {}
    TaskManager.celebrationBanner.active = false

    -- Listen to file events to immediately evaluate
    EventBus.on("file:saved", function()
        TaskManager.checkProgress()
    end, "task_mgr_filesave")

    EventBus.on("file:created", function()
        TaskManager.checkProgress()
    end, "task_mgr_filecreate")

    EventBus.on("terminal:command", function()
        TaskManager.checkProgress()
    end, "task_mgr_cmd")
end

function TaskManager.setTask(taskDef)
    if not taskDef then
        TaskManager.currentTask = nil
        return
    end

    -- Setup task structure
    TaskManager.currentTask = {
        id = taskDef.id or ("task_" .. tostring(os.time())),
        title = taskDef.title or "New Objective",
        desc = taskDef.desc or "",
        hint = taskDef.hint or "",
        xp = taskDef.xp or 100,
        objectives = taskDef.objectives or {},
        onComplete = taskDef.onComplete,
        completed = false,
        completedTime = nil
    }

    -- If no explicit objectives array, create single default objective from condition
    if #TaskManager.currentTask.objectives == 0 and taskDef.condition then
        table.insert(TaskManager.currentTask.objectives, {
            id = "main_objective",
            text = taskDef.desc or taskDef.title,
            condition = taskDef.condition,
            done = false
        })
    end

    EventBus.emit("task:assigned", TaskManager.currentTask)
    AudioManager.playSFX("notification")
end

function TaskManager.getCurrentTask()
    return TaskManager.currentTask
end

function TaskManager.hasActiveTask()
    return TaskManager.currentTask ~= nil and not TaskManager.currentTask.completed
end

function TaskManager.checkProgress()
    local task = TaskManager.currentTask
    if not task or task.completed then return end

    local allDone = true
    for _, obj in ipairs(task.objectives) do
        if not obj.done then
            local isDone = false
            if type(obj.condition) == "function" then
                local ok, res = pcall(obj.condition)
                if ok and res then
                    isDone = true
                end
            end
            if isDone then
                obj.done = true
                AudioManager.playSFX("tick", 1.2)
                EventBus.emit("task:objective_done", { task = task, objective = obj })
            else
                allDone = false
            end
        end
    end

    if allDone and #task.objectives > 0 then
        TaskManager.completeTask(task)
    end
end

function TaskManager.completeTask(task)
    task = task or TaskManager.currentTask
    if not task or task.completed then return end

    task.completed = true
    task.completedTime = love.timer.getTime()
    table.insert(TaskManager.completedTasks, task)

    -- Trigger Celebration Banner
    TaskManager.celebrationBanner.active = true
    TaskManager.celebrationBanner.timer = 0
    TaskManager.celebrationBanner.title = task.title .. " Complete!"
    TaskManager.celebrationBanner.xp = task.xp
    TaskManager.celebrationBanner.subtext = "XP Gained: +" .. tostring(task.xp)

    -- Audio feedback
    AudioManager.playSFX("task_complete", 1.0, 1.0)
    
    -- Award XP
    if task.xp and task.xp > 0 then
        PlayerStats.addXP(task.xp)
    end

    EventBus.emit("task:completed", task)

    if task.onComplete then
        task.onComplete(task)
    end
end

function TaskManager.update(dt)
    -- Periodic check
    if TaskManager.hasActiveTask() then
        TaskManager.checkTimer = TaskManager.checkTimer + dt
        if TaskManager.checkTimer >= TaskManager.checkInterval then
            TaskManager.checkTimer = 0
            TaskManager.checkProgress()
        end
    end

    -- Celebration Banner timer
    if TaskManager.celebrationBanner.active then
        TaskManager.celebrationBanner.timer = TaskManager.celebrationBanner.timer + dt
        if TaskManager.celebrationBanner.timer >= TaskManager.celebrationBanner.duration then
            TaskManager.celebrationBanner.active = false
        end
    end
end

function TaskManager.drawCelebrationBanner()
    if not TaskManager.celebrationBanner.active then return end

    local b = TaskManager.celebrationBanner
    local w, h = Viewport.getWidth(), Viewport.getHeight()
    local bannerW = 380
    local bannerH = 54
    local bannerX = (w - bannerW) / 2
    local bannerY = 40

    -- Fade and slide animation
    local alpha = 1
    if b.timer < 0.25 then
        alpha = b.timer / 0.25
        bannerY = 24 + 16 * alpha
    elseif b.timer > b.duration - 0.4 then
        alpha = (b.duration - b.timer) / 0.4
    end

    love.graphics.push()
    
    -- Drop Shadow
    love.graphics.setColor(0, 0, 0, 0.35 * alpha)
    love.graphics.rectangle("fill", bannerX + 2, bannerY + 2, bannerW, bannerH)

    -- Background (Windows 10 Clean Dark Surface)
    love.graphics.setColor(0.12, 0.13, 0.16, 0.98 * alpha)
    love.graphics.rectangle("fill", bannerX, bannerY, bannerW, bannerH)

    -- Windows Accent Blue Indicator Strip (No emojis)
    love.graphics.setColor(0.0, 0.47, 0.83, 0.95 * alpha)
    love.graphics.rectangle("fill", bannerX, bannerY, 4, bannerH)

    -- Text Content
    local bannerFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 15) or love.graphics.newFont(15)
    local bannerSmallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 12) or love.graphics.newFont(12)
    
    love.graphics.setFont(bannerFont)
    love.graphics.setColor(0.96, 0.98, 1.0, alpha)
    love.graphics.print(b.title, bannerX + 16, bannerY + 8)

    love.graphics.setFont(bannerSmallFont)
    love.graphics.setColor(0.0, 0.55, 0.95, alpha)
    love.graphics.print(b.subtext .. "  |  Level " .. tostring(PlayerStats.level) .. " (" .. PlayerStats.title .. ")", bannerX + 16, bannerY + 28)

    love.graphics.pop()
end

return TaskManager
