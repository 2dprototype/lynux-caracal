-- src/story/dialogue_box.lua
local utf8 = require("utf8")
local AudioManager = require("src.core.audio_manager")
local CharacterManager = require("src.story.character_mgr")

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
    boxX = 0,
    boxY = 0,
    boxW = 0,
    boxH = 0,
    onFinishLine = nil
}

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

function DialogueBox.init()
    DialogueBox.font = loadCustomFont("font/Nunito-Regular.ttf", 15)
    DialogueBox.nameFont = loadCustomFont("font/IBMPlexSans-Bold.ttf", 16) or loadCustomFont("font/Nunito-Regular.ttf", 16)
    DialogueBox.italicFont = loadCustomFont("font/Nunito-Regular.ttf", 15)
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

function DialogueBox.draw()
    if not DialogueBox.visible then return end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local marginX = 28
    local boxH = 125
    local boxW = screenW - marginX * 2
    local boxX = marginX
    local boxY = screenH - boxH - 18

    DialogueBox.boxX = boxX
    DialogueBox.boxY = boxY
    DialogueBox.boxW = boxW
    DialogueBox.boxH = boxH

    love.graphics.push()

    -- Subtle soft shadow underneath the plate
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", boxX + 2, boxY + 3, boxW, boxH, 4, 4)

    -- Material Solid Plate (Clean dark surface, NO BORDERS as requested)
    love.graphics.setColor(0.08, 0.09, 0.12, 0.92)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 4, 4)

    if DialogueBox.isMonologue then
        -- Thought / Internal Monologue mode
        -- Subtle Material Left Accent Indicator Strip
        love.graphics.setColor(0.35, 0.65, 0.95, 0.9)
        love.graphics.rectangle("fill", boxX, boxY, 4, boxH, 2, 2)

        -- Thought label
        love.graphics.setFont(DialogueBox.nameFont or DialogueBox.font)
        love.graphics.setColor(0.4, 0.7, 0.95, 0.95)
        love.graphics.print("Thought", boxX + 18, boxY + 10)

        -- Dialogue Text
        love.graphics.setFont(DialogueBox.italicFont or DialogueBox.font)
        love.graphics.setColor(0.92, 0.94, 0.96)
        love.graphics.printf(DialogueBox.displayText, boxX + 18, boxY + 38, boxW - 36, "left")

    else
        -- Character Dialogue mode
        local charInfo = CharacterManager.get(DialogueBox.speaker)
        local accentColor = charInfo.color or {0.35, 0.65, 0.95}

        -- Subtle Material Left Accent Indicator Strip with character's color
        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.95)
        love.graphics.rectangle("fill", boxX, boxY, 4, boxH, 2, 2)

        -- Speaker Name (Clean typography, no emojis, no borders)
        local nameStr = charInfo.name or DialogueBox.speaker or "Protagonist"
        love.graphics.setFont(DialogueBox.nameFont or DialogueBox.font)
        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3])
        love.graphics.print(nameStr, boxX + 18, boxY + 10)

        -- Dialogue Text
        love.graphics.setFont(DialogueBox.font)
        love.graphics.setColor(0.95, 0.96, 0.98)
        love.graphics.printf(DialogueBox.displayText, boxX + 18, boxY + 38, boxW - 36, "left")
    end

    -- Clean blinking advance prompt (Chevron / Dash cursor, no emojis)
    if not DialogueBox.isTyping then
        local pulseAlpha = 0.35 + 0.65 * math.abs(math.sin(DialogueBox.promptPulseTimer * 4))
        love.graphics.setColor(0.85, 0.88, 0.92, pulseAlpha)
        love.graphics.setFont(DialogueBox.font)
        love.graphics.print(">", boxX + boxW - 22, boxY + boxH - 28)
    end

    love.graphics.pop()
end

return DialogueBox
