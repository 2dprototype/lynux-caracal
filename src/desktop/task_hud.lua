-- src/desktop/task_hud.lua
-- Right‑side collapsible Task/Objective widget with scrollbar
-- Light theme, Windows 10 style

local TaskManager = require("src.tasks.task_manager")
local AudioManager = require("src.core.audio_manager")
local EventBus = require("src.core.event_bus")

local TaskHUD = {
    -- Panel geometry (right‑aligned)
    x = 0,
    y = 40,
    width = 260,
    collapsedWidth = 28,
    height = 0,
    maxHeight = 0,

    collapsed = false,
    showHint = false,          -- hidden by default

    -- Scroll
    scrollOffset = 0,
    maxScroll = 0,
    scrollBarWidth = 10,
    isDraggingScroll = false,
    dragStartY = 0,
    dragStartScroll = 0,

    -- Fonts
    font = nil,
    headerFont = nil,
    smallFont = nil,

    -- For hit detection
    interactiveAreas = {},
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

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    TaskHUD.x = screenW - TaskHUD.width
    TaskHUD.y = 40
    TaskHUD.scrollOffset = 0
    TaskHUD.maxHeight = screenH - 100
    TaskHUD.height = math.min(400, TaskHUD.maxHeight)
    TaskHUD.interactiveAreas = {}
end

function TaskHUD.update(dt)
    -- fixed position
end

function TaskHUD.draw()
    local task = TaskManager.getCurrentTask()
    if not task then return end

    -- Clear previous interactive areas
    TaskHUD.interactiveAreas = {}

    local headerH = 28
    local panelW = TaskHUD.collapsed and TaskHUD.collapsedWidth or TaskHUD.width

    -- For collapsed, we position at the right edge
    local screenW = love.graphics.getWidth()
    local x = TaskHUD.collapsed and (screenW - TaskHUD.collapsedWidth) or TaskHUD.x
    local y = TaskHUD.y
    local panelH = TaskHUD.height

    love.graphics.push()

    -- Shadow only when expanded
    if not TaskHUD.collapsed then
        love.graphics.setColor(0, 0, 0, 0.08)
        love.graphics.rectangle("fill", x + 4, y + 4, panelW, panelH)
    end

    -- Background
    love.graphics.setColor(1, 1, 1, 0.98)
    love.graphics.rectangle("fill", x, y, panelW, panelH)

    -- Border
    if task.completed then
        love.graphics.setColor(0.18, 0.65, 0.35, 0.6)
    else
        love.graphics.setColor(0.0, 0.47, 0.83, 0.5)
    end
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, panelW, panelH)

    if not TaskHUD.collapsed then
        -- Header
        love.graphics.setColor(0.96, 0.97, 0.98)
        love.graphics.rectangle("fill", x, y, panelW, headerH)
        love.graphics.setColor(0.85, 0.88, 0.92)
        love.graphics.line(x, y + headerH, x + panelW, y + headerH)

        -- Header title
        love.graphics.setFont(TaskHUD.headerFont)
        if task.completed then
            love.graphics.setColor(0.18, 0.65, 0.35)
            love.graphics.print("✔ Done", x + 10, y + 4)
        else
            love.graphics.setColor(0.1, 0.12, 0.16)
            love.graphics.print("Objectives", x + 10, y + 4)
        end

        -- XP Badge
        love.graphics.setFont(TaskHUD.smallFont)
        love.graphics.setColor(0.0, 0.55, 0.95)
        love.graphics.print("+" .. tostring(task.xp) .. " XP", x + panelW - 70, y + 6)

        -- Collapse button (>>) – store as interactive
        love.graphics.setColor(0.3, 0.32, 0.36)
        love.graphics.print(">>", x + panelW - 24, y + 6)
        table.insert(TaskHUD.interactiveAreas, {
            type = "collapse",
            x = x + panelW - 28,
            y = y,
            w = 28,
            h = headerH,
        })

        -- Content area with clipping
        local contentX = x
        local contentY = y + headerH
        local contentW = panelW
        local contentH = panelH - headerH

        love.graphics.setScissor(contentX, contentY, contentW, contentH)

        local lineHeight = 20
        local padding = 12
        local yPos = contentY + padding - TaskHUD.scrollOffset

        -- Title (wrapped)
        love.graphics.setFont(TaskHUD.font)
        love.graphics.setColor(0.1, 0.12, 0.16)
        local titleLines = TaskHUD.wrapText(task.title, contentW - 24, TaskHUD.font)
        for _, line in ipairs(titleLines) do
            love.graphics.print(line, contentX + 12, yPos)
            yPos = yPos + lineHeight
        end
        yPos = yPos + 4

        -- Description
        love.graphics.setFont(TaskHUD.smallFont)
        love.graphics.setColor(0.3, 0.32, 0.36)
        local descLines = TaskHUD.wrapText(task.desc, contentW - 24, TaskHUD.smallFont)
        for _, line in ipairs(descLines) do
            love.graphics.print(line, contentX + 12, yPos)
            yPos = yPos + lineHeight
        end
        yPos = yPos + 8

        -- Checklist items (no interactivity, just draw)
        for _, obj in ipairs(task.objectives) do
            love.graphics.setColor(0.7, 0.72, 0.76)
            love.graphics.rectangle("line", contentX + 12, yPos + 2, 12, 12)
            if obj.done then
                love.graphics.setColor(0.18, 0.8, 0.4)
                love.graphics.rectangle("fill", contentX + 14, yPos + 4, 8, 8)
                love.graphics.setColor(0.18, 0.8, 0.4)
            else
                love.graphics.setColor(0.1, 0.12, 0.16)
            end
            local objLines = TaskHUD.wrapText(obj.text, contentW - 44, TaskHUD.smallFont)
            for _, line in ipairs(objLines) do
                love.graphics.print(line, contentX + 30, yPos)
                yPos = yPos + lineHeight
            end
            yPos = yPos + 2
        end

        -- Hint button (store as interactive)
        if task.hint and task.hint ~= "" and not task.completed then
            yPos = yPos + 4
            local hintBtnY = yPos
            love.graphics.setColor(0.95, 0.96, 0.97)
            love.graphics.rectangle("fill", contentX + 12, hintBtnY, contentW - 24, 20, 2, 2)
            love.graphics.setColor(0.0, 0.47, 0.83)
            love.graphics.setFont(TaskHUD.smallFont)
            local hintLabel = TaskHUD.showHint and "Hide Hint" or "Need a Hint?"
            love.graphics.printf(hintLabel, contentX + 12, hintBtnY + 3, contentW - 24, "center")

            -- Store hit area (in global coordinates)
            table.insert(TaskHUD.interactiveAreas, {
                type = "hint",
                x = contentX + 12,
                y = hintBtnY,
                w = contentW - 24,
                h = 20,
            })

            yPos = yPos + 24

            if TaskHUD.showHint then
                love.graphics.setColor(0.1, 0.12, 0.16)
                local hintLines = TaskHUD.wrapText(task.hint, contentW - 24, TaskHUD.smallFont)
                for _, line in ipairs(hintLines) do
                    love.graphics.print(line, contentX + 14, yPos)
                    yPos = yPos + lineHeight
                end
                yPos = yPos + 4
            end
        end

        -- Continue button (store as interactive)
        if task.completed then
            yPos = yPos + 8
            local contY = yPos
            love.graphics.setColor(0.0, 0.47, 0.83, 0.9)
            love.graphics.rectangle("fill", contentX + 12, contY, contentW - 24, 22, 2, 2)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(TaskHUD.font)
            love.graphics.printf("Continue Story", contentX + 12, contY + 2, contentW - 24, "center")

            table.insert(TaskHUD.interactiveAreas, {
                type = "continue",
                x = contentX + 12,
                y = contY,
                w = contentW - 24,
                h = 22,
            })
            yPos = yPos + 30
        end

        yPos = yPos + padding

        -- Compute scroll max
        local totalContentHeight = yPos - (contentY + padding - TaskHUD.scrollOffset)
        TaskHUD.maxScroll = math.max(0, totalContentHeight - contentH)
        if TaskHUD.scrollOffset > TaskHUD.maxScroll then
            TaskHUD.scrollOffset = TaskHUD.maxScroll
        end

        love.graphics.setScissor()

        -- Scrollbar
        if TaskHUD.maxScroll > 0 then
            local barX = contentX + contentW - TaskHUD.scrollBarWidth - 4
            local barY = contentY + 4
            local barH = contentH - 8
            love.graphics.setColor(0.9, 0.92, 0.94)
            love.graphics.rectangle("fill", barX, barY, TaskHUD.scrollBarWidth, barH)

            local visibleRatio = contentH / (totalContentHeight + contentH)
            local thumbH = math.max(20, barH * visibleRatio)
            local thumbY = barY + (barH - thumbH) * (TaskHUD.scrollOffset / math.max(1, TaskHUD.maxScroll))
            love.graphics.setColor(0.6, 0.65, 0.7)
            love.graphics.rectangle("fill", barX, thumbY, TaskHUD.scrollBarWidth, thumbH)

            -- Store scrollbar track as interactive for dragging (we handle separately)
        end

    else
        -- Collapsed view: thin bar on the right edge
        -- Position already set to (screenW - collapsedWidth)
        love.graphics.setColor(0.96, 0.97, 0.98)
        love.graphics.rectangle("fill", x, y, panelW, panelH)
        love.graphics.setColor(0.0, 0.47, 0.83, 0.5)
        love.graphics.rectangle("line", x, y, panelW, panelH)

        -- Expand button (<<) – store as interactive
        love.graphics.setColor(0.1, 0.12, 0.16)
        love.graphics.setFont(TaskHUD.headerFont)
        love.graphics.print("<<", x + 4, y + 8)
        table.insert(TaskHUD.interactiveAreas, {
            type = "expand",
            x = x,
            y = y,
            w = panelW,
            h = panelH,
        })
    end

    love.graphics.pop()
end

-- Helper: wrap text to fit width
function TaskHUD.wrapText(text, maxWidth, font)
    if not text or text == "" then return {""} end
    font = font or TaskHUD.smallFont or love.graphics.getFont()
    local words = {}
    for w in text:gmatch("%S+") do
        table.insert(words, w)
    end
    local lines = {}
    local currentLine = ""
    for _, word in ipairs(words) do
        local testLine = currentLine == "" and word or currentLine .. " " .. word
        if font:getWidth(testLine) <= maxWidth then
            currentLine = testLine
        else
            if currentLine ~= "" then
                table.insert(lines, currentLine)
            end
            currentLine = word
        end
    end
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    return lines
end

-- Mouse handling using interactive areas
function TaskHUD.mousepressed(x, y, button)
    if button ~= 1 then return false end

    -- Check interactive areas first
    for _, area in ipairs(TaskHUD.interactiveAreas) do
        if x >= area.x and x <= area.x + area.w and y >= area.y and y <= area.y + area.h then
            if area.type == "collapse" then
                TaskHUD.collapsed = true
                TaskHUD.scrollOffset = 0
                AudioManager.playSFX("click")
                return true
            elseif area.type == "expand" then
                TaskHUD.collapsed = false
                AudioManager.playSFX("click")
                return true
            elseif area.type == "hint" then
                TaskHUD.showHint = not TaskHUD.showHint
                AudioManager.playSFX("click")
                return true
            elseif area.type == "continue" then
                EventBus.emit("game:request_switch_mode", { mode = "story", transition = "fade" })
                AudioManager.playSFX("click")
                return true
            end
        end
    end

    -- Scrollbar click (only when expanded)
    if not TaskHUD.collapsed and TaskHUD.maxScroll > 0 then
        local contentX = TaskHUD.x
        local contentY = TaskHUD.y + 28
        local contentH = TaskHUD.height - 28
        local barX = contentX + TaskHUD.width - TaskHUD.scrollBarWidth - 4
        if x >= barX and x <= barX + TaskHUD.scrollBarWidth and
           y >= contentY + 4 and y <= contentY + contentH - 4 then
            TaskHUD.isDraggingScroll = true
            TaskHUD.dragStartY = y
            TaskHUD.dragStartScroll = TaskHUD.scrollOffset
            return true
        end
    end

    return false
end

function TaskHUD.mousereleased(x, y, button)
    if button == 1 and TaskHUD.isDraggingScroll then
        TaskHUD.isDraggingScroll = false
        return true
    end
    return false
end

function TaskHUD.mousemoved(x, y, dx, dy)
    if TaskHUD.isDraggingScroll then
        local contentY = TaskHUD.y + 28
        local contentH = TaskHUD.height - 28
        local barY = contentY + 4
        local barH = contentH - 8
        local dy_rel = y - TaskHUD.dragStartY
        local ratio = dy_rel / barH
        TaskHUD.scrollOffset = TaskHUD.dragStartScroll + ratio * TaskHUD.maxScroll
        TaskHUD.scrollOffset = math.max(0, math.min(TaskHUD.maxScroll, TaskHUD.scrollOffset))
        return true
    end
    return false
end

function TaskHUD.wheelmoved(x, y)
    if not TaskHUD.collapsed then
        local scrollAmount = y * 20
        TaskHUD.scrollOffset = math.max(0, math.min(TaskHUD.maxScroll, TaskHUD.scrollOffset + scrollAmount))
        return true
    end
    return false
end

-- Called on window resize
function TaskHUD.resize()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    TaskHUD.x = screenW - TaskHUD.width
    TaskHUD.maxHeight = screenH - 100
    TaskHUD.height = math.min(400, TaskHUD.maxHeight)
    TaskHUD.interactiveAreas = {}
end

return TaskHUD