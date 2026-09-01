-- dlc/calculator/init.lua
local folderPath = ...
local chunk = love.filesystem.load(folderPath .. "/calculator.lua")
if chunk then
    return chunk()
end
return nil
