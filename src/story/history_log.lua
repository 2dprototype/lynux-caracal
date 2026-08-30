-- src/story/history_log.lua
local CharacterManager = require("src.story.character_mgr")

local HistoryLog = {
    visible = false,
    entries = {},
    scrollOffset = 0,
    maxScroll = 0,
    font = nil,
    nameFont = nil
}

function HistoryLog.init()
    HistoryLog.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    HistoryLog.nameFont = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    HistoryLog.entries = {}
    HistoryLog.scrollOffset = 0
end

function HistoryLog.add(speaker, text, isMonologue)
    table.insert(HistoryLog.entries, {
        speaker = speaker,
        text = text,
        isMonologue = isMonologue
    })
    if #HistoryLog.entries > 100 then
        table.remove(HistoryLog.entries, 1)
    end
end

function HistoryLog.toggle()
    HistoryLog.visible = not HistoryLog.visible
    if HistoryLog.visible then
        HistoryLog.scrollOffset = 0
    end
end

function HistoryLog.wheelmoved(x, y)
    if not HistoryLog.visible then return false end
    HistoryLog.scrollOffset = math.max(0, math.min(HistoryLog.maxScroll, HistoryLog.scrollOffset - y * 30))
    return true
end

function HistoryLog.keypressed(key)
    if not HistoryLog.visible then
        if key == "h" or key == "l" then
            HistoryLog.toggle()
            return true
        end
        return false
    end

    if key == "escape" or key == "h" or key == "space" or key == "return" then
        HistoryLog.visible = false
        return true
    elseif key == "up" then
        HistoryLog.scrollOffset = math.max(0, HistoryLog.scrollOffset - 30)
        return true
    elseif key == "down" then
        HistoryLog.scrollOffset = math.min(HistoryLog.maxScroll, HistoryLog.scrollOffset + 30)
        return true
    end
    return true
end

function HistoryLog.draw()
    if not HistoryLog.visible then return end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local marginX, marginY = 40, 30
    local logW, logH = screenW - marginX * 2, screenH - marginY * 2

    love.graphics.push()

    -- Dim background (Warm Charcoal)
    love.graphics.setColor(0.11, 0.1, 0.14, 0.96)
    love.graphics.rectangle("fill", marginX, marginY, logW, logH, 6, 6)
    love.graphics.setColor(1.0, 0.82, 0.25, 0.9) -- Sunny Yellow Border
    love.graphics.setLineWidth(1.4)
    love.graphics.rectangle("line", marginX, marginY, logW, logH, 6, 6)

    -- Header (Sunny Gold)
    love.graphics.setColor(1.0, 0.85, 0.3)
    love.graphics.setFont(HistoryLog.nameFont)
    love.graphics.print("★ Dialogue Transcript (Press ESC or H to close)", marginX + 16, marginY + 14)
    love.graphics.setColor(1.0, 0.82, 0.25, 0.3)
    love.graphics.line(marginX + 16, marginY + 38, marginX + logW - 16, marginY + 38)

    -- Content list
    local contentY = marginY + 55 - HistoryLog.scrollOffset
    local totalHeight = 0

    for _, entry in ipairs(HistoryLog.entries) do
        local nameStr = entry.isMonologue and "[Thought]" or (entry.speaker or "Protagonist")
        local charInfo = CharacterManager.get(entry.speaker)
        local color = entry.isMonologue and {1.0, 0.85, 0.3} or (charInfo.color or {1.0, 0.9, 0.8})

        if contentY + 40 >= marginY + 50 and contentY <= marginY + logH - 20 then
            love.graphics.setColor(color[1], color[2], color[3], 0.95)
            love.graphics.setFont(HistoryLog.nameFont)
            love.graphics.print(nameStr .. ":", marginX + 24, contentY)

            love.graphics.setColor(0.96, 0.94, 0.9)
            love.graphics.setFont(HistoryLog.font)
            love.graphics.printf(entry.text, marginX + 150, contentY, logW - 175, "left")
        end

        local textH = HistoryLog.font:getHeight() * math.ceil(HistoryLog.font:getWidth(entry.text) / (logW - 175))
        local itemH = math.max(28, textH + 10)
        contentY = contentY + itemH
        totalHeight = totalHeight + itemH
    end

    HistoryLog.maxScroll = math.max(0, totalHeight - (logH - 80))

    love.graphics.pop()
end

return HistoryLog
