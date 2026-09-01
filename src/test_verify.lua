-- src/test_verify.lua
-- Headless verification script for Lynux Caracal systems

local function runTests()
    print("=== STARTING LYNUX CARACAL VERIFICATION TESTS ===")

    -- 1. Test PlayerStats & EventBus
    local EventBus = require("src.core.event_bus")
    local PlayerStats = require("src.core.player_stats")
    PlayerStats.init()
    assert(PlayerStats.level == 1, "PlayerStats level should start at 1")
    assert(PlayerStats.xp == 0, "PlayerStats xp should start at 0")
    print("[PASS] PlayerStats initialized correctly.")

    -- 2. Test Audio Manager & OST Aliases
    local AudioManager = require("src.core.audio_manager")
    AudioManager.init()
    assert(AudioManager.bgmAliases["main_menu"] ~= nil, "main_menu BGM alias should exist")
    assert(AudioManager.bgmAliases["desktop"] ~= nil, "desktop BGM alias should exist")
    print("[PASS] AudioManager and OST aliases verified.")

    -- 3. Test ChapterManager & Modular Chapters
    local ChapterManager = require("src.chapters.chapter_manager")
    ChapterManager.init()
    assert(ChapterManager.getChapterMeta(1) ~= nil, "Chapter 1 metadata should exist")
    assert(ChapterManager.getChapterMeta(2) ~= nil, "Chapter 2 metadata should exist")
    
    local ok1 = ChapterManager.loadChapter(1)
    assert(ok1 == true, "Chapter 1 should load successfully")
    local ok2 = ChapterManager.loadChapter(2)
    assert(ok2 == true, "Chapter 2 should load successfully")
    print("[PASS] ChapterManager and modular chapters (chapter_1.lua, chapter_2.lua) verified.")

    -- 4. Test Main Menu Module
    local MainMenu = require("src.ui.main_menu")
    MainMenu.init()
    local menuItems = MainMenu.getMenuItems()
    assert(#menuItems == 5, "Main Menu should have 5 items (Continue, New Game, Chapter Select, Settings, Exit)")
    print("[PASS] MainMenu UI initialized successfully.")

    -- 5. Test SaveManager
    local SaveManager = require("src.core.save_manager")
    SaveManager.init()
    local saveSuccess = SaveManager.saveGame()
    assert(saveSuccess == true, "SaveManager.saveGame() should succeed")
    assert(SaveManager.hasSave() == true, "Save file should exist")
    
    local loadSuccess = SaveManager.loadGame()
    assert(loadSuccess == true, "SaveManager.loadGame() should load successfully")
    print("[PASS] SaveManager with chapterIndex verified.")

    print("=== ALL VERIFICATION TESTS PASSED SUCCESSFULLY! ===")
end

return runTests
