-- src/story/character_mgr.lua
-- Character Profiles, Sprite Asset Loader & Fallback Management

local CharacterManager = {
    characters = {
        ["Aki"] = {
            name = "Aki",
            color = {0.29, 0.56, 0.89}, -- Soft Sky Blue
            isProtagonist = true,
            title = "Newspaper Club Reporter"
        },
        ["Protagonist"] = {
            name = "Aki",
            color = {0.29, 0.56, 0.89}, -- Soft Sky Blue
            isProtagonist = true,
            title = "Me"
        },
        ["Suzumia"] = {
            name = "Suzumia",
            color = {0.94, 0.48, 0.58}, -- Sakura Rose Pink
            sprite = "data/characters/suzumia.png",
            title = "Vice President"
        },
        ["Nagahashi"] = {
            name = "Nagahashi",
            color = {0.95, 0.65, 0.22}, -- Bold Amber
            sprite = "data/characters/nagahashi.png",
            title = "Club President"
        },
        ["Hoshida"] = {
            name = "Hoshida",
            color = {0.32, 0.72, 0.48}, -- Soft Forest Green
            sprite = "data/characters/hoshida.png",
            title = "Club Member"
        },
        ["Hoshida (Anon)"] = {
            name = "Hoshida [Root]",
            color = {0.72, 0.38, 0.88}, -- Cyber Violet
            sprite = "data/characters/hoshida.png",
            title = "SysAdmin / Hacker"
        },
        ["Hiko"] = {
            name = "Hiko",
            color = {0.22, 0.78, 0.85}, -- Bright Turquoise / Cyan
            sprite = "data/characters/hiko.png",
            title = "Sister (1st Year)"
        },
        ["Student Council"] = {
            name = "Council Rep",
            color = {0.62, 0.65, 0.72}, -- Slate Silver
            sprite = "data/characters/student_council.png",
            title = "Student Council"
        },
        ["Ghost"] = {
            name = "Ghost [Unknown]",
            color = {0.89, 0.35, 0.35}, -- Crimson Red
            sprite = "data/characters/ghost.png",
            title = "Intruder"
        },
        ["System"] = {
            name = "System",
            color = {0.18, 0.75, 0.45}, -- Clean Green
            sprite = "data/characters/system.png",
            title = "OS Kernel"
        }
    },
    activeCharacters = {},
    imageCache = {},
    fontSmall = nil,
    fontBold = nil
}

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

function CharacterManager.init()
    CharacterManager.activeCharacters = {}
    CharacterManager.imageCache = {}
    CharacterManager.fontSmall = loadCustomFont("font/Nunito-Regular.ttf", 11)
    CharacterManager.fontBold = loadCustomFont("font/IBMPlexSans-Bold.ttf", 12)
end

function CharacterManager.get(id)
    return CharacterManager.characters[id] or {
        name = id or "Unknown",
        color = {0.29, 0.56, 0.89},
        title = ""
    }
end

function CharacterManager.getSprite(characterId)
    local charInfo = CharacterManager.get(characterId)
    
    -- Protagonist does not require a sprite on stage
    if charInfo.isProtagonist or characterId == "Aki" or characterId == "Protagonist" then
        return nil, nil
    end

    -- Determine default expected sprite path
    local rawName = string.lower(string.gsub(characterId, "[%s%(%)%[%]]+", "_"))
    local defaultPath = charInfo.sprite or ("data/characters/" .. rawName .. ".png")

    -- Check cache
    if CharacterManager.imageCache[defaultPath] ~= nil then
        return CharacterManager.imageCache[defaultPath], defaultPath
    end

    -- Candidate paths to search
    local candidatePaths = {
        charInfo.sprite,
        "data/characters/" .. rawName .. ".png",
        "data/characters/" .. string.lower(characterId) .. ".png",
        "data/characters/" .. characterId .. ".png",
        "data/characters/" .. rawName .. ".jpg"
    }

    for _, path in ipairs(candidatePaths) do
        if path then
            if CharacterManager.imageCache[path] then
                return CharacterManager.imageCache[path], path
            end
            local ok, img = pcall(love.graphics.newImage, path)
            if ok and img then
                CharacterManager.imageCache[path] = img
                CharacterManager.imageCache[defaultPath] = img
                return img, path
            end
        end
    end

    -- Mark as not found in cache so we know it's missing
    CharacterManager.imageCache[defaultPath] = false
    return nil, defaultPath
end

function CharacterManager.show(characterId, position, expression, flipped)
    position = position or "center"
    CharacterManager.activeCharacters[position] = {
        characterId = characterId,
        expression = expression or "normal",
        flipped = (flipped == true),
        alpha = 1.0
    }
end

function CharacterManager.hide(position)
    if position then
        CharacterManager.activeCharacters[position] = nil
    else
        CharacterManager.activeCharacters = {}
    end
end

function CharacterManager.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local posCoords = {
        far_left = { x = w * 0.12 },
        left     = { x = w * 0.24 },
        center   = { x = w * 0.50 },
        right    = { x = w * 0.76 },
        far_right= { x = w * 0.88 }
    }

    for posKey, charData in pairs(CharacterManager.activeCharacters) do
        local coords = posCoords[posKey] or posCoords.center
        local charInfo = CharacterManager.get(charData.characterId)
        
        -- Protagonist doesn't need a sprite
        if not charInfo.isProtagonist and charData.characterId ~= "Aki" and charData.characterId ~= "Protagonist" then
            local img, spriteSrc = CharacterManager.getSprite(charData.characterId)
            local alpha = charData.alpha or 1.0

            love.graphics.push()

            if img then
                -- Render loaded visual novel character sprite with mirror/flip support
                local targetHeight = math.min(h * 0.78, 640)
                local scale = targetHeight / img:getHeight()
                local imgW = img:getWidth() * scale
                local imgH = img:getHeight() * scale

                local scaleX = charData.flipped and -scale or scale
                local drawX = charData.flipped and math.floor(coords.x + imgW / 2) or math.floor(coords.x - imgW / 2)
                local drawY = math.floor(h - imgH + 15) -- grounded near bottom

                love.graphics.setColor(1, 1, 1, alpha)
                love.graphics.draw(img, drawX, drawY, 0, scaleX, scale)

            else
                -- Missing sprite: Developer placeholder card displaying target sprite source
                local cardW = math.min(220, math.floor(w * 0.26))
                local cardH = math.min(300, math.floor(h * 0.52))
                local cardX = math.floor(coords.x - cardW / 2)
                local cardY = math.floor(h * 0.42 - cardH / 2)

                -- Semi-transparent dark blue card body
                love.graphics.setColor(0.06, 0.09, 0.16, 0.88 * alpha)
                love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 6, 6)

                -- Accent border in character's theme color
                local col = charInfo.color or {0.3, 0.6, 0.9}
                love.graphics.setColor(col[1], col[2], col[3], 0.9 * alpha)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 6, 6)

                -- Top title bar
                love.graphics.setColor(col[1], col[2], col[3], 0.25 * alpha)
                love.graphics.rectangle("fill", cardX + 1, cardY + 1, cardW - 2, 28, 5, 5)

                -- Character Name
                love.graphics.setFont(CharacterManager.fontBold or love.graphics.getFont())
                love.graphics.setColor(1, 1, 1, alpha)
                love.graphics.printf(charInfo.name or charData.characterId, cardX, cardY + 6, cardW, "center")

                -- Placeholder tag & position
                love.graphics.setFont(CharacterManager.fontSmall or love.graphics.getFont())
                love.graphics.setColor(0.95, 0.45, 0.45, alpha)
                love.graphics.printf("[Missing Sprite]", cardX + 8, cardY + 38, cardW - 16, "center")

                if charData.flipped then
                    love.graphics.setColor(0.9, 0.75, 0.35, alpha)
                    love.graphics.printf("[Mirrored] Pos: " .. tostring(posKey), cardX + 8, cardY + 58, cardW - 16, "center")
                else
                    love.graphics.setColor(0.7, 0.78, 0.9, alpha)
                    love.graphics.printf("Position: " .. tostring(posKey), cardX + 8, cardY + 58, cardW - 16, "center")
                end

                -- Sprite Source Path box
                love.graphics.setColor(0.04, 0.06, 0.11, 0.9 * alpha)
                love.graphics.rectangle("fill", cardX + 10, cardY + 82, cardW - 20, 68, 4, 4)
                love.graphics.setColor(0.18, 0.24, 0.36, alpha)
                love.graphics.rectangle("line", cardX + 10, cardY + 82, cardW - 20, 68, 4, 4)

                love.graphics.setColor(0.45, 0.75, 1.0, alpha)
                love.graphics.printf("Expected File:", cardX + 14, cardY + 88, cardW - 28, "center")

                love.graphics.setColor(0.85, 0.9, 0.98, alpha)
                love.graphics.printf(tostring(spriteSrc or "data/characters/*.png"), cardX + 14, cardY + 106, cardW - 28, "center")

                -- Hint text
                love.graphics.setColor(0.5, 0.55, 0.65, alpha)
                love.graphics.printf("Add file to auto-load", cardX + 8, cardY + cardH - 24, cardW - 16, "center")
            end

            love.graphics.pop()
        end
    end
end

return CharacterManager
