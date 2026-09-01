-- dlc/retro_snake/init.lua
local folderPath = ...
local chunk = love.filesystem.load(folderPath .. "/snake.lua")
if chunk then
    return chunk()
end
return nil
