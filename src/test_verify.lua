-- src/test_verify.lua
-- Headless verification script for Lynux Caracal systems

local function runTests()
    local logs = {}
    local function log(msg)
        print(msg)
        table.insert(logs, msg)
    end

    log("=== STARTING LYNUX CARACAL VERIFICATION TESTS ===")

    -- 1. Test PlayerStats & EventBus
    local EventBus = require("src.core.event_bus")
    local PlayerStats = require("src.core.player_stats")
    PlayerStats.init()
    assert(PlayerStats.level == 1, "PlayerStats level should start at 1")
    assert(PlayerStats.xp == 0, "PlayerStats xp should start at 0")
    log("[PASS] PlayerStats initialized correctly.")

    -- 2. Test Filesystem
    local filesystem = require("src.core.filesystem")
    local fs = filesystem.getFS()
    assert(fs ~= nil, "Filesystem should be loaded")
    log("[PASS] Virtual Filesystem loaded successfully.")

    -- 3. Test Email App & Progressive Unlocking
    local EmailApp = require("src.apps.email")
    local emailInstance = EmailApp.new()
    local visibleEmails = emailInstance:getVisibleEmails()
    assert(#visibleEmails == 4, "Initial inbox should contain 4 emails (101, 102, 103, 104), found: " .. tostring(#visibleEmails))
    log("[PASS] Initial Email inbox properly filtered (no future emails present).")

    -- 4. Test Attachment Downloading
    local suzumiaEmail = visibleEmails[2] -- Suzumia's email
    assert(suzumiaEmail.attachment ~= nil, "Suzumia's email should have an attachment")
    assert(suzumiaEmail.attachment.filename == "cat_cafe_review.txt", "Attachment should be cat_cafe_review.txt")
    
    emailInstance:downloadAttachment(suzumiaEmail, suzumiaEmail.attachment)
    local TaskConditions = require("src.tasks.task_conditions")
    assert(TaskConditions.attachmentDownloaded("cat_cafe_review.txt")(), "cat_cafe_review.txt should be downloaded to Downloads")
    log("[PASS] Email attachment download verified.")

    -- 5. Test Chat App & Scripted Auto-Text
    local ChatApp = require("src.apps.chat")
    local chatInstance = ChatApp.new()
    
    -- Suzumia should be offline initially
    assert(chatInstance.users[1].online == false, "Suzumia should be offline before cat cafe research")
    
    -- Simulate Cat Cafe website visit
    PlayerStats.setFlag("browser_visited:cat", true)
    chatInstance:update(0.1)
    assert(chatInstance.users[1].online == true, "Suzumia should come online after cat cafe visit")
    
    -- Check scripted message
    chatInstance.activeUserId = 1
    local scriptedMsg, replyText = chatInstance:getScriptedInputForUser(chatInstance.users[1])
    assert(scriptedMsg ~= nil and scriptedMsg ~= "", "Scripted message for Suzumia should be present")
    
    -- Send scripted message
    chatInstance:sendMessage()
    assert(chatInstance.isTyping == true, "Suzumia should enter typing state")
    chatInstance:update(1.5) -- Complete bot reply
    assert(PlayerStats.getFlag("chat_sent:suzumia") == true, "Flag chat_sent:suzumia should be set")
    log("[PASS] Scripted Chat interaction & bot typing verified.")

    -- 6. Test Chapter 1 Task Chaining
    local TaskManager = require("src.tasks.task_manager")
    TaskManager.init()
    
    local prologue = require("src.chapters.prologue")
    assert(prologue ~= nil and #prologue > 0, "Prologue chapter script loaded with " .. tostring(#prologue) .. " steps.")
    log("[PASS] Prologue chapter script loaded successfully.")

    -- 7. Test SaveManager
    local SaveManager = require("src.core.save_manager")
    SaveManager.init()
    local saveSuccess = SaveManager.saveGame()
    assert(saveSuccess == true, "SaveManager.saveGame() should succeed")
    assert(SaveManager.hasSave() == true, "Save file should exist")
    
    local loadSuccess = SaveManager.loadGame()
    assert(loadSuccess == true, "SaveManager.loadGame() should load successfully")
    log("[PASS] SaveManager saving and loading verified.")

    log("=== ALL VERIFICATION TESTS PASSED SUCCESSFULLY! ===")
    
    local file = io.open("test_output.log", "w")
    if file then
        file:write(table.concat(logs, "\n"))
        file:close()
    end
end

return runTests
