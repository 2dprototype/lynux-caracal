-- src/desktop/task_hud.lua
local TaskManager = require("src.tasks.task_manager")
local AudioManager = require("src.core.audio_manager")
local EventBus = require("src.core.event_bus")

local TaskHUD = {
    x = 18,
    y = 42,
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

function TaskHUD.init()
    TaskHUD.font = love.graphics.newFont("font/Nunito-Regular.ttf", 13) or love.graphics.newFont(13)
    TaskHUD.headerFont = love.graphics.newFont("font/Nunito-Regular.ttf", 13) or love.graphics.newFont(13)
    TaskHUD.smallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 11) or love.graphics.newFont(11)
    TaskHUD.x = 18
    TaskHUD.y = 42
end

function TaskHUD.update(dt)
    if TaskHUD.dragging then
        local mx, my = love.mouse.getPosition()
        TaskHUD.x = mx - TaskHUD.dragOffsetX
        TaskHUD.y = my - TaskHUD.dragOffsetY
        TaskHUD.x = math.max(4, math.min(love.graphics.getWidth() - TaskHUD.width - 4, TaskHUD.x))
        TaskHUD.y = math.max(32, math.min(love.graphics.getHeight() - 65, TaskHUD.y))
    end
end

function TaskHUD.draw()
    local task = TaskManager.getCurrentTask()
    if not task then return end

    local headerH = 26
    local fullH = TaskHUD.collapsed and headerH or (TaskHUD.showHint and 220 or 165)
    TaskHUD.height = fullH

    love.graphics.push()

    -- Drop shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", TaskHUD.x + 3, TaskHUD.y + 3, TaskHUD.width, fullH, 5, 5)

    -- Card Background (Warm Retro Charcoal)
    if task.completed then
        love.graphics.setColor(0.12, 0.18, 0.15, 0.95)
    else
        love.graphics.setColor(0.14, 0.13, 0.17, 0.95)
    end
    love.graphics.rectangle("fill", TaskHUD.x, TaskHUD.y, TaskHUD.width, fullH, 5, 5)

    -- Accent Border (Retro Sunny Yellow when active, Pastel Mint when completed)
    if task.completed then
        love.graphics.setColor(0.2, 0.88, 0.55, 0.95) -- Mint
    else
        love.graphics.setColor(1.0, 0.82, 0.25, 0.95) -- Sunny Yellow
    end
    love.graphics.setLineWidth(1.4)
    love.graphics.rectangle("line", TaskHUD.x, TaskHUD.y, TaskHUD.width, fullH, 5, 5)

    -- Header Bar
    if task.completed then
        love.graphics.setColor(0.16, 0.26, 0.2, 0.95)
    else
        love.graphics.setColor(0.22, 0.18, 0.22, 0.95)
    end
    love.graphics.rectangle("fill", TaskHUD.x, TaskHUD.y, TaskHUD.width, headerH, 5, 5)
    love.graphics.rectangle("fill", TaskHUD.x, TaskHUD.y + headerH - 4, TaskHUD.width, 4)

    -- Header Label
    love.graphics.setFont(TaskHUD.headerFont)
    if task.completed then
        love.graphics.setColor(0.2, 0.88, 0.55)
        love.graphics.print("✓ Quest Complete", TaskHUD.x + 8, TaskHUD.y + 4)
    else
        love.graphics.setColor(1.0, 0.85, 0.3)
        love.graphics.print("★ Active Quest", TaskHUD.x + 8, TaskHUD.y + 4)
    end

    -- XP Pill Badge (Header Right)
    love.graphics.setFont(TaskHUD.smallFont)
    love.graphics.setColor(1.0, 0.85, 0.3)
    love.graphics.print("+" .. tostring(task.xp) .. " XP", TaskHUD.x + TaskHUD.width - 70, TaskHUD.y + 5)

    -- Collapse/Expand button
    love.graphics.setColor(1.0, 0.88, 0.6)
    love.graphics.print(TaskHUD.collapsed and "[+]" or "[-]", TaskHUD.x + TaskHUD.width - 20, TaskHUD.y + 5)

    if not TaskHUD.collapsed then
        -- Title
        love.graphics.setFont(TaskHUD.font)
        love.graphics.setColor(1.0, 0.96, 0.9)
        love.graphics.printf(task.title, TaskHUD.x + 10, TaskHUD.y + 32, TaskHUD.width - 20, "left")

        -- Description
        love.graphics.setFont(TaskHUD.smallFont)
        love.graphics.setColor(0.85, 0.82, 0.78)
        love.graphics.printf(task.desc, TaskHUD.x + 10, TaskHUD.y + 50, TaskHUD.width - 20, "left")

        -- Checklist Items
        local objY = TaskHUD.y + 88
        for _, obj in ipairs(task.objectives) do
            -- Checkbox Box
            love.graphics.setColor(1.0, 0.82, 0.25, 0.6)
            love.graphics.rectangle("line", TaskHUD.x + 10, objY + 2, 11, 11)

            if obj.done then
                love.graphics.setColor(0.2, 0.88, 0.55) -- Mint Check
                love.graphics.rectangle("fill", TaskHUD.x + 12, objY + 4, 7, 7)
                love.graphics.setColor(0.4, 0.88, 0.6)
            else
                love.graphics.setColor(0.9, 0.88, 0.85)
            end

            love.graphics.setFont(TaskHUD.smallFont)
            love.graphics.printf(obj.text, TaskHUD.x + 26, objY + 1, TaskHUD.width - 36, "left")
            objY = objY + 18
        end

        -- Hint Button / Drawer
        if task.hint and task.hint ~= "" and not task.completed then
            local hintBtnY = objY + 4
            love.graphics.setColor(0.25, 0.2, 0.24, 0.85)
            love.graphics.rectangle("fill", TaskHUD.x + 10, hintBtnY, TaskHUD.width - 20, 18, 3, 3)
            love.graphics.setColor(1.0, 0.85, 0.4)
            love.graphics.setFont(TaskHUD.smallFont)
            love.graphics.printf(TaskHUD.showHint and "Hide Hint" or "Need a Hint?", TaskHUD.x + 10, hintBtnY + 2, TaskHUD.width - 20, "center")

            if TaskHUD.showHint then
                love.graphics.setColor(1.0, 0.88, 0.45)
                love.graphics.printf(task.hint, TaskHUD.x + 12, hintBtnY + 22, TaskHUD.width - 24, "left")
            end
        end

        -- Continue Story Button when Completed
        if task.completed then
            local returnY = TaskHUD.y + fullH - 26
            love.graphics.setColor(0.2, 0.88, 0.55, 0.95) -- Mint Button
            love.graphics.rectangle("fill", TaskHUD.x + 10, returnY, TaskHUD.width - 20, 20, 4, 4)
            love.graphics.setColor(0.1, 0.15, 0.12)
            love.graphics.setFont(TaskHUD.font)
            love.graphics.printf("▶ Continue Story", TaskHUD.x + 10, returnY + 1, TaskHUD.width - 20, "center")
        end
    end

    love.graphics.pop()
end

function TaskHUD.mousepressed(x, y, button)
    local task = TaskManager.getCurrentTask()
    if not task or button ~= 1 then return false end

    if x >= TaskHUD.x and x <= TaskHUD.x + TaskHUD.width and y >= TaskHUD.y and y <= TaskHUD.y + 26 then
        if x >= TaskHUD.x + TaskHUD.width - 26 then
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
            local hintBtnY = TaskHUD.y + 110
            if y >= hintBtnY and y <= hintBtnY + 20 then
                TaskHUD.showHint = not TaskHUD.showHint
                AudioManager.playSFX("click")
                return true
            end
        end

        if task.completed and y >= TaskHUD.y + TaskHUD.height - 28 then
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
