-- src/story/story_engine.lua
local EventBus = require("src.core.event_bus")
local AudioManager = require("src.core.audio_manager")
local PlayerStats = require("src.core.player_stats")
local DialogueBox = require("src.story.dialogue_box")
local ChoiceBox = require("src.story.choice_box")
local SceneView = require("src.story.scene_view")
local CharacterManager = require("src.story.character_mgr")
local HistoryLog = require("src.story.history_log")
local TaskManager = require("src.tasks.task_manager")

local StoryEngine = {
    script = {},
    labels = {},
    currentIndex = 0,
    waitingForInput = false,
    waitingForChoice = false,
    waitTimer = 0,
    autoPlay = false,
    autoPlayTimer = 0,
    autoPlayDelay = 2.0,
    isFinished = false
}

function StoryEngine.init()
    DialogueBox.init()
    ChoiceBox.init()
    SceneView.init()
    CharacterManager.init()
    HistoryLog.init()
    StoryEngine.script = {}
    StoryEngine.labels = {}
    StoryEngine.currentIndex = 0
    StoryEngine.waitingForInput = false
    StoryEngine.waitingForChoice = false
    StoryEngine.isFinished = false

    EventBus.on("game:mode_switched", function(data)
        if data and data.to == "story" then
            local currentStep = StoryEngine.script[StoryEngine.currentIndex]
            if currentStep and currentStep.type == "switch_mode" then
                StoryEngine.nextStep()
            end
        end
    end, "story_engine_mode_switch")
end

function StoryEngine.loadScript(scriptData)
    StoryEngine.script = scriptData or {}
    StoryEngine.labels = {}
    StoryEngine.currentIndex = 0
    StoryEngine.waitingForInput = false
    StoryEngine.waitingForChoice = false
    StoryEngine.isFinished = false

    -- Index all labels for quick branching
    for i, step in ipairs(StoryEngine.script) do
        if step.type == "label" and step.name then
            StoryEngine.labels[step.name] = i
        end
    end

    StoryEngine.nextStep()
end

function StoryEngine.restart()
    StoryEngine.currentIndex = 0
    StoryEngine.waitingForInput = false
    StoryEngine.waitingForChoice = false
    StoryEngine.isFinished = false
    CharacterManager.init()
    DialogueBox.init()
    ChoiceBox.hide()
    HistoryLog.init()
    StoryEngine.nextStep()
end

function StoryEngine.jumpToLabel(labelName)
    local idx = StoryEngine.labels[labelName]
    if idx then
        StoryEngine.currentIndex = idx
        StoryEngine.nextStep()
    else
        print("[StoryEngine Warning] Unknown label: " .. tostring(labelName))
    end
end

function StoryEngine.nextStep()
    if StoryEngine.waitingForChoice then return end

    StoryEngine.currentIndex = StoryEngine.currentIndex + 1
    if StoryEngine.currentIndex > #StoryEngine.script then
        StoryEngine.isFinished = true
        return
    end

    local step = StoryEngine.script[StoryEngine.currentIndex]
    if not step then return end

    if step.type == "say" then
        DialogueBox.showDialogue(step.speaker, step.text, false)
        HistoryLog.add(step.speaker, step.text, false)
        StoryEngine.waitingForInput = true

    elseif step.type == "monologue" or step.type == "thought" then
        DialogueBox.showDialogue("Monologue", step.text, true)
        HistoryLog.add("Monologue", step.text, true)
        StoryEngine.waitingForInput = true

    elseif step.type == "bg" then
        SceneView.setScene(step.name)
        StoryEngine.nextStep()

    elseif step.type == "char_show" then
        CharacterManager.show(step.char, step.pos, step.expr)
        StoryEngine.nextStep()

    elseif step.type == "char_hide" then
        CharacterManager.hide(step.pos)
        StoryEngine.nextStep()

    elseif step.type == "sfx" then
        AudioManager.playSFX(step.name, step.pitch, step.volume)
        StoryEngine.nextStep()

    elseif step.type == "music" then
        AudioManager.playBGM(step.track, step.loop)
        StoryEngine.nextStep()

    elseif step.type == "choice" then
        DialogueBox.visible = false
        StoryEngine.waitingForChoice = true
        ChoiceBox.show(step.prompt, step.options, function(selectedOption)
            StoryEngine.waitingForChoice = false
            if selectedOption.action then
                selectedOption.action(StoryEngine)
            end
            if selectedOption.target then
                StoryEngine.jumpToLabel(selectedOption.target)
            else
                StoryEngine.nextStep()
            end
        end)

    elseif step.type == "task" then
        TaskManager.setTask(step.task)
        StoryEngine.nextStep()

    elseif step.type == "switch_mode" then
        EventBus.emit("game:request_switch_mode", {
            mode = step.mode or "desktop",
            transition = step.transition or "crt_zoom"
        })
        -- Don't auto-advance index so returning resumes properly or steps can continue on return
        StoryEngine.waitingForInput = false

    elseif step.type == "flag" then
        PlayerStats.setFlag(step.name, step.value)
        StoryEngine.nextStep()

    elseif step.type == "if_flag" then
        local val = PlayerStats.getFlag(step.flag)
        if val == step.value then
            if step.then_jump then StoryEngine.jumpToLabel(step.then_jump) else StoryEngine.nextStep() end
        else
            if step.else_jump then StoryEngine.jumpToLabel(step.else_jump) else StoryEngine.nextStep() end
        end

    elseif step.type == "jump" then
        StoryEngine.jumpToLabel(step.target)

    elseif step.type == "label" then
        -- Labels are pass-through
        StoryEngine.nextStep()

    elseif step.type == "wait" then
        StoryEngine.waitTimer = step.duration or 1.0

    elseif step.type == "custom" then
        if step.fn then step.fn(StoryEngine) end
        StoryEngine.nextStep()
    end
end

function StoryEngine.advance()
    if HistoryLog.visible then return end

    if StoryEngine.waitingForInput then
        local readyForNext = DialogueBox.advance()
        if readyForNext then
            StoryEngine.waitingForInput = false
            StoryEngine.nextStep()
        end
    end
end

function StoryEngine.update(dt)
    SceneView.update(dt)
    DialogueBox.update(dt)

    if StoryEngine.waitTimer > 0 then
        StoryEngine.waitTimer = StoryEngine.waitTimer - dt
        if StoryEngine.waitTimer <= 0 then
            StoryEngine.nextStep()
        end
    end

    -- Auto-play handling
    if StoryEngine.autoPlay and StoryEngine.waitingForInput and not DialogueBox.isTyping then
        StoryEngine.autoPlayTimer = StoryEngine.autoPlayTimer + dt
        if StoryEngine.autoPlayTimer >= StoryEngine.autoPlayDelay then
            StoryEngine.autoPlayTimer = 0
            StoryEngine.advance()
        end
    else
        StoryEngine.autoPlayTimer = 0
    end
end

function StoryEngine.draw()
    SceneView.draw()
    CharacterManager.draw()
    DialogueBox.draw()
    ChoiceBox.draw()
    HistoryLog.draw()
end

function StoryEngine.keypressed(key)
    if HistoryLog.keypressed(key) then return end
    if ChoiceBox.keypressed(key) then return end

    if key == "space" or key == "return" or key == "z" then
        StoryEngine.advance()
    elseif key == "a" then
        StoryEngine.autoPlay = not StoryEngine.autoPlay
        AudioManager.playSFX("click")
    elseif key == "h" or key == "l" then
        HistoryLog.toggle()
        AudioManager.playSFX("click")
    end
end

function StoryEngine.mousepressed(x, y, button)
    if HistoryLog.visible then return end
    if ChoiceBox.mousepressed(x, y, button) then return end

    if button == 1 then
        StoryEngine.advance()
    elseif button == 2 then
        HistoryLog.toggle()
    end
end

function StoryEngine.mousemoved(x, y, dx, dy)
    ChoiceBox.mousemoved(x, y)
end

function StoryEngine.wheelmoved(x, y)
    if y > 0 and not HistoryLog.visible then
        HistoryLog.toggle()
    elseif HistoryLog.visible then
        HistoryLog.wheelmoved(x, y)
    end
end

return StoryEngine
