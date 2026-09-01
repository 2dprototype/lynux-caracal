-- objviewer.lua
local cpml = require("ss3d/cpml")
local ObjViewer = {}
ObjViewer.__index = ObjViewer

function ObjViewer.new(__filepath, fileNode)
    if type(__filepath) == "table" and not fileNode then
        fileNode = __filepath
        __filepath = fileNode.name
    end

    local self = setmetatable({}, ObjViewer)
    self.fileNode = fileNode or { name = tostring(__filepath or "model.obj") }
    self.engine = nil
    self.scene = nil
    self.models = {}
    self.timer = 0
    self.paused = false
    self.error = nil
    self.missingSource = nil
    self.dragging = false
    self.lastX, self.lastY = 0, 0
    
    self.zoom = 5
    self.rotation = {x = 0, y = 0}
    self.autoRotate = true
    
    -- Determine candidate paths from node.content, node.name, __filepath
    local contentSrc = (self.fileNode and self.fileNode.content and self.fileNode.content ~= "") and self.fileNode.content or nil
    local fileName = (self.fileNode and self.fileNode.name) or tostring(__filepath or "model.obj")

    local success, err = pcall(function()
        self.engine = require("ss3d")
        self.scene = self.engine.newScene(800, 600)

        local modelData = nil

        -- 1. Try contentSrc if it's a file path
        if contentSrc and (string.find(contentSrc, "^data/") or string.find(contentSrc, "%.obj$")) then
            if love.filesystem.getInfo(contentSrc) then
                modelData = self.engine.loadObj(contentSrc)
            end
        end

        -- 2. Try candidate paths
        if not modelData then
            local candidates = {
                "data/models/" .. fileName,
                "data/files/" .. fileName,
                "data/" .. fileName,
                __filepath and ("data/models/" .. __filepath) or nil,
                __filepath and ("data/files/" .. __filepath) or nil,
                __filepath
            }
            for _, path in ipairs(candidates) do
                if path and love.filesystem.getInfo(path) then
                    modelData = self.engine.loadObj(path)
                    break
                end
            end
        end

        -- 3. Try raw OBJ line content
        if not modelData and contentSrc and string.find(contentSrc, "v%s+") then
            local lines = {}
            for line in contentSrc:gmatch("([^\n]*)\n?") do
                table.insert(lines, line)
            end
            if #lines > 0 then
                modelData = self.engine.loadObjFromLines(lines)
            end
        end

        if not modelData then
            self.missingSource = contentSrc or ("data/models/" .. fileName)
            return
        end

        local texture = nil
        if love.filesystem.getInfo("assets/texture.png") then
            texture = love.graphics.newImage("assets/texture.png")
        end

        local model = self.engine.newModel(modelData, texture)
        self.scene:addModel(model)
        table.insert(self.models, model)

        self.scene.camera.pos.z = self.zoom
    end)
    
    if not success then
        self.error = "Failed to load model: " .. tostring(err)
        print(err)
    end
    
    return self
end

function ObjViewer:update(dt)
    if self.paused or not self.scene or self.error or not self.models[1] then return end
    
    if self.autoRotate and not self.dragging then
        self.timer = self.timer + dt/2
        self.rotation.y = self.timer
    end
    
    if self.models[1] then
        self.models[1]:setTransform(
            {0, 0, 0}, 
            {self.rotation.y, cpml.vec3.unit_y, self.rotation.x, cpml.vec3.unit_x}
        )
    end
    
    self.scene.camera.pos.z = self.zoom
end

function ObjViewer:draw(x, y, width, height)
    self.windowX, self.windowY, self.windowWidth, self.windowHeight = x, y, width, height
    
    -- Background
    love.graphics.setColor(0.06, 0.08, 0.14)
    love.graphics.rectangle("fill", x, y, width, height)

    if self.error then
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.printf(self.error, x, y + height/2 - 10, width, "center")
        return
    end

    if self.missingSource or not self.models[1] then
        -- Clean Material placeholder for missing 3D model
        local cardW = math.min(320, width - 40)
        local cardH = math.min(180, height - 60)
        local cardX = x + (width - cardW) / 2
        local cardY = y + (height - cardH) / 2

        love.graphics.setColor(0.08, 0.12, 0.20, 0.95)
        love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 6, 6)
        love.graphics.setColor(0.2, 0.5, 0.85, 0.8)
        love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 6, 6)

        -- Title
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self.fileNode and self.fileNode.name or "3D Model", cardX, cardY + 14, cardW, "center")

        -- Tag
        love.graphics.setColor(0.95, 0.45, 0.45)
        love.graphics.printf("[Missing 3D Model File]", cardX, cardY + 38, cardW, "center")

        -- Expected Path box
        love.graphics.setColor(0.04, 0.06, 0.11)
        love.graphics.rectangle("fill", cardX + 12, cardY + 64, cardW - 24, 48, 4, 4)
        love.graphics.setColor(0.45, 0.75, 1.0)
        love.graphics.printf("Expected Content Source:", cardX + 16, cardY + 70, cardW - 32, "center")
        love.graphics.setColor(0.85, 0.9, 0.98)
        love.graphics.printf(tostring(self.missingSource or "data/models/*.obj"), cardX + 16, cardY + 88, cardW - 32, "center")

        love.graphics.setColor(0.5, 0.55, 0.65)
        love.graphics.printf("Place .obj file in data/models/ to view", cardX, cardY + cardH - 24, cardW, "center")
        return
    end

    if not self.scene then return end

    -- Sync scene size
    if self.scene.renderWidth ~= width or self.scene.renderHeight ~= height then
        self.scene:resize(width, height)
    end
    
    -- Render to canvas (don't draw yet)
    self.scene:render(false)
    
    -- Draw the 3D canvas centered in the window
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.scene.threeCanvas, x + width/2, y + height/2, 0, 1, -1, width/2, height/2)
    
    -- Overlay UI
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", x, y, width, 30)
    love.graphics.setColor(0.85, 0.88, 0.92)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("3D Viewer: " .. (self.fileNode and self.fileNode.name or "Unknown"), x + 10, y + 8)
    
    -- Controls guide
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", x, y + height - 30, width, 30)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Drag to Rotate • Scroll to Zoom • Space to Pause Rotation • R to Reset", x, y + height - 22, width, "center")
end

function ObjViewer:mousepressed(mx, my, button)
    if button == 1 then
        self.dragging = true
        self.lastX, self.lastY = mx, my
        self.autoRotate = false
    end
end

function ObjViewer:mousemoved(mx, my, dx, dy)
    if self.dragging then
        self.rotation.y = self.rotation.y + dx * 0.01
        self.rotation.x = self.rotation.x + dy * 0.01
    end
end

function ObjViewer:mousereleased(mx, my, button)
    if button == 1 then
        self.dragging = false
    end
end

function ObjViewer:wheelmoved(x, y)
    self.zoom = math.max(1, math.min(50, self.zoom - y * 0.5))
end

function ObjViewer:keypressed(key)
    if key == "space" then
        self.autoRotate = not self.autoRotate
    elseif key == "r" then
        self.rotation = {x = 0, y = 0}
        self.zoom = 5
        self.autoRotate = true
        self.timer = 0
    end
end

return ObjViewer