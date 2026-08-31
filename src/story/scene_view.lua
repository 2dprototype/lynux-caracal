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

    elseif SceneView.currentScene == "clubroom_sunset" or SceneView.currentScene == "clubroom_day" then
        local isSunset = SceneView.currentScene == "clubroom_sunset"
        
        -- Wall background (Warm cream/amber for sunset, crisp warm beige for day)
        if isSunset then
            love.graphics.setColor(0.24, 0.16, 0.14) -- Deep sunset interior shadow
            love.graphics.rectangle("fill", 0, 0, w, h)
            -- Gradient sunset glow
            love.graphics.setColor(0.95, 0.52, 0.28, 0.35)
            love.graphics.rectangle("fill", 0, 0, w, h * 0.7)
        else
            love.graphics.setColor(0.88, 0.86, 0.82) -- Daylight classroom wall
            love.graphics.rectangle("fill", 0, 0, w, h)
            love.graphics.setColor(0.98, 0.98, 0.95, 0.4)
            love.graphics.rectangle("fill", 0, 0, w, h * 0.6)
        end

        -- Tall Clubroom Windows (Left/Center background)
        local winY = 20
        local winH = h * 0.52
        for i = 1, 3 do
            local winX = 35 + (i - 1) * 110
            local winW = 95
            
            -- Outside Sky
            if isSunset then
                love.graphics.setColor(0.95, 0.45, 0.22) -- Bright Orange Sunset Sky
                love.graphics.rectangle("fill", winX, winY, winW, winH)
                -- Sunset pink/gold gradient
                love.graphics.setColor(1.0, 0.78, 0.35, 0.7)
                love.graphics.rectangle("fill", winX, winY + winH * 0.4, winW, winH * 0.6)
            else
                love.graphics.setColor(0.45, 0.72, 0.95) -- Clear Blue Sky
                love.graphics.rectangle("fill", winX, winY, winW, winH)
                love.graphics.setColor(1, 1, 1, 0.6)
                love.graphics.circle("fill", winX + 50, winY + 40, 20)
                love.graphics.circle("fill", winX + 70, winY + 45, 16)
            end

            -- Window Frame & Mullions
            love.graphics.setColor(isSunset and {0.28, 0.2, 0.18} or {0.75, 0.75, 0.78})
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", winX, winY, winW, winH)
            love.graphics.line(winX + winW/2, winY, winX + winW/2, winY + winH)
            love.graphics.line(winX, winY + winH * 0.6, winX + winW, winY + winH * 0.6)
        end

        -- Bulletin Board / Corkboard (Right wall)
        local boardX = w - 190
        local boardY = 30
        local boardW = 160
        local boardH = 110
        love.graphics.setColor(0.55, 0.38, 0.24) -- Wood frame
        love.graphics.rectangle("fill", boardX, boardY, boardW, boardH, 3, 3)
        love.graphics.setColor(0.78, 0.62, 0.42) -- Cork
        love.graphics.rectangle("fill", boardX + 4, boardY + 4, boardW - 8, boardH - 8, 2, 2)

        -- Pinned Notes, Newspaper Clippings & Cat Photo
        love.graphics.setColor(0.95, 0.95, 0.92) -- Newspaper proof
        love.graphics.rectangle("fill", boardX + 12, boardY + 14, 50, 70)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", boardX + 16, boardY + 18, 42, 6) -- Headline mockup
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.line(boardX + 16, boardY + 30, boardX + 56, boardY + 30)
        love.graphics.line(boardX + 16, boardY + 36, boardX + 56, boardY + 36)
        love.graphics.line(boardX + 16, boardY + 42, boardX + 56, boardY + 42)

        -- Kawaii Cat Cafe flyer pinned with red pin
        love.graphics.setColor(1.0, 0.88, 0.92) -- Pink Cat Cafe Flyer
        love.graphics.rectangle("fill", boardX + 72, boardY + 18, 48, 60)
        love.graphics.setColor(0.92, 0.45, 0.55)
        love.graphics.circle("fill", boardX + 96, boardY + 38, 12) -- Cat silhouette head
        love.graphics.polygon("fill", boardX + 86, boardY + 30, boardX + 90, boardY + 22, boardX + 94, boardY + 30) -- Ears
        love.graphics.polygon("fill", boardX + 98, boardY + 30, boardX + 102, boardY + 22, boardX + 106, boardY + 30)
        -- Red pin
        love.graphics.setColor(0.9, 0.2, 0.2)
        love.graphics.circle("fill", boardX + 96, boardY + 16, 3)

        -- Floor (Polished wooden classroom parquet)
        local floorY = h * 0.58
        love.graphics.setColor(isSunset and {0.42, 0.24, 0.16} or {0.58, 0.44, 0.32})
        love.graphics.rectangle("fill", 0, floorY, w, h - floorY)

        -- Large Wooden Editorial Conference Table
        local tableY = h * 0.64
        love.graphics.setColor(isSunset and {0.32, 0.18, 0.12} or {0.48, 0.34, 0.24})
        love.graphics.rectangle("fill", 40, tableY, w - 80, h - tableY)
        love.graphics.setColor(isSunset and {0.48, 0.28, 0.18} or {0.62, 0.46, 0.34})
        love.graphics.line(40, tableY, w - 40, tableY)

        -- Stacks of Newspapers, Red Pens, and Notebooks on Table
        love.graphics.setColor(0.92, 0.92, 0.9) -- Newspaper stack
        love.graphics.rectangle("fill", 70, tableY + 12, 100, 18, 2, 2)
        love.graphics.rectangle("fill", 72, tableY + 8, 96, 4, 1, 1)

        -- Hoshida's Open Laptop (Right side of table)
        love.graphics.setColor(0.18, 0.2, 0.22)
        love.graphics.rectangle("fill", w - 180, tableY + 5, 80, 50, 2, 2)
        love.graphics.setColor(0.12, 0.6, 0.3) -- Terminal green screen
        love.graphics.rectangle("fill", w - 176, tableY + 9, 72, 42)

    elseif SceneView.currentScene == "commute_morning" then
        -- Morning Commute Street with Blue Sky & Morning Sunlight
        love.graphics.setColor(0.55, 0.78, 0.96) -- Morning clear blue sky
        love.graphics.rectangle("fill", 0, 0, w, h)

        -- Distant Morning Clouds & City Skyline
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.circle("fill", 80, 50, 25)
        love.graphics.circle("fill", 110, 55, 20)
        love.graphics.circle("fill", w - 120, 60, 30)

        -- Distant School Roofs & Trees (Ginkgo trees with yellow-gold autumn leaves)
        local groundY = h * 0.6
        love.graphics.setColor(0.92, 0.75, 0.28) -- Golden yellow ginkgo canopy
        love.graphics.circle("fill", 140, groundY - 20, 45)
        love.graphics.circle("fill", 180, groundY - 30, 40)
        love.graphics.circle("fill", w - 100, groundY - 25, 50)

        -- Suburban Road & Sidewalk
        love.graphics.setColor(0.52, 0.54, 0.58) -- Asphalt road
        love.graphics.rectangle("fill", 0, groundY, w, h - groundY)
        love.graphics.setColor(0.78, 0.78, 0.8) -- Concrete curb
        love.graphics.rectangle("fill", 0, groundY - 12, w, 12)

        -- Utility Pole & Wires (Classic anime commute aesthetic)
        love.graphics.setColor(0.35, 0.36, 0.38)
        love.graphics.rectangle("fill", 50, 10, 8, groundY - 10)
        love.graphics.rectangle("fill", 35, 30, 38, 4)
        love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
        love.graphics.line(0, 35, w, 45)
        love.graphics.line(0, 40, w, 52)

    elseif SceneView.currentScene == "hallway_day" then
        -- High School Corridor
        love.graphics.setColor(0.9, 0.88, 0.84) -- Cream walls
        love.graphics.rectangle("fill", 0, 0, w, h)

        -- Large windows along left side
        local winY = 30
        local winH = h * 0.5
        for i = 1, 3 do
            local winX = 30 + (i - 1) * 120
            love.graphics.setColor(0.55, 0.8, 0.98) -- Sky through window
            love.graphics.rectangle("fill", winX, winY, 100, winH)
            love.graphics.setColor(0.8, 0.8, 0.85)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", winX, winY, 100, winH)
            love.graphics.line(winX + 50, winY, winX + 50, winY + winH)
        end

        -- Classroom Wooden Sliding Doors on right
        love.graphics.setColor(0.75, 0.58, 0.42)
        love.graphics.rectangle("fill", w - 160, 40, 120, h * 0.55, 2, 2)
        love.graphics.setColor(0.55, 0.38, 0.24)
        love.graphics.rectangle("line", w - 160, 40, 120, h * 0.55, 2, 2)
        -- Door window glass
        love.graphics.setColor(0.85, 0.92, 0.98, 0.8)
        love.graphics.rectangle("fill", w - 145, 60, 90, 60, 2, 2)

        -- Polished Linoleum Floor
        local floorY = h * 0.6
        love.graphics.setColor(0.78, 0.68, 0.54)
        love.graphics.rectangle("fill", 0, floorY, w, h - floorY)

    elseif SceneView.currentScene == "cat_cafe" then
        -- Warm Cozy Meow Latte Cat Cafe
        love.graphics.setColor(0.96, 0.92, 0.86) -- Warm peach/cream interior
        love.graphics.rectangle("fill", 0, 0, w, h)

        -- Large Cafe Bay Window overlooking sunlit garden
        local winX = 40
        local winY = 20
        local winW = 180
        local winH = h * 0.52
        love.graphics.setColor(0.65, 0.88, 0.95)
        love.graphics.rectangle("fill", winX, winY, winW, winH, 4, 4)
        love.graphics.setColor(0.85, 0.72, 0.55)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", winX, winY, winW, winH, 4, 4)

        -- Cat Tree / Scratching Post in corner
        love.graphics.setColor(0.82, 0.72, 0.58) -- Sisal rope post
        love.graphics.rectangle("fill", winX + winW + 30, 40, 16, h * 0.5)
        -- Platforms
        love.graphics.setColor(0.94, 0.78, 0.65)
        love.graphics.rectangle("fill", winX + winW + 10, 70, 56, 10, 4, 4)
        love.graphics.rectangle("fill", winX + winW + 15, 120, 50, 10, 4, 4)

        -- Cat Silhouette resting on upper perch
        love.graphics.setColor(0.25, 0.25, 0.28) -- Black cat Luna
        love.graphics.circle("fill", winX + winW + 38, 62, 7)
        love.graphics.ellipse("fill", winX + winW + 46, 65, 10, 6)

        -- Cafe Wooden Table & Soft Cushion Seating
        local floorY = h * 0.58
        love.graphics.setColor(0.74, 0.62, 0.48) -- Natural oak floor
        love.graphics.rectangle("fill", 0, floorY, w, h - floorY)

        local tableY = h * 0.65
        love.graphics.setColor(0.58, 0.42, 0.3) -- Round cafe table
        love.graphics.rectangle("fill", w - 240, tableY, 200, h - tableY, 6, 6)
        
        -- Strawberry Parfait & Milk Tea cups on table
        love.graphics.setColor(0.95, 0.45, 0.55) -- Parfait glass
        love.graphics.rectangle("fill", w - 180, tableY - 24, 16, 24, 2, 2)
        love.graphics.setColor(1, 1, 1) -- Whipped cream & cat paw marshmallow
        love.graphics.circle("fill", w - 172, tableY - 26, 8)
        love.graphics.setColor(0.92, 0.45, 0.55)
        love.graphics.circle("fill", w - 172, tableY - 26, 3)

    elseif SceneView.currentScene == "server_room" then
        love.graphics.setColor(0.08, 0.09, 0.12)
        love.graphics.rectangle("fill", 0, 0, w, h)
        for i = 1, 5 do
            local rackX = 40 + (i - 1) * 130
            love.graphics.setColor(0.14, 0.15, 0.18)
            love.graphics.rectangle("fill", rackX, 40, 90, h - 80, 2, 2)
            love.graphics.setColor(0.22, 0.24, 0.28)
            love.graphics.rectangle("line", rackX, 40, 90, h - 80, 2, 2)
            -- Blinking LED lights
            love.graphics.setColor(0.2, 0.8, 0.4)
            love.graphics.circle("fill", rackX + 15, 60, 2)
            love.graphics.setColor(0.9, 0.3, 0.3)
            love.graphics.circle("fill", rackX + 25, 60, 2)
        end

    else
        love.graphics.setColor(0.09, 0.1, 0.13)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end
end

return SceneView
