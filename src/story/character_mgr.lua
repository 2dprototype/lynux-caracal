-- src/story/character_mgr.lua
local CharacterManager = {
    characters = {
        ["Protagonist"] = {
            name = "Protagonist",
            color = {0.3, 0.75, 0.95},
            portrait = nil,
            title = "Me"
        },
        ["Ghost"] = {
            name = "Ghost",
            color = {0.9, 0.3, 0.35},
            portrait = nil,
            title = "Unknown Entity"
        },
        ["Alice"] = {
            name = "Alice",
            color = {0.95, 0.45, 0.6},
            portrait = nil,
            title = "Colleague"
        },
        ["System"] = {
            name = "System",
            color = {0.2, 0.85, 0.5},
            portrait = nil,
            title = "Lynux Kernel"
        }
    },
    activeCharacters = {} -- { [position] = { characterId = "...", expression = "...", alpha = 1.0 } }
}

function CharacterManager.init()
    CharacterManager.activeCharacters = {}
end

function CharacterManager.get(id)
    return CharacterManager.characters[id] or {
        name = id or "Unknown",
        color = {0.8, 0.8, 0.8},
        title = ""
    }
end

function CharacterManager.show(characterId, position, expression)
    position = position or "center" -- "left", "center", "right"
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
        
        -- Silhouette / avatar placeholder rendering
        love.graphics.push()
        love.graphics.setColor(0, 0, 0, 0.4 * charData.alpha)
        love.graphics.circle("fill", coords.x, coords.y - 40, 36)
        love.graphics.rectangle("fill", coords.x - 30, coords.y, 60, 80, 8, 8)

        -- Character Accent Aura
        love.graphics.setColor(charInfo.color[1], charInfo.color[2], charInfo.color[3], 0.8 * charData.alpha)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", coords.x, coords.y - 40, 36)
        love.graphics.rectangle("line", coords.x - 30, coords.y, 60, 80, 8, 8)
        love.graphics.pop()
    end
end

return CharacterManager
