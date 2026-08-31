-- src/story/character_mgr.lua
-- Character Profiles and Colors (Clean standard material colors, zero emojis)

local CharacterManager = {
    characters = {
        ["Protagonist"] = {
            name = "Protagonist",
            color = {0.29, 0.56, 0.89}, -- Standard Blue
            portrait = nil,
            title = "Me"
        },
        ["Ghost"] = {
            name = "Ghost",
            color = {0.89, 0.35, 0.35}, -- Crimson Red
            portrait = nil,
            title = "Unknown"
        },
        ["Alice"] = {
            name = "Alice",
            color = {0.65, 0.45, 0.8}, -- Lavender
            portrait = nil,
            title = "Colleague"
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
