-- src/story/character_mgr.lua
local CharacterManager = {
    characters = {
        ["Protagonist"] = {
            name = "Protagonist",
            color = {1.0, 0.82, 0.25}, -- Sunny Yellow
            portrait = nil,
            title = "Me"
        },
        ["Ghost"] = {
            name = "Ghost",
            color = {1.0, 0.44, 0.65}, -- Strawberry Pink
            portrait = nil,
            title = "Unknown Entity"
        },
        ["Alice"] = {
            name = "Alice",
            color = {1.0, 0.55, 0.75}, -- Sakura Pink
            portrait = nil,
            title = "Colleague"
        },
        ["System"] = {
            name = "System",
            color = {0.2, 0.88, 0.55}, -- Pastel Mint
            portrait = nil,
            title = "Lynux Kernel"
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
        color = {1.0, 0.82, 0.25},
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
        love.graphics.setColor(0, 0, 0, 0.3 * charData.alpha)
        love.graphics.circle("fill", coords.x, coords.y - 40, 36)
        love.graphics.rectangle("fill", coords.x - 30, coords.y, 60, 80, 8, 8)

        -- Kawaii Accent Aura (Sunny Yellow / Pastel Pink)
        love.graphics.setColor(charInfo.color[1], charInfo.color[2], charInfo.color[3], 0.85 * charData.alpha)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", coords.x, coords.y - 40, 36)
        love.graphics.rectangle("line", coords.x - 30, coords.y, 60, 80, 8, 8)
        love.graphics.pop()
    end
end

return CharacterManager
