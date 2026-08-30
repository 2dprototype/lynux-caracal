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
    typeSpeed = 0.022, -- fast and responsive typewriter
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

function DialogueBox.init()
    DialogueBox.font = love.graphics.newFont("font/Nunito-Regular.ttf", 15) or love.graphics.newFont(15)
    DialogueBox.nameFont = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    DialogueBox.italicFont = love.graphics.newFont("font/Nunito-Regular.ttf", 15) or love.graphics.newFont(15)
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
        return false -- consumed to reveal entire line
    else
        AudioManager.playSFX("click", 1.0)
        return true -- ready for next line
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

            -- Subtle audio click on characters
            if DialogueBox.charIndex % 3 == 1 then
                if DialogueBox.isMonologue then
                    AudioManager.playSFX("typewriter", 0.95 + math.random() * 0.1, 0.35)
                else
                    AudioManager.playSFX("blip_low", 1.0 + math.random() * 0.1, 0.35)
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
    local marginX = 36
    local boxH = 120
    local boxW = screenW - marginX * 2
    local boxX = marginX
    local boxY = screenH - boxH - 20

    DialogueBox.boxX = boxX
    DialogueBox.boxY = boxY
    DialogueBox.boxW = boxW
    DialogueBox.boxH = boxH

    love.graphics.push()

    if DialogueBox.isMonologue then
        -- Minimalist Monologue Panel (Sleek Dark Indigo Plate)
        -- Drop Shadow
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", boxX + 3, boxY + 3, boxW, boxH, 6, 6)

        -- Panel Background
        love.graphics.setColor(0.08, 0.1, 0.16, 0.94)
        love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 6, 6)

        -- Retro Cyan Accent Border
        love.graphics.setColor(0.2, 0.7, 0.95, 0.85)
        love.graphics.setLineWidth(1.2)
        love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 6, 6)

        -- Thought Badge Pill
        love.graphics.setColor(0.12, 0.25, 0.38, 0.95)
        love.graphics.rectangle("fill", boxX + 16, boxY - 12, 115, 20, 4, 4)
        love.graphics.setColor(0.3, 0.85, 1.0, 0.9)
        love.graphics.rectangle("line", boxX + 16, boxY - 12, 115, 20, 4, 4)
        
        love.graphics.setFont(DialogueBox.nameFont or DialogueBox.font)
        love.graphics.setColor(0.4, 0.9, 1.0)
        love.graphics.print("« Thought »", boxX + 26, boxY - 10)

        -- Text Content
        love.graphics.setFont(DialogueBox.italicFont or DialogueBox.font)
        love.graphics.setColor(0.9, 0.95, 1.0)
        love.graphics.printf(DialogueBox.displayText, boxX + 22, boxY + 20, boxW - 44, "left")

    else
        -- Standard Dialogue Panel (Minimalist Retro Charcoal)
        local charInfo = CharacterManager.get(DialogueBox.speaker)
        local accentColor = charInfo.color or {0.2, 0.7, 0.95}

        -- Drop Shadow
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", boxX + 3, boxY + 3, boxW, boxH, 6, 6)

        -- Background
        love.graphics.setColor(0.09, 0.11, 0.16, 0.95)
        love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 6, 6)

        -- Accent Border
        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.85)
        love.graphics.setLineWidth(1.2)
        love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 6, 6)

        -- Speaker Name Tag (Left Card)
        local nameStr = charInfo.name or DialogueBox.speaker or "???"
        local nameWidth = (DialogueBox.nameFont or DialogueBox.font):getWidth(nameStr) + 32
        
        love.graphics.setColor(0.14, 0.17, 0.24, 0.98)
        love.graphics.rectangle("fill", boxX + 16, boxY - 12, nameWidth, 22, 4, 4)
        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.9)
        love.graphics.rectangle("line", boxX + 16, boxY - 12, nameWidth, 22, 4, 4)

        -- Character Color Dot
        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3])
        love.graphics.circle("fill", boxX + 25, boxY - 1, 4)

        -- Name Text
        love.graphics.setFont(DialogueBox.nameFont or DialogueBox.font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(nameStr, boxX + 34, boxY - 10)

        -- Text Content
        love.graphics.setFont(DialogueBox.font)
        love.graphics.setColor(0.95, 0.96, 0.98)
        love.graphics.printf(DialogueBox.displayText, boxX + 22, boxY + 20, boxW - 44, "left")
    end

    -- Minimalist Pulsing Prompt Indicator
    if not DialogueBox.isTyping then
        local pulseAlpha = 0.4 + 0.6 * math.abs(math.sin(DialogueBox.promptPulseTimer * 4))
        love.graphics.setColor(0.3, 0.85, 1.0, pulseAlpha)
        local arrowX = boxX + boxW - 24
        local arrowY = boxY + boxH - 18
        love.graphics.polygon("fill", arrowX, arrowY, arrowX + 8, arrowY, arrowX + 4, arrowY + 6)
    end

    love.graphics.pop()
end

return DialogueBox
