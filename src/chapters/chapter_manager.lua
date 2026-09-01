-- src/chapters/chapter_manager.lua
local EventBus = require("src.core.event_bus")
local PlayerStats = require("src.core.player_stats")
local AudioManager = require("src.core.audio_manager")

local ChapterManager = {
    currentChapterIndex = 1,
    chapters = {
        [1] = {
            id = 1,
            module = "src.chapters.chapter_1",
            title = "Chapter 1",
            subtitle = "Ink, Whiskers & The Midnight Repeater",
            desc = "Editorial deadlock in Clubroom 204, cat cafe draft investigation, and the 3rd floor repeater anomaly.",
            bgm = "main_theme"
        },
        [2] = {
            id = 2,
            module = "src.chapters.chapter_2",
            title = "Chapter 2",
            subtitle = "The Morning Commute & The Basement Sub-Station",
            desc = "Morning commute with Hiko, Auditor Saeki's 17:00 deadline, and tracing the basement physical mesh node.",
            bgm = "morning_theme"
        }
    }
}

function ChapterManager.init()
    ChapterManager.currentChapterIndex = 1
end

function ChapterManager.getChapterMeta(index)
    return ChapterManager.chapters[index or ChapterManager.currentChapterIndex]
end

function ChapterManager.getAllChapters()
    return ChapterManager.chapters
end

function ChapterManager.getUnlockedChapters()
    local unlocked = {}
    for i, meta in ipairs(ChapterManager.chapters) do
        if i == 1 or PlayerStats.getFlag("unlocked_chapter_" .. tostring(i)) or PlayerStats.getFlag("chapter_" .. tostring(i) .. "_started") or PlayerStats.getFlag("chapter1_completed") then
            table.insert(unlocked, meta)
        end
    end
    return unlocked
end

function ChapterManager.loadChapter(index, startStepIndex)
    index = index or 1
    local meta = ChapterManager.chapters[index]
    if not meta then
        print("[ChapterManager Warning] Invalid chapter index: " .. tostring(index))
        return false
    end

    ChapterManager.currentChapterIndex = index
    PlayerStats.setFlag("chapter_" .. tostring(index) .. "_started", true)
    PlayerStats.setFlag("unlocked_chapter_" .. tostring(index), true)

    local ok, scriptData = pcall(require, meta.module)
    if not ok or not scriptData then
        print("[ChapterManager Error] Failed to load chapter module: " .. tostring(meta.module) .. " - " .. tostring(scriptData))
        return false
    end

    local StoryEngine = require("src.story.story_engine")
    StoryEngine.loadScript(scriptData)
    
    if startStepIndex and startStepIndex > 1 then
        StoryEngine.currentIndex = math.max(0, math.min(#scriptData, startStepIndex - 1))
        StoryEngine.nextStep()
    end

    if meta.bgm then
        AudioManager.playBGM(meta.bgm)
    end

    EventBus.emit("chapter:loaded", { index = index, meta = meta })
    EventBus.emit("chapter:transition", { index = index, meta = meta })
    return true
end

function ChapterManager.nextChapter()
    local nextIndex = ChapterManager.currentChapterIndex + 1
    if ChapterManager.chapters[nextIndex] then
        PlayerStats.setFlag("chapter" .. tostring(ChapterManager.currentChapterIndex) .. "_completed", true)
        return ChapterManager.loadChapter(nextIndex)
    else
        print("[ChapterManager] Reached the end of available chapters.")
        return false
    end
end

return ChapterManager
