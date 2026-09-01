-- src/ui/main_menu.lua
local EventBus = require("src.core.event_bus")
local AudioManager = require("src.core.audio_manager")
local SaveManager = require("src.core.save_manager")
local ChapterManager = require("src.chapters.chapter_manager")
local PlayerStats = require("src.core.player_stats")
local DialogueBox = require("src.story.dialogue_box")
local Viewport = require("src.core.viewport")

local MainMenu = {
    selectedIndex = 1,
    currentModal = nil, -- nil, "chapter_select", "settings"
    chapterSelectedIndex = 1,
    settingsSelectedIndex = 1,

    -- Fonts
    titleFont = nil,
    subtitleFont = nil,
    menuFont = nil,
    smallFont = nil,
    boldFont = nil,

    colors = {
        bgTop = {0.05, 0.08, 0.16},
        bgBottom = {0.08, 0.12, 0.22},
        cardBg = {0.10, 0.14, 0.22, 0.96},
        accent = {0.13, 0.59, 0.95},
        accentHover = {0.25, 0.72, 1.0},
        textPrimary = {0.95, 0.97, 1.0},
        textSecondary = {0.60, 0.66, 0.76},
        textDisabled = {0.35, 0.38, 0.45},
        border = {0.20, 0.25, 0.36},
        badge = {0.85, 0.18, 0.14}
    },

    bgImage = nil
}

function MainMenu.init()
    MainMenu.selectedIndex = SaveManager.hasSave() and 1 or 2
    MainMenu.currentModal = nil
    MainMenu.chapterSelectedIndex = 1
    MainMenu.settingsSelectedIndex = 1

    -- Attempt to load menu background image asset
    local menuBgCandidates = {
        "data/backgrounds/main_menu.png",
        "data/backgrounds/menu.png",
        "data/backgrounds/title.png",
        "data/backgrounds/newspaper_club.png",
        "wallpaper/1.jpg"
    }
    MainMenu.bgImage = nil
    for _, path in ipairs(menuBgCandidates) do
        local ok, img = pcall(love.graphics.newImage, path)
        if ok and img then
            MainMenu.bgImage = img
            break
        end
    end

    MainMenu.titleFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 26) or love.graphics.newFont(26)
    MainMenu.titleFontLarge = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 34) or love.graphics.newFont(34)
    MainMenu.subtitleFont = love.graphics.newFont("font/Nunito-Regular.ttf", 13) or love.graphics.newFont(13)
    MainMenu.menuFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 15) or love.graphics.newFont(15)
    MainMenu.boldFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 13) or love.graphics.newFont(13)
    MainMenu.smallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 11) or love.graphics.newFont(11)

    MainMenu.hasDrawnOnce = false
    MainMenu.bgmTimer = 0
end

function MainMenu.getLayout(screenW, screenH)
    local isCompact = (screenH < 540 or screenW < 720)
    local startX = isCompact and 36 or 64
    local titleY = isCompact and 18 or 36
    local titleH = isCompact and 48 or 62
    local btnY = titleY + titleH + (isCompact and 12 or 20)
    local btnW = isCompact and math.min(340, math.floor(screenW * 0.48)) or math.min(420, math.floor(screenW * 0.42))
    local btnH = isCompact and 44 or 54
    local btnGap = isCompact and 7 or 10

    return {
        isCompact = isCompact,
        startX = startX,
        titleY = titleY,
        btnY = btnY,
        btnW = btnW,
        btnH = btnH,
        btnGap = btnGap
    }
end

function MainMenu.getMenuItems()
    local hasSave = SaveManager.hasSave()
    local saveInfo = ""
    if hasSave then
        local chapMeta = ChapterManager.getChapterMeta(SaveManager.saveData.chapterIndex or 1)
        saveInfo = (chapMeta and chapMeta.title or "Chapter 1") .. "  •  Lv." .. tostring(PlayerStats.level)
    end

    return {
        { id = "continue", label = "Continue", subtext = saveInfo, enabled = hasSave },
        { id = "new_game", label = "New Game", subtext = "Start Chapter 1 from beginning", enabled = true },
        { id = "chapter_select", label = "Chapter Select", subtext = "Replay unlocked chapters", enabled = true },
        { id = "settings", label = "Settings & Audio", subtext = "Volume sliders & text speed", enabled = true },
        { id = "exit", label = "Exit to Desktop", subtext = "Quit application", enabled = true }
    }
end

function MainMenu.update(dt)
    -- Start Main Menu BGM only after the menu interface has rendered on screen
    if MainMenu.hasDrawnOnce then
        MainMenu.bgmTimer = (MainMenu.bgmTimer or 0) + dt
        if MainMenu.bgmTimer >= 0.25 then
            if not AudioManager.bgm or not AudioManager.bgm:isPlaying() then
                AudioManager.playBGM("main_menu")
            end
        end
    end
end

function MainMenu.draw()
    MainMenu.hasDrawnOnce = true
    local screenW = Viewport.getWidth()
    local screenH = Viewport.getHeight()
    local layout = MainMenu.getLayout(screenW, screenH)

    -- 1. Background Rendering (Image with dark blue overlay, or dark blue fallback)
    if MainMenu.bgImage then
        local scaleX = screenW / MainMenu.bgImage:getWidth()
        local scaleY = screenH / MainMenu.bgImage:getHeight()
        local scale = math.max(scaleX, scaleY)
        local drawW = MainMenu.bgImage:getWidth() * scale
        local drawH = MainMenu.bgImage:getHeight() * scale
        local drawX = math.floor((screenW - drawW) / 2)
        local drawY = math.floor((screenH - drawH) / 2)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(MainMenu.bgImage, drawX, drawY, 0, scale, scale)

        -- Dark blue translucent veil for high-contrast UI legibility
        love.graphics.setColor(0.04, 0.07, 0.14, 0.76)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        love.graphics.setColor(0.02, 0.05, 0.10, 0.45)
        love.graphics.rectangle("fill", 0, 0, layout.startX + layout.btnW + 48, screenH)
    else
        -- Fallback Dark Blue Gradient
        love.graphics.setColor(MainMenu.colors.bgTop)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        
        love.graphics.setColor(MainMenu.colors.bgBottom)
        love.graphics.rectangle("fill", 0, screenH * 0.4, screenW, screenH * 0.6)
    end

    -- Subtle accent lines
    love.graphics.setColor(0.12, 0.18, 0.28, 0.5)
    love.graphics.line(layout.startX, layout.btnY - 10, layout.startX + layout.btnW + 40, layout.btnY - 10)

    -- 2. Title & Logo
    love.graphics.setColor(MainMenu.colors.accent)
    love.graphics.rectangle("fill", layout.startX, layout.titleY + 4, 4, layout.isCompact and 36 or 46, 2)

    love.graphics.setFont(layout.isCompact and MainMenu.titleFont or MainMenu.titleFontLarge)
    love.graphics.setColor(MainMenu.colors.textPrimary)
    love.graphics.print("DAYDREAM NEWSPAPER CLUB", layout.startX + 16, layout.titleY)

    love.graphics.setFont(MainMenu.subtitleFont)
    love.graphics.setColor(MainMenu.colors.textSecondary)
    love.graphics.print("Kamiyama High Newspaper Club • Desktop Investigation", layout.startX + 18, layout.titleY + (layout.isCompact and 32 or 42))

    -- 3. Responsive Menu Buttons
    local menuItems = MainMenu.getMenuItems()
    local currentY = layout.btnY
    local mx, my = love.mouse.getPosition()

    for i, item in ipairs(menuItems) do
        local isSelected = (MainMenu.selectedIndex == i and not MainMenu.currentModal)
        local isHovered = (mx >= layout.startX and mx <= layout.startX + layout.btnW and
                           my >= currentY and my <= currentY + layout.btnH and not MainMenu.currentModal)

        if isHovered and not isSelected and item.enabled then
            MainMenu.selectedIndex = i
            AudioManager.playSFX("tick", 1.4)
            isSelected = true
        end

        -- Card background
        if not item.enabled then
            love.graphics.setColor(0.08, 0.10, 0.14, 0.6)
        elseif isSelected then
            love.graphics.setColor(0.13, 0.24, 0.40, 0.95)
        else
            love.graphics.setColor(0.10, 0.13, 0.20, 0.85)
        end
        love.graphics.rectangle("fill", layout.startX, currentY, layout.btnW, layout.btnH, 6)

        -- Border & selection indicator
        if isSelected and item.enabled then
            love.graphics.setColor(MainMenu.colors.accent)
            love.graphics.rectangle("line", layout.startX, currentY, layout.btnW, layout.btnH, 6)
            love.graphics.setColor(MainMenu.colors.accentHover)
            love.graphics.rectangle("fill", layout.startX, currentY + 6, 3, layout.btnH - 12, 2)
        else
            love.graphics.setColor(MainMenu.colors.border)
            love.graphics.rectangle("line", layout.startX, currentY, layout.btnW, layout.btnH, 6)
        end

        -- Button Label
        love.graphics.setFont(MainMenu.menuFont)
        if not item.enabled then
            love.graphics.setColor(MainMenu.colors.textDisabled)
        elseif isSelected then
            love.graphics.setColor(MainMenu.colors.accentHover)
        else
            love.graphics.setColor(MainMenu.colors.textPrimary)
        end
        love.graphics.print(item.label, layout.startX + 16, currentY + (layout.isCompact and 6 or 8))

        -- Subtext
        if item.subtext and item.subtext ~= "" then
            love.graphics.setFont(MainMenu.smallFont)
            if not item.enabled then
                love.graphics.setColor(MainMenu.colors.textDisabled)
            elseif isSelected then
                love.graphics.setColor(0.75, 0.88, 1.0)
            else
                love.graphics.setColor(MainMenu.colors.textSecondary)
            end
            love.graphics.print(item.subtext, layout.startX + 16, currentY + (layout.isCompact and 24 or 28))
        end

        currentY = currentY + layout.btnH + layout.btnGap
    end

    -- 4. Clean Footer Info
    love.graphics.setFont(MainMenu.smallFont)
    love.graphics.setColor(MainMenu.colors.textSecondary)
    love.graphics.print("v1.3.0 • Love2D Engine • Kamiyama Press Workstation", layout.startX, screenH - 24)

    -- 5. Modals (Chapter Select / Settings)
    if MainMenu.currentModal == "chapter_select" then
        MainMenu.drawChapterSelectModal(screenW, screenH)
    elseif MainMenu.currentModal == "settings" then
        MainMenu.drawSettingsModal(screenW, screenH)
    end
end

function MainMenu.drawChapterSelectModal(screenW, screenH)
    love.graphics.setColor(0, 0, 0, 0.78)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    local modalW = math.min(560, screenW - 32)
    local modalH = math.min(380, screenH - 32)
    local modalX = math.floor((screenW - modalW) / 2)
    local modalY = math.floor((screenH - modalH) / 2)

    love.graphics.setColor(MainMenu.colors.cardBg)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 10)
    love.graphics.setColor(MainMenu.colors.accent)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH, 10)

    -- Header
    love.graphics.setFont(MainMenu.menuFont)
    love.graphics.setColor(MainMenu.colors.textPrimary)
    love.graphics.print("CHAPTER SELECT", modalX + 24, modalY + 18)

    love.graphics.setFont(MainMenu.smallFont)
    love.graphics.setColor(MainMenu.colors.textSecondary)
    love.graphics.print("Select a chapter to begin or replay:", modalX + 24, modalY + 42)

    -- Chapter Cards
    local chapters = ChapterManager.getAllChapters()
    local cardY = modalY + 68
    local cardW = modalW - 48
    local cardH = math.max(64, math.min(84, math.floor((modalH - 140) / #chapters)))
    local mx, my = love.mouse.getPosition()

    for i = 1, #chapters do
        local chap = chapters[i]
        local isUnlocked = (i == 1 or PlayerStats.getFlag("unlocked_chapter_" .. tostring(i)) or PlayerStats.getFlag("chapter_" .. tostring(i) .. "_started") or PlayerStats.getFlag("chapter1_completed"))
        local isSelected = (MainMenu.chapterSelectedIndex == i)
        local isHovered = (mx >= modalX + 24 and mx <= modalX + 24 + cardW and my >= cardY and my <= cardY + cardH)

        if isHovered and isUnlocked and not isSelected then
            MainMenu.chapterSelectedIndex = i
            AudioManager.playSFX("tick", 1.4)
        end

        if not isUnlocked then
            love.graphics.setColor(0.08, 0.10, 0.15, 0.7)
        elseif isSelected then
            love.graphics.setColor(0.14, 0.24, 0.42, 0.95)
        else
            love.graphics.setColor(0.10, 0.13, 0.20, 0.85)
        end
        love.graphics.rectangle("fill", modalX + 24, cardY, cardW, cardH, 6)

        if isSelected and isUnlocked then
            love.graphics.setColor(MainMenu.colors.accent)
            love.graphics.rectangle("line", modalX + 24, cardY, cardW, cardH, 6)
        else
            love.graphics.setColor(MainMenu.colors.border)
            love.graphics.rectangle("line", modalX + 24, cardY, cardW, cardH, 6)
        end

        -- Chapter Title
        love.graphics.setFont(MainMenu.boldFont)
        if not isUnlocked then
            love.graphics.setColor(MainMenu.colors.textDisabled)
            love.graphics.print(chap.title .. " (Locked)", modalX + 38, cardY + 10)
        else
            love.graphics.setColor(isSelected and MainMenu.colors.accentHover or MainMenu.colors.textPrimary)
            love.graphics.print(chap.title .. ": " .. chap.subtitle, modalX + 38, cardY + 10)
        end

        -- Chapter Description
        love.graphics.setFont(MainMenu.smallFont)
        if not isUnlocked then
            love.graphics.setColor(MainMenu.colors.textDisabled)
            love.graphics.print("Complete previous chapter objectives to unlock.", modalX + 38, cardY + 30)
        else
            love.graphics.setColor(MainMenu.colors.textSecondary)
            love.graphics.printf(chap.desc, modalX + 38, cardY + 30, cardW - 40, "left")
        end

        cardY = cardY + cardH + 10
    end

    -- Close Button
    local closeBtnW = 120
    local closeBtnH = 34
    local closeBtnX = modalX + modalW - closeBtnW - 24
    local closeBtnY = modalY + modalH - closeBtnH - 16
    local closeHovered = (mx >= closeBtnX and mx <= closeBtnX + closeBtnW and my >= closeBtnY and my <= closeBtnY + closeBtnH)

    love.graphics.setColor(closeHovered and MainMenu.colors.accentHover or MainMenu.colors.accent)
    love.graphics.rectangle("fill", closeBtnX, closeBtnY, closeBtnW, closeBtnH, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(MainMenu.boldFont)
    love.graphics.printf("Close (ESC)", closeBtnX, closeBtnY + 8, closeBtnW, "center")
end

function MainMenu.drawSettingsModal(screenW, screenH)
    love.graphics.setColor(0, 0, 0, 0.78)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    local modalW = math.min(500, screenW - 32)
    local modalH = math.min(340, screenH - 32)
    local modalX = math.floor((screenW - modalW) / 2)
    local modalY = math.floor((screenH - modalH) / 2)

    love.graphics.setColor(MainMenu.colors.cardBg)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 10)
    love.graphics.setColor(MainMenu.colors.accent)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH, 10)

    love.graphics.setFont(MainMenu.menuFont)
    love.graphics.setColor(MainMenu.colors.textPrimary)
    love.graphics.print("SETTINGS & AUDIO", modalX + 24, modalY + 18)

    local sliderW = modalW - 80

    -- Option 1: BGM Volume
    local optY = modalY + 60
    love.graphics.setFont(MainMenu.boldFont)
    love.graphics.setColor(MainMenu.settingsSelectedIndex == 1 and MainMenu.colors.accentHover or MainMenu.colors.textPrimary)
    love.graphics.print("Music Volume (BGM): " .. math.floor(AudioManager.bgmVolume * 100) .. "%", modalX + 30, optY)
    
    love.graphics.setColor(0.18, 0.22, 0.32)
    love.graphics.rectangle("fill", modalX + 30, optY + 22, sliderW, 8, 4)
    love.graphics.setColor(MainMenu.colors.accent)
    love.graphics.rectangle("fill", modalX + 30, optY + 22, sliderW * AudioManager.bgmVolume, 8, 4)
    love.graphics.circle("fill", modalX + 30 + (sliderW * AudioManager.bgmVolume), optY + 26, 7)

    -- Option 2: SFX Volume
    optY = optY + 60
    love.graphics.setColor(MainMenu.settingsSelectedIndex == 2 and MainMenu.colors.accentHover or MainMenu.colors.textPrimary)
    love.graphics.print("Sound Effects (SFX): " .. math.floor(AudioManager.sfxVolume * 100) .. "%", modalX + 30, optY)
    love.graphics.setColor(0.18, 0.22, 0.32)
    love.graphics.rectangle("fill", modalX + 30, optY + 22, sliderW, 8, 4)
    love.graphics.setColor(MainMenu.colors.accent)
    love.graphics.rectangle("fill", modalX + 30, optY + 22, sliderW * AudioManager.sfxVolume, 8, 4)
    love.graphics.circle("fill", modalX + 30 + (sliderW * AudioManager.sfxVolume), optY + 26, 7)

    -- Option 3: Text Speed
    optY = optY + 60
    local speedLabel = DialogueBox.typeSpeed <= 0.015 and "Fast" or (DialogueBox.typeSpeed <= 0.035 and "Normal" or "Slow")
    love.graphics.setColor(MainMenu.settingsSelectedIndex == 3 and MainMenu.colors.accentHover or MainMenu.colors.textPrimary)
    love.graphics.print("Text Typewriter Speed: " .. speedLabel .. " (Click to toggle)", modalX + 30, optY)

    -- Close Button
    local mx, my = love.mouse.getPosition()
    local closeBtnW = 120
    local closeBtnH = 34
    local closeBtnX = modalX + modalW - closeBtnW - 24
    local closeBtnY = modalY + modalH - closeBtnH - 16
    local closeHovered = (mx >= closeBtnX and mx <= closeBtnX + closeBtnW and my >= closeBtnY and my <= closeBtnY + closeBtnH)

    love.graphics.setColor(closeHovered and MainMenu.colors.accentHover or MainMenu.colors.accent)
    love.graphics.rectangle("fill", closeBtnX, closeBtnY, closeBtnW, closeBtnH, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(MainMenu.boldFont)
    love.graphics.printf("Close (ESC)", closeBtnX, closeBtnY + 8, closeBtnW, "center")
end

function MainMenu.activateOption()
    local items = MainMenu.getMenuItems()
    local item = items[MainMenu.selectedIndex]
    if not item or not item.enabled then return end

    AudioManager.playSFX("click")

    if item.id == "continue" then
        SaveManager.loadGame()
        EventBus.emit("game:request_switch_mode", { mode = "story", transition = "fade" })

    elseif item.id == "new_game" then
        SaveManager.resetProgress()
        PlayerStats.init()
        local TaskManager = require("src.tasks.task_manager")
        TaskManager.init()
        ChapterManager.loadChapter(1)
        EventBus.emit("game:request_switch_mode", { mode = "story", transition = "fade" })

    elseif item.id == "chapter_select" then
        MainMenu.currentModal = "chapter_select"
        MainMenu.chapterSelectedIndex = 1

    elseif item.id == "settings" then
        MainMenu.currentModal = "settings"
        MainMenu.settingsSelectedIndex = 1

    elseif item.id == "exit" then
        love.event.quit()
    end
end

function MainMenu.mousepressed(x, y, button)
    if button ~= 1 then return end

    local screenW = Viewport.getWidth()
    local screenH = Viewport.getHeight()

    if MainMenu.currentModal == "chapter_select" then
        local modalW = math.min(560, screenW - 32)
        local modalH = math.min(380, screenH - 32)
        local modalX = math.floor((screenW - modalW) / 2)
        local modalY = math.floor((screenH - modalH) / 2)

        -- Check Close button
        local closeBtnW = 120
        local closeBtnH = 34
        local closeBtnX = modalX + modalW - closeBtnW - 24
        local closeBtnY = modalY + modalH - closeBtnH - 16
        if x >= closeBtnX and x <= closeBtnX + closeBtnW and y >= closeBtnY and y <= closeBtnY + closeBtnH then
            MainMenu.currentModal = nil
            AudioManager.playSFX("click")
            return
        end

        -- Check chapter card click
        local chapters = ChapterManager.getAllChapters()
        local cardY = modalY + 68
        local cardW = modalW - 48
        local cardH = math.max(64, math.min(84, math.floor((modalH - 140) / #chapters)))
        for i = 1, #chapters do
            if x >= modalX + 24 and x <= modalX + 24 + cardW and y >= cardY and y <= cardY + cardH then
                local isUnlocked = (i == 1 or PlayerStats.getFlag("unlocked_chapter_" .. tostring(i)) or PlayerStats.getFlag("chapter_" .. tostring(i) .. "_started") or PlayerStats.getFlag("chapter1_completed"))
                if isUnlocked then
                    MainMenu.currentModal = nil
                    SaveManager.resetProgress()
                    PlayerStats.init()
                    local TaskManager = require("src.tasks.task_manager")
                    TaskManager.init()
                    ChapterManager.loadChapter(i)
                    EventBus.emit("game:request_switch_mode", { mode = "story", transition = "fade" })
                else
                    AudioManager.playSFX("error")
                end
                return
            end
            cardY = cardY + cardH + 10
        end

    elseif MainMenu.currentModal == "settings" then
        local modalW = math.min(500, screenW - 32)
        local modalH = math.min(340, screenH - 32)
        local modalX = math.floor((screenW - modalW) / 2)
        local modalY = math.floor((screenH - modalH) / 2)
        local sliderW = modalW - 80

        -- Check Close button
        local closeBtnW = 120
        local closeBtnH = 34
        local closeBtnX = modalX + modalW - closeBtnW - 24
        local closeBtnY = modalY + modalH - closeBtnH - 16
        if x >= closeBtnX and x <= closeBtnX + closeBtnW and y >= closeBtnY and y <= closeBtnY + closeBtnH then
            MainMenu.currentModal = nil
            AudioManager.playSFX("click")
            return
        end

        -- Slider 1: BGM
        local bgmY = modalY + 60 + 22
        if x >= modalX + 30 and x <= modalX + 30 + sliderW and y >= bgmY - 10 and y <= bgmY + 18 then
            local val = (x - (modalX + 30)) / sliderW
            AudioManager.setBGMVolume(val)
            AudioManager.playSFX("tick", 1.2)
            return
        end

        -- Slider 2: SFX
        local sfxY = modalY + 120 + 22
        if x >= modalX + 30 and x <= modalX + 30 + sliderW and y >= sfxY - 10 and y <= sfxY + 18 then
            local val = (x - (modalX + 30)) / sliderW
            AudioManager.setSFXVolume(val)
            AudioManager.playSFX("tick", 1.2)
            return
        end

        -- Option 3: Text Speed toggle
        local spdY = modalY + 180
        if x >= modalX + 30 and x <= modalX + 30 + sliderW and y >= spdY and y <= spdY + 28 then
            if DialogueBox.typeSpeed > 0.035 then
                DialogueBox.typeSpeed = 0.015 -- Fast
            elseif DialogueBox.typeSpeed > 0.015 then
                DialogueBox.typeSpeed = 0.045 -- Slow
            else
                DialogueBox.typeSpeed = 0.025 -- Normal
            end
            AudioManager.playSFX("tick", 1.2)
            return
        end

    else
        -- Main menu buttons click
        local layout = MainMenu.getLayout(screenW, screenH)
        local menuItems = MainMenu.getMenuItems()

        for i, item in ipairs(menuItems) do
            local by = layout.btnY + (i - 1) * (layout.btnH + layout.btnGap)
            if x >= layout.startX and x <= layout.startX + layout.btnW and y >= by and y <= by + layout.btnH then
                if item.enabled then
                    MainMenu.selectedIndex = i
                    MainMenu.activateOption()
                else
                    AudioManager.playSFX("error")
                end
                return
            end
        end
    end
end

function MainMenu.keypressed(key)
    if MainMenu.currentModal == "chapter_select" then
        if key == "escape" then
            MainMenu.currentModal = nil
            AudioManager.playSFX("click")
        elseif key == "up" then
            MainMenu.chapterSelectedIndex = math.max(1, MainMenu.chapterSelectedIndex - 1)
            AudioManager.playSFX("tick", 1.3)
        elseif key == "down" then
            local chapters = ChapterManager.getAllChapters()
            MainMenu.chapterSelectedIndex = math.min(#chapters, MainMenu.chapterSelectedIndex + 1)
            AudioManager.playSFX("tick", 1.3)
        elseif key == "return" or key == "space" then
            local idx = MainMenu.chapterSelectedIndex
            local isUnlocked = (idx == 1 or PlayerStats.getFlag("unlocked_chapter_" .. tostring(idx)) or PlayerStats.getFlag("chapter_" .. tostring(idx) .. "_started") or PlayerStats.getFlag("chapter1_completed"))
            if isUnlocked then
                MainMenu.currentModal = nil
                SaveManager.resetProgress()
                PlayerStats.init()
                local TaskManager = require("src.tasks.task_manager")
                TaskManager.init()
                ChapterManager.loadChapter(idx)
                EventBus.emit("game:request_switch_mode", { mode = "story", transition = "fade" })
            else
                AudioManager.playSFX("error")
            end
        end
        return
    end

    if MainMenu.currentModal == "settings" then
        if key == "escape" then
            MainMenu.currentModal = nil
            AudioManager.playSFX("click")
        elseif key == "up" then
            MainMenu.settingsSelectedIndex = math.max(1, MainMenu.settingsSelectedIndex - 1)
            AudioManager.playSFX("tick", 1.3)
        elseif key == "down" then
            MainMenu.settingsSelectedIndex = math.min(3, MainMenu.settingsSelectedIndex + 1)
            AudioManager.playSFX("tick", 1.3)
        elseif key == "left" then
            if MainMenu.settingsSelectedIndex == 1 then
                AudioManager.setBGMVolume(AudioManager.bgmVolume - 0.1)
                AudioManager.playSFX("tick", 1.2)
            elseif MainMenu.settingsSelectedIndex == 2 then
                AudioManager.setSFXVolume(AudioManager.sfxVolume - 0.1)
                AudioManager.playSFX("tick", 1.2)
            end
        elseif key == "right" then
            if MainMenu.settingsSelectedIndex == 1 then
                AudioManager.setBGMVolume(AudioManager.bgmVolume + 0.1)
                AudioManager.playSFX("tick", 1.2)
            elseif MainMenu.settingsSelectedIndex == 2 then
                AudioManager.setSFXVolume(AudioManager.sfxVolume + 0.1)
                AudioManager.playSFX("tick", 1.2)
            end
        end
        return
    end

    local menuItems = MainMenu.getMenuItems()
    if key == "up" then
        local prev = MainMenu.selectedIndex
        repeat
            MainMenu.selectedIndex = MainMenu.selectedIndex - 1
            if MainMenu.selectedIndex < 1 then MainMenu.selectedIndex = #menuItems end
        until menuItems[MainMenu.selectedIndex].enabled or MainMenu.selectedIndex == prev
        AudioManager.playSFX("tick", 1.3)

    elseif key == "down" then
        local prev = MainMenu.selectedIndex
        repeat
            MainMenu.selectedIndex = MainMenu.selectedIndex + 1
            if MainMenu.selectedIndex > #menuItems then MainMenu.selectedIndex = 1 end
        until menuItems[MainMenu.selectedIndex].enabled or MainMenu.selectedIndex == prev
        AudioManager.playSFX("tick", 1.3)

    elseif key == "return" or key == "space" then
        MainMenu.activateOption()
    end
end

return MainMenu
