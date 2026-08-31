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

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

function ChoiceBox.init()
    ChoiceBox.font = loadCustomFont("font/Nunito-Regular.ttf", 15)
    ChoiceBox.promptFont = loadCustomFont("font/IBMPlexSans-Bold.ttf", 16) or loadCustomFont("font/Nunito-Regular.ttf", 16)
end

function ChoiceBox.show(prompt, options, callback)
    ChoiceBox.visible = true
    ChoiceBox.prompt = prompt or "Choose an option:"
    ChoiceBox.options = options or {}
    ChoiceBox.selectedIndex = 1
    ChoiceBox.onSelect = callback
    AudioManager.playSFX("notification", 1.1)
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
    AudioManager.playSFX("click", 1.2)
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
    local itemW = math.min(520, screenW - 60)
    local itemH = 44
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
    local itemW = math.min(520, screenW - 60)
    local itemH = 44
    local totalH = #ChoiceBox.options * (itemH + 10)
    local startY = (screenH - totalH) / 2

    for i, opt in ipairs(ChoiceBox.options) do
        local optY = startY + (i - 1) * (itemH + 10)
        local optX = (screenW - itemW) / 2
        if x >= optX and x <= optX + itemW and y >= optY and y <= optY + itemH then
            if ChoiceBox.selectedIndex ~= i then
                ChoiceBox.selectedIndex = i
                AudioManager.playSFX("tick", 1.2, 0.3)
            end
            break
        end
    end
end

function ChoiceBox.draw()
    if not ChoiceBox.visible then return end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local itemW = math.min(520, screenW - 60)
    local itemH = 44
    local totalH = #ChoiceBox.options * (itemH + 10) + 40
    local startY = (screenH - totalH) / 2

    love.graphics.push()

    -- Dim Backdrop
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Prompt Text
    love.graphics.setFont(ChoiceBox.promptFont or ChoiceBox.font)
    love.graphics.setColor(0.92, 0.94, 0.98)
    love.graphics.printf(ChoiceBox.prompt, 0, startY - 32, screenW, "center")

    -- Choice Option Cards
    for i, opt in ipairs(ChoiceBox.options) do
        local optY = startY + (i - 1) * (itemH + 10)
        local optX = (screenW - itemW) / 2
        local isSelected = (i == ChoiceBox.selectedIndex)

        -- Soft Drop Shadow
        love.graphics.setColor(0, 0, 0, 0.25)
        love.graphics.rectangle("fill", optX + 2, optY + 2, itemW, itemH, 4, 4)

        -- Clean Flat Card (Material Style)
        if isSelected then
            love.graphics.setColor(0.18, 0.24, 0.35, 0.98)
        else
            love.graphics.setColor(0.1, 0.12, 0.16, 0.92)
        end
        love.graphics.rectangle("fill", optX, optY, itemW, itemH, 4, 4)

        -- Left indicator accent strip when selected
        if isSelected then
            love.graphics.setColor(0.0, 0.47, 0.83, 1.0) -- Windows Accent Blue
            love.graphics.rectangle("fill", optX, optY, 4, itemH, 2, 2)
        end

        -- Option Number & Text
        love.graphics.setFont(ChoiceBox.font)
        if isSelected then
            love.graphics.setColor(0.35, 0.75, 1.0)
            love.graphics.print(tostring(i) .. ".", optX + 16, optY + 11)
            love.graphics.setColor(1.0, 1.0, 1.0)
        else
            love.graphics.setColor(0.6, 0.65, 0.75)
            love.graphics.print(tostring(i) .. ".", optX + 16, optY + 11)
            love.graphics.setColor(0.85, 0.88, 0.92)
        end

        love.graphics.printf(opt.text, optX + 38, optY + 11, itemW - 52, "left")
    end

    love.graphics.pop()
end

return ChoiceBox
