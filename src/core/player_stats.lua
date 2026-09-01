-- src/core/player_stats.lua
local EventBus = require("src.core.event_bus")

local PlayerStats = {
    level = 1,
    xp = 0,
    xpForNextLevel = 100,
    title = "Protagonist",
    flags = {},
    levelTitles = {
        [1] = "Alpha",
        [2] = "Beta",
        [3] = "Gamma",
        [4] = "Delta",
        [5] = "Epsilon"
    }
}

function PlayerStats.init()
    PlayerStats.level = 1
    PlayerStats.xp = 0
    PlayerStats.xpForNextLevel = 100
    PlayerStats.title = PlayerStats.levelTitles[1]
    PlayerStats.flags = {}

    EventBus.on("email:read", function(email)
        if email then
            PlayerStats.setFlag("email_read:" .. tostring(email.id), true)
            if email.sender then
                PlayerStats.setFlag("email_read_sender:" .. email.sender:lower(), true)
            end
        end
    end, "stats_email_read")

    EventBus.on("email:attachment_downloaded", function(data)
        if data and data.filename then
            PlayerStats.setFlag("downloaded:" .. data.filename:lower(), true)
        end
    end, "stats_attachment_downloaded")

    EventBus.on("chat:sent", function(data)
        if data and data.user then
            PlayerStats.setFlag("chat_sent:" .. data.user:lower(), true)
        end
    end, "stats_chat_sent")

    EventBus.on("file:saved", function(data)
        if data and data.node and data.node.name then
            PlayerStats.setFlag("file_saved:" .. data.node.name:lower(), true)
        end
    end, "stats_file_saved")

    EventBus.on("browser:navigate", function(data)
        if data and data.url then
            PlayerStats.setFlag("browser_visited:" .. data.url:lower(), true)
        end
    end, "stats_browser_nav")
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
