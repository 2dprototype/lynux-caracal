-- objviewer.lua
local cpml = require("ss3d/cpml")
local ObjViewer = {}
ObjViewer.__index = ObjViewer

function ObjViewer.new(__filepath, fileNode)
    local self = setmetatable({}, ObjViewer)
    self.fileNode = fileNode
    self.engine = nil
    self.scene = nil
    self.models = {}
    self.timer = 0
    self.paused = false
    self.error = nil
    self.dragging = false
    self.lastX, self.lastY = 0, 0
    
    self.zoom = 5
    self.rotation = {x = 0, y = 0}
    self.autoRotate = true
    
    -- Try to load the OBJ file
    local success, err = pcall(function()
        self.engine = require("ss3d")
        self.scene = self.engine.newScene(800, 600)

        -- Try to load from virtual filesystem content first
        local modelData
        if fileNode and fileNode.content then
            local lines = {}
            for line in fileNode.content:gmatch("([^\n]*)\n?") do
                table.insert(lines, line)
            end
            modelData = self.engine.loadObjFromLines(lines)
        else
            local path = "data/files/" .. __filepath
            modelData = self.engine.loadObj(path)
        end

        local texture = love.graphics.newImage("assets/texture.png")

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
    if self.paused or not self.scene or self.error then return end
    
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
    love.graphics.setColor(0.05, 0.05, 0.07)
    love.graphics.rectangle("fill", x, y, width, height)

    if self.error then
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf(self.error, x, y + height/2 - 10, width, "center")
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
    -- The engine renders Y-up, so we flip Y and center
    love.graphics.draw(self.scene.threeCanvas, x + width/2, y + height/2, 0, 1, -1, width/2, height/2)
    
    -- Overlay UI
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", x, y, width, 30)
    love.graphics.setColor(0.8, 0.8, 0.8)
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