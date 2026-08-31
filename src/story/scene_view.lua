-- src/story/scene_view.lua
-- Realistic ~2009/2010 Bedroom & Scene Visuals (Clean, Lag-Free)

local SceneView = {
    currentScene = "bedroom_night"
}

function SceneView.init()
    SceneView.currentScene = "bedroom_night"
end

function SceneView.setScene(name)
    SceneView.currentScene = name or "bedroom_night"
end

function SceneView.update(dt)
end

function SceneView.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    if SceneView.currentScene == "bedroom_night" then
        -- Realistic Dark Night Room Atmosphere
        love.graphics.setColor(0.07, 0.08, 0.11)
        love.graphics.rectangle("fill", 0, 0, w, h)

        -- Bedroom Window (Left) with soft night twilight
        love.graphics.setColor(0.12, 0.15, 0.22)
        love.graphics.rectangle("fill", 36, 24, 120, 150, 2, 2)
        
        -- Window frame (Neutral off-white / grey)
        love.graphics.setColor(0.18, 0.2, 0.26)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 36, 24, 120, 150, 2, 2)
        love.graphics.line(96, 24, 96, 174)
        love.graphics.line(36, 99, 156, 99)

        -- Soft moon in sky
        love.graphics.setColor(0.85, 0.88, 0.95, 0.75)
        love.graphics.circle("fill", 70, 56, 12)

        -- Computer Desk Surface (Neutral Dark Charcoal/Wood)
        local deskY = h * 0.62
        love.graphics.setColor(0.1, 0.11, 0.14)
        love.graphics.rectangle("fill", 0, deskY, w, h - deskY)
        love.graphics.setColor(0.16, 0.18, 0.24)
        love.graphics.line(0, deskY, w, deskY)

        -- 2009-style LCD Computer Monitor (Center/Right)
        local monX = w * 0.52
        local monY = h * 0.32
        local monW = 160
        local monH = 105

        -- Ambient screen glow on wall
        love.graphics.setColor(0.15, 0.3, 0.5, 0.1)
        love.graphics.circle("fill", monX + monW / 2, monY + monH / 2, 130)

        -- Monitor Bezel (Matte black/dark grey plastic)
        love.graphics.setColor(0.12, 0.13, 0.16)
        love.graphics.rectangle("fill", monX, monY, monW, monH, 3, 3)
        love.graphics.setColor(0.2, 0.22, 0.28)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", monX, monY, monW, monH, 3, 3)

        -- LCD Screen Content (Realistic Windows desktop wallpaper & taskbar glow)
        love.graphics.setColor(0.0, 0.35, 0.65) -- Classic Windows Blue Wallpaper
        love.graphics.rectangle("fill", monX + 6, monY + 6, monW - 12, monH - 12)

        -- Mini taskbar on the monitor
        love.graphics.setColor(0.08, 0.08, 0.1)
        love.graphics.rectangle("fill", monX + 6, monY + monH - 14, monW - 12, 8)
        love.graphics.setColor(0.0, 0.47, 0.83)
        love.graphics.rectangle("fill", monX + 7, monY + monH - 13, 10, 6) -- Mini Start button

        -- Monitor Stand & Base
        love.graphics.setColor(0.14, 0.15, 0.18)
        love.graphics.rectangle("fill", monX + monW / 2 - 12, monY + monH, 24, 24)
        love.graphics.rectangle("fill", monX + monW / 2 - 32, monY + monH + 20, 64, 6, 2, 2)

    elseif SceneView.currentScene == "server_room" then
        love.graphics.setColor(0.08, 0.09, 0.12)
        love.graphics.rectangle("fill", 0, 0, w, h)
        for i = 1, 5 do
            local rackX = 40 + (i - 1) * 130
            love.graphics.setColor(0.14, 0.15, 0.18)
            love.graphics.rectangle("fill", rackX, 40, 90, h - 80, 2, 2)
            love.graphics.setColor(0.22, 0.24, 0.28)
            love.graphics.rectangle("line", rackX, 40, 90, h - 80, 2, 2)
        end

    else
        love.graphics.setColor(0.09, 0.1, 0.13)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end
end

return SceneView
