-- src/ui/pause_menu.lua
-- Professional, high-polish ESC Pause & Settings Menu with Retro Yellow Gaming / Kawaii aesthetic

local AudioManager = require("src.core.audio_manager")
local EventBus = require("src.core.event_bus")
local PlayerStats = require("src.core.player_stats")

local PauseMenu = {
    isOpen = false,
    currentTab = "main", -- "main", "settings", "confirm_reset"
    selectedIndex = 1,
    font = nil,
    titleFont = nil,
    smallFont = nil,
    
    -- Settings states
    sfxVolume = 1.0,
    bgmVolume = 0.8,
    textSpeed = "Normal", -- "Fast", "Normal", "Slow"
    textSpeeds = { "Fast", "Normal", "Slow" },
    textSpeedIndex = 2,
    
    -- Main Menu Items
    mainItems = {
        { id = "resume", label = "Resume Game", icon = "▶", desc = "Return to current gameplay" },
        { id = "switch_mode", label = "Switch Story / PC Mode", icon = "🔄", desc = "Toggle between Visual Novel & Desktop" },
        { id = "settings", label = "Settings & Audio", icon = "⚙", desc = "Volume sliders and text options" },
        { id = "reset", label = "Reset Chapter", icon = "↺", desc = "Restart narrative from beginning" },
        { id = "exit", label = "Exit to Desktop", icon = "✕", desc = "Safely quit the application" }
    },
    
    -- Settings Menu Items
    settingsItems = {
        { id = "sfx_vol", label = "SFX Volume", type = "slider" },
        { id = "bgm_vol", label = "Music Volume", type = "slider" },
        { id = "text_speed", label = "Text Speed", type = "choice" },
        { id = "back", label = "Back to Menu", type = "button" }
    }
}

function PauseMenu.init()
    PauseMenu.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    PauseMenu.titleFont = love.graphics.newFont("font/Nunito-Regular.ttf", 16) or love.graphics.newFont(16)
    PauseMenu.smallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 11) or love.graphics.newFont(11)
    PauseMenu.isOpen = false
    PauseMenu.currentTab = "main"
    PauseMenu.selectedIndex = 1
    PauseMenu.sfxVolume = AudioManager.sfxVolume or 1.0
    PauseMenu.bgmVolume = AudioManager.bgmVolume or 0.8
end

function PauseMenu.open()
    PauseMenu.isOpen = true
    PauseMenu.currentTab = "main"
    PauseMenu.selectedIndex = 1
    AudioManager.playSFX("notification", 1.1)
end

function PauseMenu.close()
    PauseMenu.isOpen = false
    AudioManager.playSFX("click", 1.2)
end

function PauseMenu.toggle()
    if PauseMenu.isOpen then
        PauseMenu.close()
    else
        PauseMenu.open()
    end
end

function PauseMenu.activateCurrent()
    if PauseMenu.currentTab == "main" then
        local item = PauseMenu.mainItems[PauseMenu.selectedIndex]
        if not item then return end

        if item.id == "resume" then
            PauseMenu.close()
        elseif item.id == "switch_mode" then
            PauseMenu.close()
            EventBus.emit("game:request_switch_mode", { transition = "fade" })
        elseif item.id == "settings" then
            PauseMenu.currentTab = "settings"
            PauseMenu.selectedIndex = 1
            AudioManager.playSFX("click")
        elseif item.id == "reset" then
            PauseMenu.currentTab = "confirm_reset"
            PauseMenu.selectedIndex = 1
            AudioManager.playSFX("notification")
        elseif item.id == "exit" then
            AudioManager.playSFX("click")
            love.event.quit()
        end

    elseif PauseMenu.currentTab == "settings" then
        local item = PauseMenu.settingsItems[PauseMenu.selectedIndex]
        if not item then return end

        if item.id == "back" then
            PauseMenu.currentTab = "main"
            PauseMenu.selectedIndex = 3 -- Return to Settings button
            AudioManager.playSFX("click")
        elseif item.id == "text_speed" then
            PauseMenu.textSpeedIndex = (PauseMenu.textSpeedIndex % #PauseMenu.textSpeeds) + 1
            PauseMenu.textSpeed = PauseMenu.textSpeeds[PauseMenu.textSpeedIndex]
            
            -- Apply to DialogueBox
            local DialogueBox = require("src.story.dialogue_box")
            if PauseMenu.textSpeed == "Fast" then
                DialogueBox.typeSpeed = 0.01
            elseif PauseMenu.textSpeed == "Slow" then
                DialogueBox.typeSpeed = 0.04
            else
                DialogueBox.typeSpeed = 0.022
            end
            AudioManager.playSFX("tick", 1.2)
        end

    elseif PauseMenu.currentTab == "confirm_reset" then
        if PauseMenu.selectedIndex == 1 then
            -- Confirm Reset
            PauseMenu.close()
            local StoryEngine = require("src.story.story_engine")
            StoryEngine.restart()
            EventBus.emit("game:request_switch_mode", { mode = "story", transition = "fade" })
            AudioManager.playSFX("switch")
        else
            -- Cancel Reset
            PauseMenu.currentTab = "main"
            PauseMenu.selectedIndex = 1
            AudioManager.playSFX("click")
        end
    end
end

function PauseMenu.keypressed(key)
    if not PauseMenu.isOpen then
        if key == "escape" then
            PauseMenu.open()
            return true
        end
        return false
    end

    -- Close on ESC if in main tab, or go back if in sub-tab
    if key == "escape" then
        if PauseMenu.currentTab == "main" then
            PauseMenu.close()
        else
            PauseMenu.currentTab = "main"
            PauseMenu.selectedIndex = 1
            AudioManager.playSFX("click")
        end
        return true
    end

    local itemsCount = (PauseMenu.currentTab == "main") and #PauseMenu.mainItems 
                    or ((PauseMenu.currentTab == "settings") and #PauseMenu.settingsItems or 2)

    if key == "up" or key == "w" then
        PauseMenu.selectedIndex = math.max(1, PauseMenu.selectedIndex - 1)
        AudioManager.playSFX("tick", 1.1, 0.4)
        return true
    elseif key == "down" or key == "s" then
        PauseMenu.selectedIndex = math.min(itemsCount, PauseMenu.selectedIndex + 1)
        AudioManager.playSFX("tick", 1.1, 0.4)
        return true
    elseif key == "left" or key == "a" then
        if PauseMenu.currentTab == "settings" then
            if PauseMenu.selectedIndex == 1 then
                -- SFX Slider
                PauseMenu.sfxVolume = math.max(0, math.min(1, PauseMenu.sfxVolume - 0.1))
                AudioManager.setSFXVolume(PauseMenu.sfxVolume)
                AudioManager.playSFX("tick", 1.2)
            elseif PauseMenu.selectedIndex == 2 then
                -- BGM Slider
                PauseMenu.bgmVolume = math.max(0, math.min(1, PauseMenu.bgmVolume - 0.1))
                AudioManager.setBGMVolume(PauseMenu.bgmVolume)
                AudioManager.playSFX("tick", 1.2)
            elseif PauseMenu.selectedIndex == 3 then
                PauseMenu.textSpeedIndex = (PauseMenu.textSpeedIndex - 2) % #PauseMenu.textSpeeds + 1
                PauseMenu.textSpeed = PauseMenu.textSpeeds[PauseMenu.textSpeedIndex]
                AudioManager.playSFX("tick", 1.2)
            end
        end
        return true
    elseif key == "right" or key == "d" then
        if PauseMenu.currentTab == "settings" then
            if PauseMenu.selectedIndex == 1 then
                PauseMenu.sfxVolume = math.max(0, math.min(1, PauseMenu.sfxVolume + 0.1))
                AudioManager.setSFXVolume(PauseMenu.sfxVolume)
                AudioManager.playSFX("tick", 1.2)
            elseif PauseMenu.selectedIndex == 2 then
                PauseMenu.bgmVolume = math.max(0, math.min(1, PauseMenu.bgmVolume + 0.1))
                AudioManager.setBGMVolume(PauseMenu.bgmVolume)
                AudioManager.playSFX("tick", 1.2)
            elseif PauseMenu.selectedIndex == 3 then
                PauseMenu.textSpeedIndex = (PauseMenu.textSpeedIndex % #PauseMenu.textSpeeds) + 1
                PauseMenu.textSpeed = PauseMenu.textSpeeds[PauseMenu.textSpeedIndex]
                AudioManager.playSFX("tick", 1.2)
            end
        end
        return true
    elseif key == "return" or key == "space" then
        PauseMenu.activateCurrent()
        return true
    elseif tonumber(key) and tonumber(key) >= 1 and tonumber(key) <= itemsCount then
        PauseMenu.selectedIndex = tonumber(key)
        PauseMenu.activateCurrent()
        return true
    end

    return true
end

function PauseMenu.mousepressed(x, y, button)
    if not PauseMenu.isOpen or button ~= 1 then return false end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local cardW = 380
    local cardH = 320
    local cardX = (screenW - cardW) / 2
    local cardY = (screenH - cardH) / 2

    -- Close if clicking outside the card
    if x < cardX or x > cardX + cardW or y < cardY or y > cardY + cardH then
        PauseMenu.close()
        return true
    end

    local itemYStart = cardY + 56
    local itemH = 40
    local itemSpacing = 8

    if PauseMenu.currentTab == "main" then
        for i, item in ipairs(PauseMenu.mainItems) do
            local iy = itemYStart + (i - 1) * (itemH + itemSpacing)
            if x >= cardX + 16 and x <= cardX + cardW - 16 and y >= iy and y <= iy + itemH then
                PauseMenu.selectedIndex = i
                PauseMenu.activateCurrent()
                return true
            end
        end

    elseif PauseMenu.currentTab == "settings" then
        for i, item in ipairs(PauseMenu.settingsItems) do
            local iy = itemYStart + (i - 1) * (itemH + itemSpacing)
            if x >= cardX + 16 and x <= cardX + cardW - 16 and y >= iy and y <= iy + itemH then
                PauseMenu.selectedIndex = i
                
                if item.type == "slider" then
                    local sliderX = cardX + cardW - 140
                    local sliderW = 120
                    if x >= sliderX and x <= sliderX + sliderW then
                        local ratio = math.max(0, math.min(1, (x - sliderX) / sliderW))
                        if item.id == "sfx_vol" then
                            PauseMenu.sfxVolume = ratio
                            AudioManager.setSFXVolume(ratio)
                            AudioManager.playSFX("tick", 1.2)
                        elseif item.id == "bgm_vol" then
                            PauseMenu.bgmVolume = ratio
                            AudioManager.setBGMVolume(ratio)
                            AudioManager.playSFX("tick", 1.2)
                        end
                    end
                else
                    PauseMenu.activateCurrent()
                end
                return true
            end
        end

    elseif PauseMenu.currentTab == "confirm_reset" then
        local btnY = cardY + 180
        local btnW = 150
        local btnH = 36

        -- Yes button
        local yesX = cardX + 30
        if x >= yesX and x <= yesX + btnW and y >= btnY and y <= btnY + btnH then
            PauseMenu.selectedIndex = 1
            PauseMenu.activateCurrent()
            return true
        end

        -- No button
        local noX = cardX + cardW - btnW - 30
        if x >= noX and x <= noX + btnW and y >= btnY and y <= btnY + btnH then
            PauseMenu.selectedIndex = 2
            PauseMenu.activateCurrent()
            return true
        end
    end

    return true
end

function PauseMenu.mousemoved(x, y)
    if not PauseMenu.isOpen then return end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local cardW = 380
    local cardH = 320
    local cardX = (screenW - cardW) / 2
    local cardY = (screenH - cardH) / 2

    local itemYStart = cardY + 56
    local itemH = 40
    local itemSpacing = 8

    if PauseMenu.currentTab == "main" then
        for i, _ in ipairs(PauseMenu.mainItems) do
            local iy = itemYStart + (i - 1) * (itemH + itemSpacing)
            if x >= cardX + 16 and x <= cardX + cardW - 16 and y >= iy and y <= iy + itemH then
                if PauseMenu.selectedIndex ~= i then
                    PauseMenu.selectedIndex = i
                    AudioManager.playSFX("tick", 1.2, 0.3)
                end
                break
            end
        end
    elseif PauseMenu.currentTab == "settings" then
        for i, _ in ipairs(PauseMenu.settingsItems) do
            local iy = itemYStart + (i - 1) * (itemH + itemSpacing)
            if x >= cardX + 16 and x <= cardX + cardW - 16 and y >= iy and y <= iy + itemH then
                if PauseMenu.selectedIndex ~= i then
                    PauseMenu.selectedIndex = i
                    AudioManager.playSFX("tick", 1.2, 0.3)
                end
                break
            end
        end
    end
end

function PauseMenu.draw()
    if not PauseMenu.isOpen then return end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local cardW = 380
    local cardH = 325
    local cardX = (screenW - cardW) / 2
    local cardY = (screenH - cardH) / 2

    love.graphics.push()

    -- Dark Translucent Vignette Backdrop
    love.graphics.setColor(0.08, 0.07, 0.1, 0.78)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Drop Shadow
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", cardX + 4, cardY + 4, cardW, cardH, 8, 8)

    -- Card Background (Warm Retro Dark Slate)
    love.graphics.setColor(0.12, 0.11, 0.15, 0.98)
    love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 8, 8)

    -- Retro Sunny Yellow Accent Border
    love.graphics.setColor(1.0, 0.82, 0.25, 0.95)
    love.graphics.setLineWidth(1.6)
    love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 8, 8)

    -- Card Header Bar
    love.graphics.setColor(0.18, 0.16, 0.22, 0.95)
    love.graphics.rectangle("fill", cardX, cardY, cardW, 42, 8, 8)
    love.graphics.rectangle("fill", cardX, cardY + 34, cardW, 8)
    love.graphics.setColor(1.0, 0.82, 0.25, 0.35)
    love.graphics.line(cardX, cardY + 42, cardX + cardW, cardY + 42)

    -- Header Title
    love.graphics.setFont(PauseMenu.titleFont or PauseMenu.font)
    love.graphics.setColor(1.0, 0.85, 0.3)
    if PauseMenu.currentTab == "main" then
        love.graphics.printf("★ GAME PAUSED ★", cardX, cardY + 11, cardW, "center")
    elseif PauseMenu.currentTab == "settings" then
        love.graphics.printf("⚙ SETTINGS & AUDIO ⚙", cardX, cardY + 11, cardW, "center")
    elseif PauseMenu.currentTab == "confirm_reset" then
        love.graphics.printf("⚠ RESTART CHAPTER? ⚠", cardX, cardY + 11, cardW, "center")
    end

    local itemYStart = cardY + 54
    local itemH = 40
    local itemSpacing = 8

    -- MAIN TAB
    if PauseMenu.currentTab == "main" then
        for i, item in ipairs(PauseMenu.mainItems) do
            local iy = itemYStart + (i - 1) * (itemH + itemSpacing)
            local isSelected = (i == PauseMenu.selectedIndex)

            -- Item Card
            if isSelected then
                love.graphics.setColor(0.24, 0.2, 0.16, 0.96)
                love.graphics.rectangle("fill", cardX + 16, iy, cardW - 32, itemH, 4, 4)
                love.graphics.setColor(1.0, 0.82, 0.25, 1.0)
                love.graphics.setLineWidth(1.4)
                love.graphics.rectangle("line", cardX + 16, iy, cardW - 32, itemH, 4, 4)
            else
                love.graphics.setColor(0.16, 0.14, 0.19, 0.7)
                love.graphics.rectangle("fill", cardX + 16, iy, cardW - 32, itemH, 4, 4)
                love.graphics.setColor(0.28, 0.25, 0.32, 0.5)
                love.graphics.setLineWidth(1)
                love.graphics.rectangle("line", cardX + 16, iy, cardW - 32, itemH, 4, 4)
            end

            -- Number & Icon
            love.graphics.setFont(PauseMenu.font)
            if isSelected then
                love.graphics.setColor(1.0, 0.85, 0.3)
                love.graphics.print("▶ [" .. tostring(i) .. "] " .. item.label, cardX + 28, iy + 6)
                love.graphics.setFont(PauseMenu.smallFont)
                love.graphics.setColor(1.0, 0.92, 0.75, 0.85)
                love.graphics.print(item.desc, cardX + 54, iy + 23)
            else
                love.graphics.setColor(0.7, 0.65, 0.55)
                love.graphics.print("  [" .. tostring(i) .. "] " .. item.label, cardX + 28, iy + 6)
                love.graphics.setFont(PauseMenu.smallFont)
                love.graphics.setColor(0.65, 0.62, 0.68, 0.7)
                love.graphics.print(item.desc, cardX + 54, iy + 23)
            end
        end

    -- SETTINGS TAB
    elseif PauseMenu.currentTab == "settings" then
        for i, item in ipairs(PauseMenu.settingsItems) do
            local iy = itemYStart + (i - 1) * (itemH + itemSpacing)
            local isSelected = (i == PauseMenu.selectedIndex)

            if isSelected then
                love.graphics.setColor(0.24, 0.2, 0.16, 0.96)
                love.graphics.rectangle("fill", cardX + 16, iy, cardW - 32, itemH, 4, 4)
                love.graphics.setColor(1.0, 0.82, 0.25, 1.0)
                love.graphics.setLineWidth(1.4)
                love.graphics.rectangle("line", cardX + 16, iy, cardW - 32, itemH, 4, 4)
            else
                love.graphics.setColor(0.16, 0.14, 0.19, 0.7)
                love.graphics.rectangle("fill", cardX + 16, iy, cardW - 32, itemH, 4, 4)
                love.graphics.setColor(0.28, 0.25, 0.32, 0.5)
                love.graphics.setLineWidth(1)
                love.graphics.rectangle("line", cardX + 16, iy, cardW - 32, itemH, 4, 4)
            end

            love.graphics.setFont(PauseMenu.font)
            if isSelected then
                love.graphics.setColor(1.0, 0.85, 0.3)
                love.graphics.print(item.label, cardX + 28, iy + 11)
            else
                love.graphics.setColor(0.9, 0.88, 0.84)
                love.graphics.print(item.label, cardX + 28, iy + 11)
            end

            -- Controls on the right
            if item.type == "slider" then
                local sliderVal = (item.id == "sfx_vol") and PauseMenu.sfxVolume or PauseMenu.bgmVolume
                local sliderX = cardX + cardW - 150
                local sliderY = iy + 14
                local sliderW = 120
                local sliderH = 12

                -- Background bar
                love.graphics.setColor(0.1, 0.09, 0.12)
                love.graphics.rectangle("fill", sliderX, sliderY, sliderW, sliderH, 3, 3)
                
                -- Filled bar
                love.graphics.setColor(1.0, 0.82, 0.25, 0.85)
                love.graphics.rectangle("fill", sliderX, sliderY, sliderW * sliderVal, sliderH, 3, 3)
                love.graphics.setColor(1.0, 0.85, 0.3, 0.6)
                love.graphics.rectangle("line", sliderX, sliderY, sliderW, sliderH, 3, 3)

                -- Percentage text
                love.graphics.setFont(PauseMenu.smallFont)
                love.graphics.setColor(1.0, 1.0, 1.0)
                love.graphics.printf(tostring(math.floor(sliderVal * 100)) .. "%", sliderX, sliderY - 1, sliderW, "center")

            elseif item.type == "choice" then
                love.graphics.setFont(PauseMenu.font)
                love.graphics.setColor(0.2, 0.88, 0.55) -- Pastel Mint
                love.graphics.printf("< " .. PauseMenu.textSpeed .. " >", cardX + cardW - 140, iy + 11, 110, "center")

            elseif item.type == "button" then
                love.graphics.setFont(PauseMenu.font)
                love.graphics.setColor(1.0, 0.85, 0.3)
                love.graphics.printf("◀ Back", cardX + cardW - 120, iy + 11, 90, "center")
            end
        end

    -- CONFIRM RESET TAB
    elseif PauseMenu.currentTab == "confirm_reset" then
        love.graphics.setFont(PauseMenu.font)
        love.graphics.setColor(1.0, 0.95, 0.9)
        love.graphics.printf("Are you sure you want to restart the current chapter?\n\nAll current progress and unsaved files will be re-initialized.", cardX + 24, cardY + 70, cardW - 48, "center")

        local btnY = cardY + 210
        local btnW = 140
        local btnH = 38

        -- Option 1: Yes Reset (Selected = 1)
        local yesX = cardX + 36
        if PauseMenu.selectedIndex == 1 then
            love.graphics.setColor(1.0, 0.35, 0.45, 0.95) -- Strawberry Red
            love.graphics.rectangle("fill", yesX, btnY, btnW, btnH, 4, 4)
            love.graphics.setColor(1.0, 0.85, 0.3)
            love.graphics.rectangle("line", yesX, btnY, btnW, btnH, 4, 4)
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.22, 0.14, 0.16, 0.8)
            love.graphics.rectangle("fill", yesX, btnY, btnW, btnH, 4, 4)
            love.graphics.setColor(0.8, 0.4, 0.45, 0.6)
            love.graphics.rectangle("line", yesX, btnY, btnW, btnH, 4, 4)
            love.graphics.setColor(0.85, 0.75, 0.78)
        end
        love.graphics.printf("Yes, Restart", yesX, btnY + 10, btnW, "center")

        -- Option 2: Cancel (Selected = 2)
        local noX = cardX + cardW - btnW - 36
        if PauseMenu.selectedIndex == 2 then
            love.graphics.setColor(0.2, 0.88, 0.55, 0.95) -- Pastel Mint
            love.graphics.rectangle("fill", noX, btnY, btnW, btnH, 4, 4)
            love.graphics.setColor(1.0, 0.85, 0.3)
            love.graphics.rectangle("line", noX, btnY, btnW, btnH, 4, 4)
            love.graphics.setColor(0.1, 0.15, 0.12)
        else
            love.graphics.setColor(0.14, 0.18, 0.16, 0.8)
            love.graphics.rectangle("fill", noX, btnY, btnW, btnH, 4, 4)
            love.graphics.setColor(0.3, 0.6, 0.45, 0.6)
            love.graphics.rectangle("line", noX, btnY, btnW, btnH, 4, 4)
            love.graphics.setColor(0.75, 0.85, 0.8)
        end
        love.graphics.printf("Cancel", noX, btnY + 10, btnW, "center")
    end

    love.graphics.pop()
end

return PauseMenu
