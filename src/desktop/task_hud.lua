-- src/desktop/task_hud.lua
-- Windows 10 Style Sticky Note / Objective Tracker Widget

local TaskManager = require("src.tasks.task_manager")
local AudioManager = require("src.core.audio_manager")
local EventBus = require("src.core.event_bus")

local TaskHUD = {
    x = 18,
    y = 35,
    width = 245,
    height = 175,
    collapsed = false,
    showHint = false,
    dragging = false,
    dragOffsetX = 0,
    dragOffsetY = 0,
    font = nil,
    headerFont = nil,
    smallFont = nil
}

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

function TaskHUD.init()
    TaskHUD.font = loadCustomFont("font/Nunito-Regular.ttf", 14)
    TaskHUD.headerFont = loadCustomFont("font/IBMPlexSans-Bold.ttf", 14) or loadCustomFont("font/Nunito-Regular.ttf", 14)
    TaskHUD.smallFont = loadCustomFont("font/Nunito-Regular.ttf", 12)
    TaskHUD.x = 18
    TaskHUD.y = 35
end

function TaskHUD.update(dt)
    if TaskHUD.dragging then
        local mx, my = love.mouse.getPosition()
        TaskHUD.x = mx - TaskHUD.dragOffsetX
        TaskHUD.y = my - TaskHUD.dragOffsetY
        TaskHUD.x = math.max(4, math.min(love.graphics.getWidth() - TaskHUD.width - 4, TaskHUD.x))
        TaskHUD.y = math.max(10, math.min(love.graphics.getHeight() - 65, TaskHUD.y))
    end
end

function TaskHUD.draw()
    local task = TaskManager.getCurrentTask()
    if not task then return end

    local headerH = 28
    local fullH = TaskHUD.collapsed and headerH or (TaskHUD.showHint and 230 or 170)
    TaskHUD.height = fullH

    love.graphics.push()

    -- Subtle Drop shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", TaskHUD.x + 2, TaskHUD.y + 2, TaskHUD.width, fullH)

    -- Windows 10 Sticky Note / Card Surface
    love.graphics.setColor(0.13, 0.14, 0.17, 0.98)
    love.graphics.rectangle("fill", TaskHUD.x, TaskHUD.y, TaskHUD.width, fullH)

    -- Flat 1px Border (Accent Blue when active, Clean Green when complete)
    if task.completed then
        love.graphics.setColor(0.18, 0.65, 0.35, 0.9)
    else
        love.graphics.setColor(0.0, 0.47, 0.83, 0.85) -- Windows Accent Blue
    end
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", TaskHUD.x, TaskHUD.y, TaskHUD.width, fullH)

    -- Header Bar
    love.graphics.setColor(0.18, 0.19, 0.23, 0.98)
    love.graphics.rectangle("fill", TaskHUD.x, TaskHUD.y, TaskHUD.width, headerH)
    love.graphics.setColor(0.25, 0.26, 0.3)
    love.graphics.line(TaskHUD.x, TaskHUD.y + headerH, TaskHUD.x + TaskHUD.width, TaskHUD.y + headerH)

    -- Header Title (No emojis)
    love.graphics.setFont(TaskHUD.headerFont)
    if task.completed then
        love.graphics.setColor(0.3, 0.85, 0.45)
        love.graphics.print("Task Complete", TaskHUD.x + 10, TaskHUD.y + 4)
    else
        love.graphics.setColor(0.92, 0.94, 0.98)
        love.graphics.print("Objectives", TaskHUD.x + 10, TaskHUD.y + 4)
    end

    -- XP Pill Badge (Header Right)
    love.graphics.setFont(TaskHUD.smallFont)
    love.graphics.setColor(0.0, 0.55, 0.95)
    love.graphics.print("+" .. tostring(task.xp) .. " XP", TaskHUD.x + TaskHUD.width - 65, TaskHUD.y + 6)

    -- Collapse toggle button
    love.graphics.setColor(0.7, 0.75, 0.8)
    love.graphics.print(TaskHUD.collapsed and "[+]" or "[-]", TaskHUD.x + TaskHUD.width - 18, TaskHUD.y + 6)

    if not TaskHUD.collapsed then
        -- Title
        love.graphics.setFont(TaskHUD.font)
        love.graphics.setColor(0.95, 0.96, 0.98)
        love.graphics.printf(task.title, TaskHUD.x + 12, TaskHUD.y + 34, TaskHUD.width - 24, "left")

        -- Description
        love.graphics.setFont(TaskHUD.smallFont)
        love.graphics.setColor(0.75, 0.78, 0.82)
        love.graphics.printf(task.desc, TaskHUD.x + 12, TaskHUD.y + 54, TaskHUD.width - 24, "left")

        -- Checklist Items
        local objY = TaskHUD.y + 92
        for _, obj in ipairs(task.objectives) do
            love.graphics.setColor(0.35, 0.38, 0.45)
            love.graphics.rectangle("line", TaskHUD.x + 12, objY + 2, 12, 12)

            if obj.done then
                love.graphics.setColor(0.2, 0.8, 0.4)
                love.graphics.rectangle("fill", TaskHUD.x + 14, objY + 4, 8, 8)
                love.graphics.setColor(0.4, 0.85, 0.5)
            else
                love.graphics.setColor(0.85, 0.88, 0.92)
            end

            love.graphics.setFont(TaskHUD.smallFont)
            love.graphics.printf(obj.text, TaskHUD.x + 30, objY + 1, TaskHUD.width - 42, "left")
            objY = objY + 20
        end

        -- Hint Button / Drawer
        if task.hint and task.hint ~= "" and not task.completed then
            local hintBtnY = objY + 4
            love.graphics.setColor(0.18, 0.2, 0.25)
            love.graphics.rectangle("fill", TaskHUD.x + 12, hintBtnY, TaskHUD.width - 24, 20, 2, 2)
            love.graphics.setColor(0.75, 0.8, 0.9)
            love.graphics.setFont(TaskHUD.smallFont)
            love.graphics.printf(TaskHUD.showHint and "Hide Hint" or "Need a Hint?", TaskHUD.x + 12, hintBtnY + 3, TaskHUD.width - 24, "center")

            if TaskHUD.showHint then
                love.graphics.setColor(0.85, 0.88, 0.95)
                love.graphics.printf(task.hint, TaskHUD.x + 14, hintBtnY + 24, TaskHUD.width - 28, "left")
            end
        end

        -- Continue Story Button when Completed
        if task.completed then
            local returnY = TaskHUD.y + fullH - 28
            love.graphics.setColor(0.0, 0.47, 0.83, 0.95) -- Windows Accent Blue
            love.graphics.rectangle("fill", TaskHUD.x + 12, returnY, TaskHUD.width - 24, 22, 2, 2)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(TaskHUD.font)
            love.graphics.printf("Continue Story", TaskHUD.x + 12, returnY + 2, TaskHUD.width - 24, "center")
        end
    end

    love.graphics.pop()
end

function TaskHUD.mousepressed(x, y, button)
    local task = TaskManager.getCurrentTask()
    if not task or button ~= 1 then return false end

    if x >= TaskHUD.x and x <= TaskHUD.x + TaskHUD.width and y >= TaskHUD.y and y <= TaskHUD.y + 28 then
        if x >= TaskHUD.x + TaskHUD.width - 28 then
            TaskHUD.collapsed = not TaskHUD.collapsed
            AudioManager.playSFX("click")
            return true
        else
            TaskHUD.dragging = true
            TaskHUD.dragOffsetX = x - TaskHUD.x
            TaskHUD.dragOffsetY = y - TaskHUD.y
            return true
        end
    end

    if not TaskHUD.collapsed and x >= TaskHUD.x and x <= TaskHUD.x + TaskHUD.width and y >= TaskHUD.y and y <= TaskHUD.y + TaskHUD.height then
        if task.hint and task.hint ~= "" and not task.completed then
            local hintBtnY = TaskHUD.y + 115
            if y >= hintBtnY and y <= hintBtnY + 22 then
                TaskHUD.showHint = not TaskHUD.showHint
                AudioManager.playSFX("click")
                return true
            end
        end

        if task.completed and y >= TaskHUD.y + TaskHUD.height - 30 then
            EventBus.emit("game:request_switch_mode", { mode = "story", transition = "fade" })
            AudioManager.playSFX("click")
            return true
        end

        return true
    end

    return false
end

function TaskHUD.mousereleased(x, y, button)
    if button == 1 and TaskHUD.dragging then
        TaskHUD.dragging = false
        return true
    end
    return false
end

return TaskHUD
