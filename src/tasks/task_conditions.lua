-- src/tasks/task_conditions.lua
local filesystemModule = require("filesystem")

local TaskConditions = {}

-- Checks if a file exists at a given path in the virtual filesystem (e.g. "home/cipher.txt" or "/home/cipher.txt")
function TaskConditions.fileExists(targetPath)
    return function()
        local fs = filesystemModule.getFS()
        if not fs then return false end

        -- Normalize path
        targetPath = targetPath:gsub("^/", "")
        local parts = {}
        for part in targetPath:gmatch("[^/]+") do
            table.insert(parts, part)
        end

        local current = fs
        for _, part in ipairs(parts) do
            if not current.children or not current.children[part] then
                return false
            end
            current = current.children[part]
        end
        return current.type == "file"
    end
end

-- Checks if a file exists AND contains expected text / pattern
function TaskConditions.fileContentContains(targetPath, searchStr, caseSensitive)
    if caseSensitive == nil then caseSensitive = false end
    return function()
        local fs = filesystemModule.getFS()
        if not fs then return false end

        targetPath = targetPath:gsub("^/", "")
        local parts = {}
        for part in targetPath:gmatch("[^/]+") do
            table.insert(parts, part)
        end

        local current = fs
        for _, part in ipairs(parts) do
            if not current.children or not current.children[part] then
                return false
            end
            current = current.children[part]
        end

        if current.type == "file" and current.content then
            local content = current.content
            if not caseSensitive then
                content = content:lower()
                searchStr = searchStr:lower()
            end
            return content:find(searchStr, 1, true) ~= nil
        end
        return false
    end
end

-- Checks if a custom flag is set in PlayerStats
function TaskConditions.flagIsSet(flagName, expectedValue)
    if expectedValue == nil then expectedValue = true end
    local PlayerStats = require("src.core.player_stats")
    return function()
        return PlayerStats.getFlag(flagName) == expectedValue
    end
end

return TaskConditions
