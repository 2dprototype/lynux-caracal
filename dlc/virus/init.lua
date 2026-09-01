-- dlc/virus/init.lua
local folderPath = ...
local chunk = love.filesystem.load(folderPath .. "/virus.lua")
if chunk then
    return chunk()
end
return nil