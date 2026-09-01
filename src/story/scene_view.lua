-- src/story/scene_view.lua
-- Background Asset Loader, Scene Management & Dark Blue Fallback

local SceneView = {
    currentScene = "clubroom_sunset",
    imageCache = {},
    fontBold = nil,
    fontSmall = nil
}

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

function SceneView.init()
    SceneView.currentScene = "clubroom_sunset"
    SceneView.imageCache = {}
    SceneView.fontBold = loadCustomFont("font/IBMPlexSans-Bold.ttf", 13)
    SceneView.fontSmall = loadCustomFont("font/Nunito-Regular.ttf", 11)
end

function SceneView.setScene(name)
    SceneView.currentScene = name or "clubroom_sunset"
end

function SceneView.getBackground(sceneName)
    sceneName = sceneName or SceneView.currentScene or "clubroom_sunset"
    local rawName = string.lower(string.gsub(sceneName, "[%s%-]+", "_"))
    local defaultExpectedPath = "data/backgrounds/" .. rawName .. ".png"

    -- Check cache
    if SceneView.imageCache[sceneName] ~= nil then
        local cached = SceneView.imageCache[sceneName]
        if cached then
            return cached.img, cached.path
        else
            return nil, defaultExpectedPath
        end
    end

    -- Candidate paths to search for this scene
    local candidatePaths = {}
    table.insert(candidatePaths, "data/backgrounds/" .. sceneName .. ".png")
    table.insert(candidatePaths, "data/backgrounds/" .. rawName .. ".png")
    table.insert(candidatePaths, "data/backgrounds/" .. sceneName .. ".jpg")
    table.insert(candidatePaths, "data/backgrounds/" .. rawName .. ".jpg")

    -- Aliases for existing clubroom background
    if sceneName == "clubroom_sunset" or sceneName == "clubroom_day" or sceneName == "newspaper_club" then
        table.insert(candidatePaths, "data/backgrounds/newspaper_club.png")
        table.insert(candidatePaths, "data/backgrounds/newspaper_club.jpg")
    end

    for _, path in ipairs(candidatePaths) do
        if SceneView.imageCache[path] then
            local cached = SceneView.imageCache[path]
            SceneView.imageCache[sceneName] = cached
            return cached.img, cached.path
        end
        local ok, img = pcall(love.graphics.newImage, path)
        if ok and img then
            local record = { img = img, path = path }
            SceneView.imageCache[path] = record
            SceneView.imageCache[sceneName] = record
            return img, path
        end
    end

    -- Mark as missing in cache
    SceneView.imageCache[sceneName] = false
    return nil, defaultExpectedPath
end

function SceneView.update(dt)
end

function SceneView.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local img, expectedPath = SceneView.getBackground(SceneView.currentScene)

    if img then
        -- 1. Draw Loaded Background Image (Scaled to fill screen smoothly)
        local scaleX = w / img:getWidth()
        local scaleY = h / img:getHeight()
        local scale = math.max(scaleX, scaleY)
        local drawW = img:getWidth() * scale
        local drawH = img:getHeight() * scale
        local drawX = math.floor((w - drawW) / 2)
        local drawY = math.floor((h - drawH) / 2)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, drawX, drawY, 0, scale, scale)

        -- 2. Scene-specific atmospheric color grading
        if SceneView.currentScene == "clubroom_sunset" then
            -- Warm golden sunset glow overlay
            love.graphics.setColor(0.95, 0.45, 0.18, 0.22)
            love.graphics.rectangle("fill", 0, 0, w, h)
        elseif SceneView.currentScene == "bedroom_night" then
            -- Deep nocturnal blue mood overlay
            love.graphics.setColor(0.04, 0.08, 0.22, 0.28)
            love.graphics.rectangle("fill", 0, 0, w, h)
        end

    else
        -- 3. Fallback: Dark Blue Background (User specification)
        love.graphics.setColor(0.05, 0.08, 0.16)
        love.graphics.rectangle("fill", 0, 0, w, h)

        -- Subtle deep navy gradient
        love.graphics.setColor(0.08, 0.12, 0.24, 0.6)
        love.graphics.rectangle("fill", 0, 0, w, h * 0.45)

        -- 4. Developer Missing Background Placeholder Card
        local cardW = math.min(460, w - 48)
        local cardH = 120
        local cardX = math.floor((w - cardW) / 2)
        local cardY = math.floor(h * 0.22)

        -- Card background
        love.graphics.setColor(0.08, 0.12, 0.22, 0.92)
        love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 6, 6)

        -- Border
        love.graphics.setColor(0.18, 0.52, 0.92, 0.85)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 6, 6)

        -- Header Bar
        love.graphics.setColor(0.18, 0.52, 0.92, 0.22)
        love.graphics.rectangle("fill", cardX + 1, cardY + 1, cardW - 2, 26, 5, 5)

        love.graphics.setFont(SceneView.fontBold or love.graphics.getFont())
        love.graphics.setColor(1.0, 0.82, 0.35)
        love.graphics.printf("[Missing Scene Background]", cardX, cardY + 5, cardW, "center")

        -- Details
        love.graphics.setFont(SceneView.fontSmall or love.graphics.getFont())
        love.graphics.setColor(0.85, 0.90, 0.98)
        love.graphics.printf("Scene: " .. tostring(SceneView.currentScene), cardX + 16, cardY + 34, cardW - 32, "center")

        love.graphics.setColor(0.40, 0.72, 1.0)
        love.graphics.printf("Expected File: " .. tostring(expectedPath), cardX + 16, cardY + 54, cardW - 32, "center")

        love.graphics.setColor(0.55, 0.62, 0.74)
        love.graphics.printf("Add file in data/backgrounds/ to automatically load.", cardX + 16, cardY + 82, cardW - 32, "center")
    end
end

return SceneView
