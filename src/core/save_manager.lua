-- src/core/save_manager.lua
local json = require("lib/json")
local EventBus = require("src.core.event_bus")

local SaveManager = {
    saveFilename = "save_game.json",
    isSaving = false,
    saveIndicatorTimer = 0,
    saveData = {}
}

function SaveManager.init()
    -- Cache save data info for Main Menu
    if SaveManager.hasSave() then
        local data = love.filesystem.read(SaveManager.saveFilename)
        if data then
            local ok, parsed = pcall(json.decode, data)
            if ok and parsed then
                SaveManager.saveData = parsed
            end
        end
    end

    -- Auto-save on task completion
    EventBus.on("task:completed", function(task)
        SaveManager.saveGame()
    end, "save_mgr_task_complete")

    -- Auto-save on story choices / major flag changes
    EventBus.on("story:choice_made", function()
        SaveManager.saveGame()
    end, "save_mgr_story_choice")

    EventBus.on("chapter:transition", function()
        SaveManager.saveGame()
    end, "save_mgr_chapter_trans")
end

function SaveManager.hasSave()
    return love.filesystem.getInfo(SaveManager.saveFilename) ~= nil
end

function SaveManager.saveGame()
    local PlayerStats = require("src.core.player_stats")
    local TaskManager = require("src.tasks.task_manager")
    local StoryEngine = require("src.story.story_engine")
    local GameManager = require("src.core.game_manager")
    local ChapterManager = require("src.chapters.chapter_manager")
    local filesystem = require("src.core.filesystem")

    local completedTaskIds = {}
    for _, t in ipairs(TaskManager.completedTasks) do
        if t.id then
            completedTaskIds[t.id] = true
        end
    end

    local currentTaskData = nil
    if TaskManager.currentTask then
        currentTaskData = {
            id = TaskManager.currentTask.id,
            title = TaskManager.currentTask.title,
            desc = TaskManager.currentTask.desc,
            hint = TaskManager.currentTask.hint,
            xp = TaskManager.currentTask.xp,
            completed = TaskManager.currentTask.completed
        }
    end

    local saveData = {
        saveVersion = 1,
        timestamp = os.time(),
        gameMode = GameManager.mode or "story",
        chapterIndex = ChapterManager.currentChapterIndex or 1,
        story = {
            currentIndex = StoryEngine.currentIndex or 1,
            isFinished = StoryEngine.isFinished or false
        },
        playerStats = {
            level = PlayerStats.level,
            xp = PlayerStats.xp,
            xpForNextLevel = PlayerStats.xpForNextLevel,
            title = PlayerStats.title,
            flags = PlayerStats.flags
        },
        tasks = {
            currentTask = currentTaskData,
            completedTaskIds = completedTaskIds
        }
    }

    local ok, encoded = pcall(json.encode, saveData, { indent = true })
    if ok and encoded then
        love.filesystem.write(SaveManager.saveFilename, encoded)
        filesystem.save(filesystem.getFS())
        
        SaveManager.saveData = saveData
        SaveManager.saveIndicatorTimer = 2.0
        EventBus.emit("game:saved", saveData)
        return true
    else
        print("[SaveManager Error] Failed to encode save data:", encoded)
        return false
    end
end

function SaveManager.loadGame()
    if not SaveManager.hasSave() then return false end

    local data = love.filesystem.read(SaveManager.saveFilename)
    if not data then return false end

    local ok, saveData = pcall(json.decode, data)
    if not ok or not saveData then
        print("[SaveManager Error] Failed to decode save data")
        return false
    end

    SaveManager.saveData = saveData

    local PlayerStats = require("src.core.player_stats")
    local ChapterManager = require("src.chapters.chapter_manager")
    local GameManager = require("src.core.game_manager")

    -- Restore PlayerStats
    if saveData.playerStats then
        PlayerStats.level = saveData.playerStats.level or 1
        PlayerStats.xp = saveData.playerStats.xp or 0
        PlayerStats.xpForNextLevel = saveData.playerStats.xpForNextLevel or 100
        PlayerStats.title = saveData.playerStats.title or PlayerStats.levelTitles[1]
        PlayerStats.flags = saveData.playerStats.flags or {}
    end

    -- Restore Chapter & Story Index
    local chapterIdx = saveData.chapterIndex or 1
    local storyStepIdx = (saveData.story and saveData.story.currentIndex) or 1
    ChapterManager.loadChapter(chapterIdx, storyStepIdx)

    -- Restore GameManager mode
    if saveData.gameMode and saveData.gameMode ~= "menu" then
        GameManager.mode = saveData.gameMode
    else
        GameManager.mode = "story"
    end

    EventBus.emit("game:loaded", saveData)
    return true
end

function SaveManager.resetProgress()
    if SaveManager.hasSave() then
        love.filesystem.remove(SaveManager.saveFilename)
    end
    if love.filesystem.getInfo("filesystem.json") then
        love.filesystem.remove("filesystem.json")
    end
    SaveManager.saveData = {}
end

function SaveManager.update(dt)
    if SaveManager.saveIndicatorTimer > 0 then
        SaveManager.saveIndicatorTimer = SaveManager.saveIndicatorTimer - dt
    end
end

return SaveManager
