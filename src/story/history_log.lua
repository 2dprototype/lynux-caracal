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

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

function HistoryLog.init()
    HistoryLog.font = loadCustomFont("font/Nunito-Regular.ttf", 14)
    HistoryLog.nameFont = loadCustomFont("font/IBMPlexSans-Bold.ttf", 15) or loadCustomFont("font/Nunito-Regular.ttf", 15)
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
    local marginX, marginY = 36, 24
    local logW, logH = screenW - marginX * 2, screenH - marginY * 2

    love.graphics.push()

    -- Dim backdrop
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Card Surface
    love.graphics.setColor(0.08, 0.09, 0.12, 0.96)
    love.graphics.rectangle("fill", marginX, marginY, logW, logH, 4, 4)

    -- Header (Clean, no emojis)
    love.graphics.setColor(0.9, 0.92, 0.96)
    love.graphics.setFont(HistoryLog.nameFont)
    love.graphics.print("Dialogue Log (ESC or H to close)", marginX + 16, marginY + 12)
    love.graphics.setColor(0.2, 0.22, 0.28, 0.8)
    love.graphics.line(marginX + 16, marginY + 36, marginX + logW - 16, marginY + 36)

    -- Content list
    local contentY = marginY + 48 - HistoryLog.scrollOffset
    local totalHeight = 0

    for _, entry in ipairs(HistoryLog.entries) do
        local nameStr = entry.isMonologue and "Thought" or (entry.speaker or "Protagonist")
        local charInfo = CharacterManager.get(entry.speaker)
        local color = entry.isMonologue and {0.4, 0.7, 0.95} or (charInfo.color or {0.85, 0.88, 0.92})

        if contentY + 40 >= marginY + 40 and contentY <= marginY + logH - 20 then
            love.graphics.setColor(color[1], color[2], color[3], 0.95)
            love.graphics.setFont(HistoryLog.nameFont)
            love.graphics.print(nameStr .. ":", marginX + 24, contentY)

            love.graphics.setColor(0.92, 0.94, 0.96)
            love.graphics.setFont(HistoryLog.font)
            love.graphics.printf(entry.text, marginX + 130, contentY, logW - 150, "left")
        end

        local textH = HistoryLog.font:getHeight() * math.ceil(HistoryLog.font:getWidth(entry.text) / (logW - 150))
        local itemH = math.max(28, textH + 8)
        contentY = contentY + itemH
        totalHeight = totalHeight + itemH
    end

    HistoryLog.maxScroll = math.max(0, totalHeight - (logH - 70))

    love.graphics.pop()
end

return HistoryLog
