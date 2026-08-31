-- test_verify.lua
-- Automated verification suite for Visual Novel + Desktop Simulation hybrid system
pcall(function() io.stdout:setvbuf("no") end)

local function runTests()
    local logLines = {}
    local function log(msg)
        print(msg)
        table.insert(logLines, msg)
    end

    log("========================================")
    log("Starting Automated Verification Tests...")
    log("========================================")

    -- Test 1: EventBus
    local EventBus = require("src.core.event_bus")
    local eventReceived = false
    local unsubscribe = EventBus.on("test:event", function(data)
        if data and data.val == 42 then
            eventReceived = true
        end
    end)
    EventBus.emit("test:event", { val = 42 })
    assert(eventReceived, "EventBus failed to dispatch event!")
    unsubscribe()
    log("[PASS] EventBus Pub/Sub")

    -- Test 2: PlayerStats
    local PlayerStats = require("src.core.player_stats")
    PlayerStats.init()
    assert(PlayerStats.level == 1, "Initial level should be 1")
    assert(PlayerStats.xp == 0, "Initial XP should be 0")
    PlayerStats.addXP(150)
    assert(PlayerStats.level >= 2, "Player should have leveled up to at least level 2!")
    assert(PlayerStats.xp == 50, "Remaining XP should be 50")
    log("[PASS] PlayerStats & Level-Up Progression")

    -- Test 3: TaskManager & Conditions
    local TaskManager = require("src.tasks.task_manager")
    local TaskConditions = require("src.tasks.task_conditions")
    local filesystemModule = require("src.core.filesystem")
    local fs = filesystemModule.getFS()
    if not fs.children["home"] then
        fs.children["home"] = { name = "home", type = "directory", parent = fs, children = {} }
    end
    
    local taskDone = false
    TaskManager.init()
    TaskManager.setTask({
        id = "test_task",
        title = "Create Test File",
        desc = "Create test.txt in home",
        xp = 100,
        condition = TaskConditions.fileContentContains("home/test.txt", "PASSPHRASE"),
        onComplete = function()
            taskDone = true
        end
    })

    assert(TaskManager.hasActiveTask(), "TaskManager should have an active task")
    
    -- Simulate file creation
    fs.children["home"].children["test.txt"] = {
        name = "test.txt",
        type = "file",
        parent = fs.children["home"],
        content = "Secret code: PASSPHRASE-123",
        created = os.time(),
        modified = os.time()
    }
    
    TaskManager.checkProgress()
    assert(taskDone, "Task condition should have succeeded and triggered completion!")
    assert(TaskManager.getCurrentTask().completed, "Task should be marked as completed")
    log("[PASS] TaskManager & Condition Evaluation")

    -- Test 4: StoryEngine & Script
    local StoryEngine = require("src.story.story_engine")
    StoryEngine.init()
    local testScript = {
        { type = "bg", name = "bedroom_night" },
        { type = "monologue", text = "Late night reflection..." },
        { type = "say", speaker = "Ghost", text = "Are you ready?" },
        { type = "label", name = "my_label" },
        { type = "flag", name = "test_flag", value = "ok" }
    }
    StoryEngine.loadScript(testScript)
    assert(StoryEngine.waitingForInput, "StoryEngine should be waiting on monologue step")
    StoryEngine.advance() -- completes typing
    StoryEngine.advance() -- moves to next step (say)
    assert(StoryEngine.waitingForInput, "StoryEngine should be waiting on say step")
    StoryEngine.advance()
    StoryEngine.advance()
    assert(PlayerStats.getFlag("test_flag") == "ok", "StoryEngine should have set flag")
    log("[PASS] StoryEngine Script Runner & Dialogue Flow")

    -- Test 5: Prologue Script Loading
    local prologueScript = require("data.stories.prologue")
    assert(type(prologueScript) == "table" and #prologueScript > 5, "Prologue script should be valid table with multiple steps")
    log("[PASS] Prologue Story Script Integrity")

    -- Test 6: Desktop & Window Manager & File Opening
    local WindowManager = require("src.desktop.window_mgr")
    local DesktopManager = require("src.desktop.desktop_mgr")
    DesktopManager.init()
    assert(#DesktopManager.apps >= 5, "DesktopManager should have registered apps")
    assert(type(_G.openFileDirectly) == "function", "_G.openFileDirectly should be defined")
    
    local dummyNode = { name = "notes.txt", type = "file", content = "Hello World" }
    _G.openFileDirectly(dummyNode)
    assert(#WindowManager.openApps == 1, "Opening file should open TextEditor window")
    assert(WindowManager.openApps[1].app.name == "TextEditor", "Opened window should be TextEditor")
    assert(WindowManager.openApps[1].instance.filename == "notes.txt", "TextEditor should have loaded filename")
    WindowManager.closeWindow(WindowManager.openApps[1])
    assert(#WindowManager.openApps == 0, "WindowManager should have closed window")
    log("[PASS] Desktop, Window Management & Direct File Opening")

    -- Test 7: Transitions
    local Transitions = require("src.core.transitions")
    local midCalled = false
    local endCalled = false
    Transitions.start("crt_zoom", 0.4, function() midCalled = true end, function() endCalled = true end)
    assert(Transitions.isActive(), "Transitions should be active")
    Transitions.update(0.25)
    assert(midCalled, "Midpoint callback should have been called")
    Transitions.update(0.2)
    assert(endCalled, "End callback should have been called")
    -- Test 8: Pause Menu
    local PauseMenu = require("src.ui.pause_menu")
    PauseMenu.init()
    assert(not PauseMenu.isOpen, "PauseMenu should initially be closed")
    PauseMenu.keypressed("escape")
    assert(PauseMenu.isOpen, "Pressing escape should open PauseMenu")
    PauseMenu.keypressed("escape")
    assert(not PauseMenu.isOpen, "Pressing escape again should close PauseMenu")
    log("[PASS] Pause & Settings Menu (ESC)")

    log("========================================")
    love.filesystem.write("verification_log.txt", table.concat(logLines, "\n"))
    print("[TEST COMPLETE] Written to verification_log.txt")
end

return runTests
