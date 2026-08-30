-- src/story/choice_box.lua
local AudioManager = require("src.core.audio_manager")

local ChoiceBox = {
    visible = false,
    prompt = "",
    options = {},
    selectedIndex = 1,
    font = nil,
    promptFont = nil,
    onSelect = nil
}

function ChoiceBox.init()
    ChoiceBox.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    ChoiceBox.promptFont = love.graphics.newFont("font/Nunito-Regular.ttf", 15) or love.graphics.newFont(15)
end

function ChoiceBox.show(prompt, options, callback)
    ChoiceBox.visible = true
    ChoiceBox.prompt = prompt or "Select an action:"
    ChoiceBox.options = options or {}
    ChoiceBox.selectedIndex = 1
    ChoiceBox.onSelect = callback
    AudioManager.playSFX("notification", 1.2)
end

function ChoiceBox.hide()
    ChoiceBox.visible = false
    ChoiceBox.options = {}
    ChoiceBox.onSelect = nil
end

function ChoiceBox.selectCurrent()
    if not ChoiceBox.visible or #ChoiceBox.options == 0 then return end
    local chosen = ChoiceBox.options[ChoiceBox.selectedIndex]
    ChoiceBox.visible = false
    AudioManager.playSFX("click", 1.3)
    if ChoiceBox.onSelect then
        ChoiceBox.onSelect(chosen)
    end
end

function ChoiceBox.keypressed(key)
    if not ChoiceBox.visible then return false end

    if key == "up" or key == "w" then
        ChoiceBox.selectedIndex = math.max(1, ChoiceBox.selectedIndex - 1)
        AudioManager.playSFX("tick", 1.1)
        return true
    elseif key == "down" or key == "s" then
        ChoiceBox.selectedIndex = math.min(#ChoiceBox.options, ChoiceBox.selectedIndex + 1)
        AudioManager.playSFX("tick", 1.1)
        return true
    elseif key == "return" or key == "space" then
        ChoiceBox.selectCurrent()
        return true
    elseif tonumber(key) and tonumber(key) >= 1 and tonumber(key) <= #ChoiceBox.options then
        ChoiceBox.selectedIndex = tonumber(key)
        ChoiceBox.selectCurrent()
        return true
    end
    return false
end

function ChoiceBox.mousepressed(x, y, button)
    if not ChoiceBox.visible or button ~= 1 then return false end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local itemW = math.min(480, screenW - 80)
    local itemH = 38
    local totalH = #ChoiceBox.options * (itemH + 10)
    local startY = (screenH - totalH) / 2

    for i, opt in ipairs(ChoiceBox.options) do
        local optY = startY + (i - 1) * (itemH + 10)
        local optX = (screenW - itemW) / 2
        if x >= optX and x <= optX + itemW and y >= optY and y <= optY + itemH then
            ChoiceBox.selectedIndex = i
            ChoiceBox.selectCurrent()
            return true
        end
    end
    return false
end

function ChoiceBox.mousemoved(x, y)
    if not ChoiceBox.visible then return end
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local itemW = math.min(480, screenW - 80)
    local itemH = 38
    local totalH = #ChoiceBox.options * (itemH + 10)
    local startY = (screenH - totalH) / 2

    for i, opt in ipairs(ChoiceBox.options) do
        local optY = startY + (i - 1) * (itemH + 10)
        local optX = (screenW - itemW) / 2
        if x >= optX and x <= optX + itemW and y >= optY and y <= optY + itemH then
            if ChoiceBox.selectedIndex ~= i then
                ChoiceBox.selectedIndex = i
                AudioManager.playSFX("tick", 1.3, 0.3)
            end
            break
        end
    end
end

function ChoiceBox.draw()
    if not ChoiceBox.visible then return end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local itemW = math.min(480, screenW - 80)
    local itemH = 38
    local totalH = #ChoiceBox.options * (itemH + 10) + 40
    local startY = (screenH - totalH) / 2

    love.graphics.push()

    -- Dark backdrop overlay
    love.graphics.setColor(0.04, 0.06, 0.09, 0.65)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Prompt Text
    love.graphics.setFont(ChoiceBox.promptFont or ChoiceBox.font)
    love.graphics.setColor(0.92, 0.95, 1.0)
    love.graphics.printf(ChoiceBox.prompt, 0, startY - 30, screenW, "center")

    -- Choice Option Cards
    for i, opt in ipairs(ChoiceBox.options) do
        local optY = startY + (i - 1) * (itemH + 10)
        local optX = (screenW - itemW) / 2
        local isSelected = (i == ChoiceBox.selectedIndex)

        -- Drop Shadow
        love.graphics.setColor(0, 0, 0, 0.25)
        love.graphics.rectangle("fill", optX + 2, optY + 2, itemW, itemH, 4, 4)

        -- Background
        if isSelected then
            love.graphics.setColor(0.15, 0.28, 0.42, 0.96)
        else
            love.graphics.setColor(0.1, 0.13, 0.18, 0.92)
        end
        love.graphics.rectangle("fill", optX, optY, itemW, itemH, 4, 4)

        -- Border (Retro Electric Azure when selected)
        if isSelected then
            love.graphics.setColor(0.2, 0.75, 1.0, 1.0)
            love.graphics.setLineWidth(1.5)
        else
            love.graphics.setColor(0.2, 0.26, 0.35, 0.7)
            love.graphics.setLineWidth(1)
        end
        love.graphics.rectangle("line", optX, optY, itemW, itemH, 4, 4)

        -- Number Tag
        love.graphics.setFont(ChoiceBox.font)
        if isSelected then
            love.graphics.setColor(0.3, 0.85, 1.0)
            love.graphics.print("▶ [" .. tostring(i) .. "]", optX + 12, optY + 10)
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.5, 0.6, 0.7)
            love.graphics.print("  [" .. tostring(i) .. "]", optX + 12, optY + 10)
            love.graphics.setColor(0.85, 0.88, 0.92)
        end

        -- Option Text
        love.graphics.printf(opt.text, optX + 56, optY + 10, itemW - 68, "left")
    end

    love.graphics.pop()
end

return ChoiceBox
