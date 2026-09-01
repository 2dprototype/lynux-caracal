-- src/ui/main_menu.lua
local EventBus = require("src.core.event_bus")
local AudioManager = require("src.core.audio_manager")
local SaveManager = require("src.core.save_manager")
local ChapterManager = require("src.chapters.chapter_manager")
local PlayerStats = require("src.core.player_stats")
local DialogueBox = require("src.story.dialogue_box")

local MainMenu = {
    selectedIndex = 1,
    currentModal = nil, -- nil, "chapter_select", "settings"
    chapterSelectedIndex = 1,
    settingsSelectedIndex = 1,
    particles = {},
    particleTimer = 0,
    time = 0,

    -- Fonts
    titleFont = nil,
    subtitleFont = nil,
    menuFont = nil,
    smallFont = nil,
    boldFont = nil,

    colors = {
        bgTop = {0.05, 0.07, 0.12},
        bgBottom = {0.09, 0.13, 0.20},
        cardBg = {0.12, 0.15, 0.22, 0.95},
        accent = {0.13, 0.59, 0.95},
        accentHover = {0.25, 0.70, 1.0},
        textPrimary = {0.95, 0.97, 1.0},
        textSecondary = {0.60, 0.66, 0.75},
        textDisabled = {0.35, 0.38, 0.45},
        border = {0.20, 0.25, 0.36},
        badge = {0.85, 0.18, 0.14}
    }
}

function MainMenu.init()
    MainMenu.selectedIndex = SaveManager.hasSave() and 1 or 2
    MainMenu.currentModal = nil
    MainMenu.chapterSelectedIndex = 1
    MainMenu.settingsSelectedIndex = 1
    MainMenu.time = 0

    MainMenu.titleFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 38) or love.graphics.newFont(38)
    MainMenu.subtitleFont = love.graphics.newFont("font/Nunito-Regular.ttf", 15) or love.graphics.newFont(15)
    MainMenu.menuFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 18) or love.graphics.newFont(18)
    MainMenu.boldFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 14) or love.graphics.newFont(14)
    MainMenu.smallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 13) or love.graphics.newFont(13)

    -- Initialize ambient floating particles
    MainMenu.particles = {}
    for i = 1, 40 do
        table.insert(MainMenu.particles, {
            x = math.random() * (love.graphics.getWidth() or 1280),
            y = math.random() * (love.graphics.getHeight() or 720),
            speedY = -10 - math.random() * 25,
            speedX = (math.random() - 0.5) * 15,
            size = 1.5 + math.random() * 3,
            alpha = 0.2 + math.random() * 0.5,
            pulse = math.random() * math.pi * 2
        })
    end
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
        { id = "new_game", label = "New Game", subtext = "Start Chapter 1 from the beginning", enabled = true },
        { id = "chapter_select", label = "Chapter Select", subtext = "Replay unlocked chapters", enabled = true },
        { id = "settings", label = "Settings & Audio", subtext = "Volume, sound effects & text speed", enabled = true },
        { id = "exit", label = "Exit to Desktop", subtext = "Quit application", enabled = true }
    }
end

function MainMenu.update(dt)
    MainMenu.time = MainMenu.time + dt

    -- Update ambient particles
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    for _, p in ipairs(MainMenu.particles) do
        p.y = p.y + p.speedY * dt
        p.x = p.x + p.speedX * dt
        p.pulse = p.pulse + dt * 1.5
        if p.y < -10 then
            p.y = screenH + 10
            p.x = math.random() * screenW
        end
        if p.x < -10 then p.x = screenW + 10 end
        if p.x > screenW + 10 then p.x = -10 end
    end
end

function MainMenu.draw()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- 1. Background Gradient
    love.graphics.setColor(MainMenu.colors.bgTop)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- 2. Ambient Floating Particles
    for _, p in ipairs(MainMenu.particles) do
        local alpha = (0.2 + 0.15 * math.sin(p.pulse)) * p.alpha
        love.graphics.setColor(0.3, 0.6, 1.0, alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end

    -- 3. Left Brand Header & Logo
    local startX = 90
    local startY = screenH * 0.18

    love.graphics.setColor(MainMenu.colors.accent)
    love.graphics.rectangle("fill", startX, startY + 6, 6, 50, 3)

    love.graphics.setFont(MainMenu.titleFont)
    love.graphics.setColor(MainMenu.colors.textPrimary)
    love.graphics.print("LYNUX CARACAL", startX + 22, startY)

    love.graphics.setFont(MainMenu.subtitleFont)
    love.graphics.setColor(MainMenu.colors.textSecondary)
    love.graphics.print("A Campus Journalism Mystery & Workstation Simulator", startX + 24, startY + 48)

    -- 4. Main Menu Buttons
    local menuItems = MainMenu.getMenuItems()
    local btnY = startY + 110
    local btnW = 420
    local btnH = 58
    local mx, my = love.mouse.getPosition()

    for i, item in ipairs(menuItems) do
        local isSelected = (MainMenu.selectedIndex == i and not MainMenu.currentModal)
        local isHovered = (mx >= startX and mx <= startX + btnW and my >= btnY and my <= btnY + btnH and not MainMenu.currentModal)

        if isHovered and not isSelected and item.enabled then
            MainMenu.selectedIndex = i
            AudioManager.playSFX("tick", 1.4)
            isSelected = true
        end

        -- Card background
        if not item.enabled then
            love.graphics.setColor(0.08, 0.10, 0.15, 0.6)
        elseif isSelected then
            love.graphics.setColor(0.12, 0.22, 0.38, 0.95)
        else
            love.graphics.setColor(0.10, 0.13, 0.20, 0.85)
        end
        love.graphics.rectangle("fill", startX, btnY, btnW, btnH, 8)

        -- Border
        if isSelected and item.enabled then
            love.graphics.setColor(MainMenu.colors.accent)
            love.graphics.rectangle("line", startX, btnY, btnW, btnH, 8)
            -- Selection highlight bar
            love.graphics.setColor(MainMenu.colors.accent)
            love.graphics.rectangle("fill", startX, btnY + 10, 4, btnH - 20, 2)
        else
            love.graphics.setColor(MainMenu.colors.border)
            love.graphics.rectangle("line", startX, btnY, btnW, btnH, 8)
        end

        -- Button Text
        love.graphics.setFont(MainMenu.menuFont)
        if not item.enabled then
            love.graphics.setColor(MainMenu.colors.textDisabled)
        elseif isSelected then
            love.graphics.setColor(MainMenu.colors.accentHover)
        else
            love.graphics.setColor(MainMenu.colors.textPrimary)
        end
        love.graphics.print(item.label, startX + 24, btnY + 10)

        -- Subtext / Save info
        if item.subtext and item.subtext ~= "" then
            love.graphics.setFont(MainMenu.smallFont)
            if not item.enabled then
                love.graphics.setColor(MainMenu.colors.textDisabled)
            elseif isSelected then
                love.graphics.setColor(0.7, 0.85, 1.0)
            else
                love.graphics.setColor(MainMenu.colors.textSecondary)
            end
            love.graphics.print(item.subtext, startX + 24, btnY + 34)
        end

        btnY = btnY + btnH + 12
    end

    -- 5. Footer Info
    love.graphics.setFont(MainMenu.smallFont)
    love.graphics.setColor(MainMenu.colors.textSecondary)
    love.graphics.print("v1.2.0 • Love2D Engine • Newspaper Club Workstation", startX, screenH - 45)

    -- 6. Modals (Chapter Select / Settings)
    if MainMenu.currentModal == "chapter_select" then
        MainMenu.drawChapterSelectModal(screenW, screenH)
    elseif MainMenu.currentModal == "settings" then
        MainMenu.drawSettingsModal(screenW, screenH)
    end
end

function MainMenu.drawChapterSelectModal(screenW, screenH)
    -- Dark overlay
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    local modalW = 620
    local modalH = 460
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2

    love.graphics.setColor(MainMenu.colors.cardBg)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setColor(MainMenu.colors.accent)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH, 12)

    -- Modal Header
    love.graphics.setFont(MainMenu.menuFont)
    love.graphics.setColor(MainMenu.colors.textPrimary)
    love.graphics.print("CHAPTER SELECT", modalX + 30, modalY + 24)

    love.graphics.setFont(MainMenu.smallFont)
    love.graphics.setColor(MainMenu.colors.textSecondary)
    love.graphics.print("Choose a chapter to begin or replay:", modalX + 30, modalY + 52)

    -- Chapter List
    local chapters = ChapterManager.getAllChapters()
    local cardY = modalY + 85
    local cardH = 95
    local cardW = modalW - 60
    local mx, my = love.mouse.getPosition()

    for i = 1, #chapters do
        local chap = chapters[i]
        local isUnlocked = (i == 1 or PlayerStats.getFlag("unlocked_chapter_" .. tostring(i)) or PlayerStats.getFlag("chapter_" .. tostring(i) .. "_started") or PlayerStats.getFlag("chapter1_completed"))
        local isSelected = (MainMenu.chapterSelectedIndex == i)
        local isHovered = (mx >= modalX + 30 and mx <= modalX + 30 + cardW and my >= cardY and my <= cardY + cardH)

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
        love.graphics.rectangle("fill", modalX + 30, cardY, cardW, cardH, 8)

        if isSelected and isUnlocked then
            love.graphics.setColor(MainMenu.colors.accent)
            love.graphics.rectangle("line", modalX + 30, cardY, cardW, cardH, 8)
        else
            love.graphics.setColor(MainMenu.colors.border)
            love.graphics.rectangle("line", modalX + 30, cardY, cardW, cardH, 8)
        end

        -- Chapter Title
        love.graphics.setFont(MainMenu.boldFont)
        if not isUnlocked then
            love.graphics.setColor(MainMenu.colors.textDisabled)
            love.graphics.print(chap.title .. " (Locked)", modalX + 48, cardY + 14)
        else
            love.graphics.setColor(isSelected and MainMenu.colors.accentHover or MainMenu.colors.textPrimary)
            love.graphics.print(chap.title .. ": " .. chap.subtitle, modalX + 48, cardY + 14)
        end

        -- Chapter Description
        love.graphics.setFont(MainMenu.smallFont)
        if not isUnlocked then
            love.graphics.setColor(MainMenu.colors.textDisabled)
            love.graphics.print("Complete previous chapter objectives to unlock.", modalX + 48, cardY + 40)
        else
            love.graphics.setColor(MainMenu.colors.textSecondary)
            love.graphics.printf(chap.desc, modalX + 48, cardY + 38, cardW - 70, "left")
        end

        cardY = cardY + cardH + 14
    end

    -- Close Button
    local closeBtnW = 140
    local closeBtnH = 38
    local closeBtnX = modalX + modalW - closeBtnW - 30
    local closeBtnY = modalY + modalH - closeBtnH - 24
    local closeHovered = (mx >= closeBtnX and mx <= closeBtnX + closeBtnW and my >= closeBtnY and my <= closeBtnY + closeBtnH)

    love.graphics.setColor(closeHovered and MainMenu.colors.accentHover or MainMenu.colors.accent)
    love.graphics.rectangle("fill", closeBtnX, closeBtnY, closeBtnW, closeBtnH, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(MainMenu.boldFont)
    love.graphics.printf("Close (ESC)", closeBtnX, closeBtnY + 10, closeBtnW, "center")
end

function MainMenu.drawSettingsModal(screenW, screenH)
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    local modalW = 540
    local modalH = 380
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2

    love.graphics.setColor(MainMenu.colors.cardBg)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setColor(MainMenu.colors.accent)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH, 12)

    love.graphics.setFont(MainMenu.menuFont)
    love.graphics.setColor(MainMenu.colors.textPrimary)
    love.graphics.print("SETTINGS & AUDIO", modalX + 30, modalY + 24)

    -- Option 1: BGM Volume
    local optY = modalY + 80
    love.graphics.setFont(MainMenu.boldFont)
    love.graphics.setColor(MainMenu.settingsSelectedIndex == 1 and MainMenu.colors.accentHover or MainMenu.colors.textPrimary)
    love.graphics.print("Music Volume (BGM): " .. math.floor(AudioManager.bgmVolume * 100) .. "%", modalX + 35, optY)
    
    -- Slider bar
    love.graphics.setColor(0.18, 0.22, 0.32)
    love.graphics.rectangle("fill", modalX + 35, optY + 25, 400, 10, 5)
    love.graphics.setColor(MainMenu.colors.accent)
    love.graphics.rectangle("fill", modalX + 35, optY + 25, 400 * AudioManager.bgmVolume, 10, 5)
    love.graphics.circle("fill", modalX + 35 + (400 * AudioManager.bgmVolume), optY + 30, 8)

    -- Option 2: SFX Volume
    optY = optY + 70
    love.graphics.setColor(MainMenu.settingsSelectedIndex == 2 and MainMenu.colors.accentHover or MainMenu.colors.textPrimary)
    love.graphics.print("Sound Effects (SFX): " .. math.floor(AudioManager.sfxVolume * 100) .. "%", modalX + 35, optY)
    love.graphics.setColor(0.18, 0.22, 0.32)
    love.graphics.rectangle("fill", modalX + 35, optY + 25, 400, 10, 5)
    love.graphics.setColor(MainMenu.colors.accent)
    love.graphics.rectangle("fill", modalX + 35, optY + 25, 400 * AudioManager.sfxVolume, 10, 5)
    love.graphics.circle("fill", modalX + 35 + (400 * AudioManager.sfxVolume), optY + 30, 8)

    -- Option 3: Text Speed
    optY = optY + 70
    local speedLabel = DialogueBox.typeSpeed <= 0.015 and "Fast" or (DialogueBox.typeSpeed <= 0.035 and "Normal" or "Slow")
    love.graphics.setColor(MainMenu.settingsSelectedIndex == 3 and MainMenu.colors.accentHover or MainMenu.colors.textPrimary)
    love.graphics.print("Text Typewriter Speed: " .. speedLabel, modalX + 35, optY)

    -- Close Button
    local mx, my = love.mouse.getPosition()
    local closeBtnW = 140
    local closeBtnH = 38
    local closeBtnX = modalX + modalW - closeBtnW - 30
    local closeBtnY = modalY + modalH - closeBtnH - 24
    local closeHovered = (mx >= closeBtnX and mx <= closeBtnX + closeBtnW and my >= closeBtnY and my <= closeBtnY + closeBtnH)

    love.graphics.setColor(closeHovered and MainMenu.colors.accentHover or MainMenu.colors.accent)
    love.graphics.rectangle("fill", closeBtnX, closeBtnY, closeBtnW, closeBtnH, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(MainMenu.boldFont)
    love.graphics.printf("Close (ESC)", closeBtnX, closeBtnY + 10, closeBtnW, "center")
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

    if MainMenu.currentModal == "chapter_select" then
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        local modalW = 620
        local modalH = 460
        local modalX = (screenW - modalW) / 2
        local modalY = (screenH - modalH) / 2

        -- Check Close button
        local closeBtnW = 140
        local closeBtnH = 38
        local closeBtnX = modalX + modalW - closeBtnW - 30
        local closeBtnY = modalY + modalH - closeBtnH - 24
        if x >= closeBtnX and x <= closeBtnX + closeBtnW and y >= closeBtnY and y <= closeBtnY + closeBtnH then
            MainMenu.currentModal = nil
            AudioManager.playSFX("click")
            return
        end

        -- Check chapter card click
        local chapters = ChapterManager.getAllChapters()
        local cardY = modalY + 85
        local cardH = 95
        local cardW = modalW - 60
        for i = 1, #chapters do
            if x >= modalX + 30 and x <= modalX + 30 + cardW and y >= cardY and y <= cardY + cardH then
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
            cardY = cardY + cardH + 14
        end

    elseif MainMenu.currentModal == "settings" then
        local screenW = love.graphics.getWidth()
        local screenH = love.graphics.getHeight()
        local modalW = 540
        local modalH = 380
        local modalX = (screenW - modalW) / 2
        local modalY = (screenH - modalH) / 2

        -- Check Close button
        local closeBtnW = 140
        local closeBtnH = 38
        local closeBtnX = modalX + modalW - closeBtnW - 30
        local closeBtnY = modalY + modalH - closeBtnH - 24
        if x >= closeBtnX and x <= closeBtnX + closeBtnW and y >= closeBtnY and y <= closeBtnY + closeBtnH then
            MainMenu.currentModal = nil
            AudioManager.playSFX("click")
            return
        end

        -- Slider 1: BGM
        local bgmY = modalY + 80 + 25
        if x >= modalX + 35 and x <= modalX + 435 and y >= bgmY - 10 and y <= bgmY + 20 then
            local val = (x - (modalX + 35)) / 400
            AudioManager.setBGMVolume(val)
            AudioManager.playSFX("tick", 1.2)
            return
        end

        -- Slider 2: SFX
        local sfxY = modalY + 150 + 25
        if x >= modalX + 35 and x <= modalX + 435 and y >= sfxY - 10 and y <= sfxY + 20 then
            local val = (x - (modalX + 35)) / 400
            AudioManager.setSFXVolume(val)
            AudioManager.playSFX("tick", 1.2)
            return
        end

        -- Option 3: Text Speed toggle
        local spdY = modalY + 220
        if x >= modalX + 35 and x <= modalX + 435 and y >= spdY and y <= spdY + 30 then
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
        -- Main menu option click
        local screenH = love.graphics.getHeight()
        local startX = 90
        local startY = screenH * 0.18 + 110
        local btnW = 420
        local btnH = 58
        local menuItems = MainMenu.getMenuItems()

        for i, item in ipairs(menuItems) do
            local by = startY + (i - 1) * (btnH + 12)
            if x >= startX and x <= startX + btnW and y >= by and y <= by + btnH then
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
