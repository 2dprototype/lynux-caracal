-- src/core/player_stats.lua
local EventBus = require("src.core.event_bus")

local PlayerStats = {
    level = 1,
    xp = 0,
    xpForNextLevel = 100,
    title = "Novice Hacker",
    flags = {},
    levelTitles = {
        [1] = "Script Novice",
        [2] = "Code Initiator",
        [3] = "Cyber Analyst",
        [4] = "System Infiltrator",
        [5] = "Netrunner Elite"
    }
}

function PlayerStats.init()
    PlayerStats.level = 1
    PlayerStats.xp = 0
    PlayerStats.xpForNextLevel = 100
    PlayerStats.title = PlayerStats.levelTitles[1]
    PlayerStats.flags = {}
end

function PlayerStats.addXP(amount)
    PlayerStats.xp = PlayerStats.xp + amount
    local leveledUp = false
    while PlayerStats.xp >= PlayerStats.xpForNextLevel do
        PlayerStats.xp = PlayerStats.xp - PlayerStats.xpForNextLevel
        PlayerStats.level = PlayerStats.level + 1
        PlayerStats.xpForNextLevel = math.floor(PlayerStats.xpForNextLevel * 1.5)
        PlayerStats.title = PlayerStats.levelTitles[PlayerStats.level] or ("Master Level " .. PlayerStats.level)
        leveledUp = true
    end

    EventBus.emit("player:xp_gained", {
        amount = amount,
        totalXP = PlayerStats.xp,
        neededXP = PlayerStats.xpForNextLevel,
        level = PlayerStats.level,
        title = PlayerStats.title,
        leveledUp = leveledUp
    })

    if leveledUp then
        EventBus.emit("player:levelup", {
            level = PlayerStats.level,
            title = PlayerStats.title
        })
    end
end

function PlayerStats.setFlag(flag, value)
    if value == nil then value = true end
    PlayerStats.flags[flag] = value
    EventBus.emit("player:flag_changed", { flag = flag, value = value })
end

function PlayerStats.getFlag(flag, defaultValue)
    if PlayerStats.flags[flag] == nil then
        return defaultValue
    end
    return PlayerStats.flags[flag]
end

function PlayerStats.getLevelProgress()
    return PlayerStats.xp / PlayerStats.xpForNextLevel
end

return PlayerStats
