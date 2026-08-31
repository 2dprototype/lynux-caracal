-- src/story/character_mgr.lua
-- Character Profiles and Colors (Clean standard material colors, zero emojis)

local CharacterManager = {
    characters = {
        ["Aki"] = {
            name = "Aki",
            color = {0.29, 0.56, 0.89}, -- Soft Sky Blue
            portrait = nil,
            title = "Newspaper Club Reporter"
        },
        ["Protagonist"] = {
            name = "Aki",
            color = {0.29, 0.56, 0.89}, -- Soft Sky Blue
            portrait = nil,
            title = "Me"
        },
        ["Suzumia"] = {
            name = "Suzumia",
            color = {0.94, 0.48, 0.58}, -- Sakura Rose Pink
            portrait = nil,
            title = "Vice President"
        },
        ["Nagahashi"] = {
            name = "Nagahashi",
            color = {0.95, 0.65, 0.22}, -- Bold Amber
            portrait = nil,
            title = "Club President"
        },
        ["Hoshida"] = {
            name = "Hoshida",
            color = {0.32, 0.72, 0.48}, -- Soft Forest Green
            portrait = nil,
            title = "Club Member"
        },
        ["Hoshida (Anon)"] = {
            name = "Hoshida [Root]",
            color = {0.72, 0.38, 0.88}, -- Cyber Violet
            portrait = nil,
            title = "SysAdmin / Hacker"
        },
        ["Hiko"] = {
            name = "Hiko",
            color = {0.22, 0.78, 0.85}, -- Bright Turquoise / Cyan
            portrait = nil,
            title = "Sister (1st Year)"
        },
        ["Student Council"] = {
            name = "Council Rep",
            color = {0.62, 0.65, 0.72}, -- Slate Silver
            portrait = nil,
            title = "Student Council"
        },
        ["Ghost"] = {
            name = "Ghost [Unknown]",
            color = {0.89, 0.35, 0.35}, -- Crimson Red
            portrait = nil,
            title = "Intruder"
        },
        ["System"] = {
            name = "System",
            color = {0.18, 0.75, 0.45}, -- Clean Green
            portrait = nil,
            title = "OS Kernel"
        }
    },
    activeCharacters = {}
}

function CharacterManager.init()
    CharacterManager.activeCharacters = {}
end

function CharacterManager.get(id)
    return CharacterManager.characters[id] or {
        name = id or "Unknown",
        color = {0.29, 0.56, 0.89},
        title = ""
    }
end

function CharacterManager.show(characterId, position, expression)
    position = position or "center"
    CharacterManager.activeCharacters[position] = {
        characterId = characterId,
        expression = expression or "normal",
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
        left = { x = w * 0.2, y = h * 0.45 },
        center = { x = w * 0.5, y = h * 0.45 },
        right = { x = w * 0.8, y = h * 0.45 }
    }

    for posKey, charData in pairs(CharacterManager.activeCharacters) do
        local coords = posCoords[posKey] or posCoords.center
        local charInfo = CharacterManager.get(charData.characterId)
        
        love.graphics.push()
        love.graphics.setColor(0, 0, 0, 0.35 * charData.alpha)
        love.graphics.circle("fill", coords.x, coords.y - 40, 36)
        love.graphics.rectangle("fill", coords.x - 30, coords.y, 60, 80, 4, 4)

        love.graphics.setColor(charInfo.color[1], charInfo.color[2], charInfo.color[3], 0.9 * charData.alpha)
        love.graphics.setLineWidth(1.5)
        love.graphics.circle("line", coords.x, coords.y - 40, 36)
        love.graphics.rectangle("line", coords.x - 30, coords.y, 60, 80, 4, 4)
        love.graphics.pop()
    end
end

return CharacterManager
