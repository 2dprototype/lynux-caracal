-- dlc/minesweeper/init.lua
local folderPath = ...
local chunk = love.filesystem.load(folderPath .. "/minesweeper.lua")
if chunk then
    return chunk()
end
return nil
