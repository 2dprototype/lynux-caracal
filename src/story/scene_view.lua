-- src/story/scene_view.lua
local SceneView = {
    currentScene = "bedroom_night",
    particles = {},
    glowTimer = 0
}

function SceneView.init()
    SceneView.particles = {}
    -- Ambient floating dust particles
    for i = 1, 30 do
        table.insert(SceneView.particles, {
            x = math.random() * 800,
            y = math.random() * 600,
            radius = math.random(1, 2),
            speed = math.random(6, 18),
            alpha = math.random() * 0.4 + 0.1,
            phase = math.random() * math.pi * 2
        })
    end
end

function SceneView.setScene(name)
    SceneView.currentScene = name or "bedroom_night"
end

function SceneView.update(dt)
    SceneView.glowTimer = SceneView.glowTimer + dt
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    for _, p in ipairs(SceneView.particles) do
        p.y = p.y - p.speed * dt
        p.x = p.x + math.sin(SceneView.glowTimer + p.phase) * 6 * dt
        if p.y < 0 then
            p.y = h + 10
            p.x = math.random() * w
        end
    end
end

function SceneView.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    if SceneView.currentScene == "bedroom_night" then
        -- Deep navy night gradient
        for y = 0, h do
            local ratio = y / h
            local r = 0.04 + ratio * 0.06
            local g = 0.05 + ratio * 0.08
            local b = 0.12 + ratio * 0.14
            love.graphics.setColor(r, g, b)
            love.graphics.line(0, y, w, y)
        end

        -- Room Window (Moonlight glow on the left)
        love.graphics.setColor(0.2, 0.4, 0.6, 0.15)
        love.graphics.polygon("fill", 40, 20, 180, 20, 260, h, 0, h)
        
        -- Window frame
        love.graphics.setColor(0.15, 0.25, 0.4, 0.35)
        love.graphics.rectangle("line", 40, 20, 140, 180)
        love.graphics.line(110, 20, 110, 200)
        love.graphics.line(40, 110, 180, 110)

        -- Desk silhouette & Computer Monitor glow (Center/Right)
        local monitorPulse = 0.85 + 0.15 * math.sin(SceneView.glowTimer * 2)
        love.graphics.setColor(0.1, 0.6, 0.8, 0.12 * monitorPulse)
        love.graphics.circle("fill", w * 0.65, h * 0.5, 240)

        -- Computer monitor silhouette
        love.graphics.setColor(0.08, 0.1, 0.15)
        love.graphics.rectangle("fill", w * 0.55, h * 0.32, 140, 95, 4, 4)
        love.graphics.setColor(0.03, 0.4, 0.5, 0.6 * monitorPulse)
        love.graphics.rectangle("fill", w * 0.55 + 6, h * 0.32 + 6, 128, 83)
        -- Monitor stand
        love.graphics.setColor(0.06, 0.08, 0.12)
        love.graphics.rectangle("fill", w * 0.55 + 55, h * 0.32 + 95, 30, 25)
        love.graphics.rectangle("fill", w * 0.55 + 40, h * 0.32 + 120, 60, 8)

        -- Desk surface
        love.graphics.setColor(0.05, 0.06, 0.09)
        love.graphics.rectangle("fill", 0, h * 0.6, w, h * 0.4)
        love.graphics.setColor(0.12, 0.2, 0.3, 0.4)
        love.graphics.line(0, h * 0.6, w, h * 0.6)

    elseif SceneView.currentScene == "server_room" then
        -- Dark cybernetic server room
        for y = 0, h do
            local ratio = y / h
            love.graphics.setColor(0.02, 0.05, 0.08 + ratio * 0.06)
            love.graphics.line(0, y, w, y)
        end
        -- Server racks with blinking LEDs
        for i = 1, 6 do
            local rackX = 40 + (i - 1) * 110
            love.graphics.setColor(0.06, 0.08, 0.12)
            love.graphics.rectangle("fill", rackX, 40, 80, h - 80)
            -- LEDs
            for row = 1, 10 do
                local ledY = 60 + row * 24
                local ledOn = ((i + row + math.floor(SceneView.glowTimer * 4)) % 3) == 0
                if ledOn then
                    love.graphics.setColor(0.1, 0.9, 0.4, 0.8)
                else
                    love.graphics.setColor(0.05, 0.2, 0.1, 0.4)
                end
                love.graphics.circle("fill", rackX + 15, ledY, 3)
            end
        end

    else
        -- Minimal dark room
        love.graphics.setColor(0.07, 0.09, 0.12)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end

    -- Draw ambient floating particles
    for _, p in ipairs(SceneView.particles) do
        love.graphics.setColor(0.4, 0.7, 0.9, p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.radius)
    end

    -- Soft atmospheric vignette
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("line", 0, 0, w, h)
end

return SceneView
