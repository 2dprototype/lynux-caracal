-- dlc/music_player/init.lua
local folderPath = ...
local chunk = love.filesystem.load(folderPath .. "/music_player.lua")
if chunk then
    return chunk()
end
return nil
