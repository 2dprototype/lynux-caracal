-- src/story/dialogue_box.lua
-- Responsive Dialogue Box & Interactive Control Buttons (ASCII only, zero emojis)

local utf8 = require("utf8")
local AudioManager = require("src.core.audio_manager")
local CharacterManager = require("src.story.character_mgr")
local Viewport = require("src.core.viewport")

local DialogueBox = {
    visible = true,
    speaker = nil,
    fullText = "",
    displayText = "",
    isMonologue = false,
    charIndex = 0,
    typeTimer = 0,
    typeSpeed = 0.022,
    isTyping = false,
    promptPulseTimer = 0,
    font = nil,
    nameFont = nil,
    italicFont = nil,
    btnFont = nil,
    boxX = 0,
    boxY = 0,
    boxW = 0,
    boxH = 0,
    hoveredBtn = nil,
    onFinishLine = nil
}

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

function DialogueBox.init()
    DialogueBox.font = loadCustomFont("font/Nunito-Regular.ttf", 15)
    DialogueBox.nameFont = loadCustomFont("font/IBMPlexSans-Bold.ttf", 15) or loadCustomFont("font/Nunito-Regular.ttf", 15)
    DialogueBox.italicFont = loadCustomFont("font/Nunito-Regular.ttf", 15)
    DialogueBox.btnFont = loadCustomFont("font/IBMPlexSans-Bold.ttf", 11) or loadCustomFont("font/Nunito-Regular.ttf", 11)
    DialogueBox.hoveredBtn = nil
end

function DialogueBox.showDialogue(speaker, text, isMonologue, onFinish)
    DialogueBox.visible = true
    DialogueBox.speaker = speaker
    DialogueBox.fullText = text or ""
    DialogueBox.displayText = ""
    DialogueBox.isMonologue = isMonologue or (speaker == nil or speaker == "" or speaker == "Monologue")
    DialogueBox.charIndex = 0
    DialogueBox.typeTimer = 0
    DialogueBox.isTyping = true
    DialogueBox.onFinishLine = onFinish
end

function DialogueBox.finishTyping()
    DialogueBox.charIndex = utf8.len(DialogueBox.fullText) or string.len(DialogueBox.fullText)
    DialogueBox.displayText = DialogueBox.fullText
    DialogueBox.isTyping = false
end

function DialogueBox.advance()
    if DialogueBox.isTyping then
        DialogueBox.finishTyping()
        AudioManager.playSFX("click", 1.2)
        return false
    else
        AudioManager.playSFX("click", 1.0)
        return true
    end
end

function DialogueBox.getButtons(boxX, boxY, boxW, boxH, isAuto)
    local btnH = 22
    local btnY = boxY + 8
    local gap = 6
    local curRight = boxX + boxW - 12

    local btns = {
        { id = "next", label = "[ NEXT > ]", w = 68, active = false },
        { id = "skip", label = "[ SKIP >> ]", w = 68, active = false },
        { id = "auto", label = isAuto and "[ AUTO: ON ]" or "[ AUTO ]", w = isAuto and 80 or 60, active = isAuto },
        { id = "log",  label = "[ LOG ]", w = 52, active = false }
    }

    local result = {}
    for _, btn in ipairs(btns) do
        curRight = curRight - btn.w
        btn.x = curRight
        btn.y = btnY
        btn.h = btnH
        table.insert(result, btn)
        curRight = curRight - gap
    end

    return result
end

function DialogueBox.mousepressed(x, y, button, StoryEngine)
    if not DialogueBox.visible or button ~= 1 then return false end

    local isAuto = StoryEngine and StoryEngine.autoPlay
    local btns = DialogueBox.getButtons(DialogueBox.boxX, DialogueBox.boxY, DialogueBox.boxW, DialogueBox.boxH, isAuto)

    for _, btn in ipairs(btns) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.id == "next" then
                if DialogueBox.isTyping then
                    DialogueBox.finishTyping()
                    AudioManager.playSFX("click", 1.2)
                elseif StoryEngine then
                    StoryEngine.advance()
                end
                return true

            elseif btn.id == "skip" then
                if DialogueBox.isTyping then
                    DialogueBox.finishTyping()
                end
                if StoryEngine then
                    StoryEngine.advance()
                end
                AudioManager.playSFX("click", 1.4)
                return true

            elseif btn.id == "auto" then
                if StoryEngine then
                    StoryEngine.autoPlay = not StoryEngine.autoPlay
                end
                AudioManager.playSFX("click", 1.2)
                return true

            elseif btn.id == "log" then
                local HistoryLog = require("src.story.history_log")
                HistoryLog.toggle()
                AudioManager.playSFX("click", 1.2)
                return true
            end
        end
    end

    -- Click inside the dialogue box area to advance
    if x >= DialogueBox.boxX and x <= DialogueBox.boxX + DialogueBox.boxW and
       y >= DialogueBox.boxY and y <= DialogueBox.boxY + DialogueBox.boxH then
        if DialogueBox.isTyping then
            DialogueBox.finishTyping()
            AudioManager.playSFX("click", 1.2)
        elseif StoryEngine then
            StoryEngine.advance()
        end
        return true
    end

    return false
end

function DialogueBox.mousemoved(x, y)
    if not DialogueBox.visible then return end
    DialogueBox.hoveredBtn = nil

    local btns = DialogueBox.getButtons(DialogueBox.boxX, DialogueBox.boxY, DialogueBox.boxW, DialogueBox.boxH, false)
    for _, btn in ipairs(btns) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            DialogueBox.hoveredBtn = btn.id
            break
        end
    end
end

function DialogueBox.update(dt)
    if not DialogueBox.visible then return end

    DialogueBox.promptPulseTimer = DialogueBox.promptPulseTimer + dt

    if DialogueBox.isTyping then
        DialogueBox.typeTimer = DialogueBox.typeTimer + dt
        local totalChars = utf8.len(DialogueBox.fullText) or string.len(DialogueBox.fullText)

        while DialogueBox.typeTimer >= DialogueBox.typeSpeed and DialogueBox.charIndex < totalChars do
            DialogueBox.typeTimer = DialogueBox.typeTimer - DialogueBox.typeSpeed
            DialogueBox.charIndex = DialogueBox.charIndex + 1

            local byteOffset = utf8.offset(DialogueBox.fullText, DialogueBox.charIndex + 1)
            if byteOffset then
                DialogueBox.displayText = string.sub(DialogueBox.fullText, 1, byteOffset - 1)
            else
                DialogueBox.displayText = DialogueBox.fullText
            end

            if DialogueBox.charIndex % 3 == 1 then
                if DialogueBox.isMonologue then
                    AudioManager.playSFX("typewriter", 1.0 + math.random() * 0.1, 0.3)
                else
                    AudioManager.playSFX("blip_low", 1.0 + math.random() * 0.1, 0.3)
                end
            end
        end

        if DialogueBox.charIndex >= totalChars then
            DialogueBox.isTyping = false
            DialogueBox.displayText = DialogueBox.fullText
        end
    end
end

function DialogueBox.draw(isAutoPlay)
    if not DialogueBox.visible then return end

    local screenW, screenH = Viewport.getWidth(), Viewport.getHeight()
    local marginX = math.max(16, math.floor(screenW * 0.035))
    local boxW = math.min(screenW - marginX * 2, 920)
    local boxH = math.max(115, math.min(150, math.floor(screenH * 0.28)))
    local boxX = math.floor((screenW - boxW) / 2)
    local boxY = math.floor(screenH - boxH - math.max(10, math.floor(screenH * 0.025)))

    DialogueBox.boxX = boxX
    DialogueBox.boxY = boxY
    DialogueBox.boxW = boxW
    DialogueBox.boxH = boxH

    love.graphics.push()

    -- 1. Soft Shadow
    -- love.graphics.setColor(0, 0, 0, 0.45)
    -- love.graphics.rectangle("fill", boxX + 2, boxY + 3, boxW, boxH, 6, 6)

    -- 2. Material Dark Navy Solid Plate
    love.graphics.setColor(0.06, 0.08, 0.14, 0.75)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 6, 6)

    -- 3. Speaker / Accent Strip
    if DialogueBox.isMonologue then
        love.graphics.setColor(0.35, 0.65, 0.95, 0.8)
        love.graphics.rectangle("fill", boxX, boxY, 4, boxH, 2, 2)

        love.graphics.setFont(DialogueBox.nameFont or DialogueBox.font)
        love.graphics.setColor(0.40, 0.72, 0.8)
        love.graphics.print("Thought", boxX + 16, boxY + 10)

        love.graphics.setFont(DialogueBox.italicFont or DialogueBox.font)
        love.graphics.setColor(0.92, 0.94, 0.87)
        love.graphics.printf(DialogueBox.displayText, boxX + 16, boxY + 36, boxW - 32, "left")

    else
        local charInfo = CharacterManager.get(DialogueBox.speaker)
        local accentColor = charInfo.color or {0.35, 0.65, 0.8}

        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.8)
        love.graphics.rectangle("fill", boxX, boxY, 4, boxH, 2, 2)

        local nameStr = charInfo.name or DialogueBox.speaker or "Protagonist"
        love.graphics.setFont(DialogueBox.nameFont or DialogueBox.font)
        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3])
        love.graphics.print(nameStr, boxX + 16, boxY + 10)

        love.graphics.setFont(DialogueBox.font)
        love.graphics.setColor(0.95, 0.96, 0.8)
        love.graphics.printf(DialogueBox.displayText, boxX + 16, boxY + 36, boxW - 32, "left")
    end

    -- 4. Interactive Control Buttons (ASCII only)
    local btns = DialogueBox.getButtons(boxX, boxY, boxW, boxH, isAutoPlay)
    love.graphics.setFont(DialogueBox.btnFont or DialogueBox.font)

    for _, btn in ipairs(btns) do
        local isHover = (DialogueBox.hoveredBtn == btn.id)

        if btn.active then
            love.graphics.setColor(0.15, 0.50, 0.85, 0.8)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 3, 3)
            love.graphics.setColor(1, 1, 1)
        elseif isHover then
            love.graphics.setColor(0.18, 0.24, 0.36, 0.95)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 3, 3)
            love.graphics.setColor(0.35, 0.75, 1.0)
        else
            love.graphics.setColor(0.10, 0.13, 0.20, 0.8)
            love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 3, 3)
            love.graphics.setColor(0.65, 0.72, 0.82)
        end

        love.graphics.printf(btn.label, btn.x, btn.y + 4, btn.w, "center")
    end

    -- 5. Advance Indicator Cursor
    if not DialogueBox.isTyping then
        local pulseAlpha = 0.35 + 0.65 * math.abs(math.sin(DialogueBox.promptPulseTimer * 4))
        love.graphics.setColor(0.85, 0.88, 0.92, pulseAlpha)
        love.graphics.setFont(DialogueBox.font)
        love.graphics.print(">", boxX + boxW - 20, boxY + boxH - 26)
    end

    love.graphics.pop()
end

return DialogueBox
