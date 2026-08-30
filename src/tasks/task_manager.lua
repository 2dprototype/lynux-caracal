-- src/tasks/task_manager.lua
local EventBus = require("src.core.event_bus")
local AudioManager = require("src.core.audio_manager")
local PlayerStats = require("src.core.player_stats")

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
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local bannerW = 360
    local bannerH = 52
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
    love.graphics.rectangle("fill", bannerX + 3, bannerY + 3, bannerW, bannerH, 6, 6)

    -- Background (Warm Retro Dark Charcoal)
    love.graphics.setColor(0.12, 0.11, 0.15, 0.96 * alpha)
    love.graphics.rectangle("fill", bannerX, bannerY, bannerW, bannerH, 6, 6)

    -- Retro Sunny Yellow Accent Border
    love.graphics.setColor(1.0, 0.82, 0.25, 0.95 * alpha)
    love.graphics.setLineWidth(1.4)
    love.graphics.rectangle("line", bannerX, bannerY, bannerW, bannerH, 6, 6)

    -- Icon Checkmark Circle (Sunny Lemon Gold)
    local iconX = bannerX + 22
    local iconY = bannerY + bannerH / 2
    love.graphics.setColor(1.0, 0.85, 0.3, 0.95 * alpha)
    love.graphics.circle("fill", iconX, iconY, 12)
    love.graphics.setColor(0.12, 0.11, 0.15, alpha)
    local font = love.graphics.getFont()
    love.graphics.print("★", iconX - 4, iconY - 9)

    -- Text Content
    love.graphics.setColor(1.0, 0.96, 0.9, alpha)
    love.graphics.print(b.title, bannerX + 44, bannerY + 8)

    love.graphics.setColor(1.0, 0.85, 0.3, alpha)
    love.graphics.print(b.subtext .. "  •  ♥ Level " .. PlayerStats.level .. " (" .. PlayerStats.title .. ")", bannerX + 44, bannerY + 28)

    love.graphics.pop()
end

return TaskManager
