-- src/story/scene_view.lua
-- High-performance, lag-free retro scene renderer without heavy per-line loops or particle lag

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
    -- Lag-free: No heavy particle processing
end

function SceneView.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    if SceneView.currentScene == "bedroom_night" then
        -- Warm Retro Midnight Background (Clean solid fills, 0 lag)
        love.graphics.setColor(0.11, 0.1, 0.14) -- Warm dark espresso night
        love.graphics.rectangle("fill", 0, 0, w, h)

        -- Soft Warm Window Area (Moonlight on Left)
        love.graphics.setColor(0.2, 0.18, 0.28, 0.5)
        love.graphics.rectangle("fill", 30, 20, 130, 160, 4, 4)

        -- Window Frame (Retro Cream/Amber)
        love.graphics.setColor(0.95, 0.8, 0.35, 0.4)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 30, 20, 130, 160, 4, 4)
        love.graphics.line(95, 20, 95, 180)
        love.graphics.line(30, 100, 160, 100)

        -- Cute Retro Moon / Stars in window
        love.graphics.setColor(1.0, 0.88, 0.4, 0.85) -- Sunny yellow moon
        love.graphics.circle("fill", 65, 55, 16)
        love.graphics.setColor(0.2, 0.18, 0.28, 0.9)
        love.graphics.circle("fill", 72, 50, 14) -- Crescent cutout

        -- Computer Desk & Monitor Silhouette (Center/Right)
        -- Desk Surface (Warm Dark Wood / Slate)
        local deskY = h * 0.62
        love.graphics.setColor(0.16, 0.14, 0.18)
        love.graphics.rectangle("fill", 0, deskY, w, h - deskY)
        love.graphics.setColor(0.95, 0.8, 0.3, 0.3) -- Warm Retro Yellow rim highlight
        love.graphics.line(0, deskY, w, deskY)

        -- Monitor Ambient Glow (Soft Warm Yellow/Gold Phosphor)
        local monX = w * 0.54
        local monY = h * 0.32
        local monW = 150
        local monH = 100

        love.graphics.setColor(1.0, 0.85, 0.35, 0.12)
        love.graphics.circle("fill", monX + monW / 2, monY + monH / 2, 140)

        -- Monitor Frame (Retro Gaming CRT Style)
        love.graphics.setColor(0.22, 0.2, 0.26)
        love.graphics.rectangle("fill", monX, monY, monW, monH, 8, 8)
        love.graphics.setColor(0.95, 0.8, 0.35, 0.7) -- Retro Gold outline
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", monX, monY, monW, monH, 8, 8)

        -- Screen (Glowing Phosphor CRT with warm amber lines)
        love.graphics.setColor(0.14, 0.12, 0.16)
        love.graphics.rectangle("fill", monX + 8, monY + 8, monW - 16, monH - 16, 4, 4)
        love.graphics.setColor(1.0, 0.82, 0.25, 0.4)
        love.graphics.rectangle("fill", monX + 16, monY + 20, 60, 6, 2, 2)
        love.graphics.rectangle("fill", monX + 16, monY + 32, 90, 6, 2, 2)
        love.graphics.rectangle("fill", monX + 16, monY + 44, 45, 6, 2, 2)
        love.graphics.setColor(0.2, 0.88, 0.55, 0.8) -- Blinking green terminal cursor
        love.graphics.rectangle("fill", monX + 66, monY + 44, 6, 6)

        -- Monitor Stand
        love.graphics.setColor(0.18, 0.16, 0.22)
        love.graphics.rectangle("fill", monX + monW / 2 - 14, monY + monH, 28, 25)
        love.graphics.rectangle("fill", monX + monW / 2 - 35, monY + monH + 20, 70, 8, 3, 3)

    elseif SceneView.currentScene == "server_room" then
        -- Retro Server Room (Clean solid blocks)
        love.graphics.setColor(0.1, 0.09, 0.12)
        love.graphics.rectangle("fill", 0, 0, w, h)
        for i = 1, 5 do
            local rackX = 40 + (i - 1) * 130
            love.graphics.setColor(0.18, 0.16, 0.22)
            love.graphics.rectangle("fill", rackX, 40, 90, h - 80, 4, 4)
            love.graphics.setColor(0.95, 0.8, 0.35, 0.4)
            love.graphics.rectangle("line", rackX, 40, 90, h - 80, 4, 4)
            -- Retro colorful LEDs
            for row = 1, 8 do
                local ledY = 60 + row * 28
                love.graphics.setColor(1.0, 0.82, 0.25, 0.8)
                love.graphics.circle("fill", rackX + 20, ledY, 3)
                love.graphics.setColor(0.2, 0.88, 0.55, 0.8)
                love.graphics.circle("fill", rackX + 40, ledY, 3)
                love.graphics.setColor(1.0, 0.44, 0.65, 0.8)
                love.graphics.circle("fill", rackX + 60, ledY, 3)
            end
        end

    else
        love.graphics.setColor(0.12, 0.11, 0.15)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end
end

return SceneView
