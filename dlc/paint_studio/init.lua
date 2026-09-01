-- dlc/paint_studio/init.lua
local folderPath = ...
local chunk = love.filesystem.load(folderPath .. "/paint.lua")
if chunk then
    return chunk()
end
return nil
