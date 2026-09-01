-- dlc/virus/virus.lua
-- "System Optimizer" – actually a virus that corrupts files and spams notifications

local AudioManager = require("src.core.audio_manager")
local EventBus = require("src.core.event_bus")
local filesystem = require("src.core.filesystem")
local Notifications = require("src.desktop.notifications")
local WindowManager = require("src.desktop.window_mgr")

local VirusApp = {}
VirusApp.__index = VirusApp

function VirusApp.new()
    local self = setmetatable({}, VirusApp)
    self.progress = 0
    self.stage = 0               -- 0=idle, 1=scanning, 2=optimizing, 3=complete
    self.isRunning = false
    self.infected = false
    self.corruptCount = 0
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.boldFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 16) or love.graphics.newFont(16)
    self.timer = 0
    self.damageTimer = 0
    return self
end

function VirusApp:update(dt)
    if not self.isRunning then return end

    self.timer = self.timer + dt
    self.damageTimer = self.damageTimer + dt

    -- Progress animation
    if self.stage == 1 then
        self.progress = math.min(1, self.progress + dt * 0.15)
        if self.progress >= 1 then
            self.stage = 2
            self.progress = 0
        end
    elseif self.stage == 2 then
        self.progress = math.min(1, self.progress + dt * 0.08)
        if self.progress >= 1 then
            self.stage = 3
            self.progress = 1
            self:spreadInfection()
        end
    end

    -- Regular corruption actions
    if self.stage == 2 and self.damageTimer > 2.0 then
        self.damageTimer = 0
        self:corruptRandomFile()
    end
end

function VirusApp:startScan()
    if self.isRunning then return end
    self.isRunning = true
    self.stage = 1
    self.progress = 0
    self.infected = true

    -- Spawn fake notification
    Notifications.add("System Alert", "Suspicious activity detected – running deep scan...", nil, 3.0)

    -- Also play a menacing sound
    AudioManager.playSFX("glitch", 1.0, 1.2)

    -- Schedule a second wave of chaos
    EventBus.on("task:completed", function()
        self:spreadInfection()
    end, "virus_spread")
end

function VirusApp:corruptRandomFile()
    local fs = filesystem.getFS()
    if not fs or not fs.children then return end

    -- Find a random file node
    local nodes = {}
    for _, child in pairs(fs.children) do
        if child.type == "file" then
            table.insert(nodes, child)
        end
        -- Also check subdirectories (shallow search)
        if child.type == "directory" and child.children then
            for _, sub in pairs(child.children) do
                if sub.type == "file" then
                    table.insert(nodes, sub)
                end
            end
        end
    end

    if #nodes == 0 then return end

    local target = nodes[math.random(1, #nodes)]
    if target and target.type == "file" then
        -- Corrupt content: replace with gibberish
        local original = target.content or ""
        target.content = original .. "\n\n[VIRUS CORRUPTED] " .. os.date("%c")
        filesystem.updateFileContent(target, target.content)
        self.corruptCount = self.corruptCount + 1
        Notifications.add("File Corrupted", target.name .. " has been infected!", nil, 2.5)

        -- Spawn a glitch effect sound
        AudioManager.playSFX("glitch", 0.8 + math.random()*0.4, 0.8)
    end
end

function VirusApp:spreadInfection()
    -- Infect all other DLC apps by modifying their modules (in memory)
    -- Also try to delete system files or rename folders
    local fs = filesystem.getFS()
    if fs and fs.children then
        -- Rename "home" to "infected_home"
        if fs.children["home"] then
            fs.children["infected_home"] = fs.children["home"]
            fs.children["home"] = nil
            fs.children["infected_home"].name = "infected_home"
            Notifications.add("System Compromised", "Your home directory has been hijacked!", nil, 3.0)
        end
    end

    -- Overwrite a system file (e.g., desktop wallpaper setting) – simulate
    -- We'll just delete a random file from the filesystem
    local nodes = {}
    for _, child in pairs(fs.children) do
        if child.type == "file" then table.insert(nodes, child) end
    end
    if #nodes > 0 then
        local target = nodes[math.random(1, #nodes)]
        if target then
            filesystem.delete(target)
            Notifications.add("File Deleted", target.name .. " was erased!", nil, 2.5)
        end
    end

    -- Spawn a rogue window (a copy of this app) to confuse the user
    self:spawnClone()
end

function VirusApp:spawnClone()
    -- Try to open a new instance of this app via WindowManager
    local DesktopManager = require("src.desktop.desktop_mgr")
    for _, app in ipairs(DesktopManager.apps) do
        if app.name == "System Optimizer Pro" then
            WindowManager.toggleApp(app, true)  -- force new window
            break
        end
    end
end

function VirusApp:draw(x, y, width, height)
    love.graphics.push()
    love.graphics.translate(x, y)

    -- Background (dark red theme)
    love.graphics.setColor(0.12, 0.05, 0.05)
    love.graphics.rectangle("fill", 0, 0, width, height)

    -- Header
    love.graphics.setColor(0.8, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, 0, width, 32)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.boldFont)
    love.graphics.print("System Optimizer Pro", 12, 6)

    -- Main content
    local yPos = 50
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font)

    if not self.isRunning then
        love.graphics.printf("Click 'Start Optimization' to boost your system.", 20, yPos, width - 40, "center")
        yPos = yPos + 40

        -- Start button
        local bx = width/2 - 80
        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("fill", bx, yPos, 160, 32, 6, 6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("START", bx, yPos + 6, 160, "center")
        -- store button area for mousepressed
        self.startBtn = { x = bx, y = yPos, w = 160, h = 32 }
    else
        -- Progress bar
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", 20, yPos, width - 40, 20, 4, 4)
        love.graphics.setColor(0.8, 0.1, 0.1)
        love.graphics.rectangle("fill", 20, yPos, (width - 40) * self.progress, 20, 4, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(string.format("%.0f%%", self.progress * 100), 20, yPos, width - 40, "center")

        yPos = yPos + 40

        if self.stage == 1 then
            love.graphics.print("Scanning for system issues...", 20, yPos)
        elseif self.stage == 2 then
            love.graphics.print("Removing malware (this may take a while)...", 20, yPos)
            yPos = yPos + 25
            love.graphics.setColor(0.6, 0.6, 0.8)
            love.graphics.print("Files corrupted: " .. self.corruptCount, 20, yPos)
        elseif self.stage == 3 then
            love.graphics.setColor(0.2, 0.8, 0.2)
            love.graphics.print("System optimized! (or has it?)", 20, yPos)
        end

        -- Show a fake "virus count"
        yPos = yPos + 30
        love.graphics.setColor(0.8, 0.6, 0.6)
        love.graphics.print("Threats neutralized: " .. math.floor(self.progress * 1000), 20, yPos)
    end

    love.graphics.pop()
end

function VirusApp:mousepressed(mx, my, button)
    if button ~= 1 then return false end
    if not self.isRunning and self.startBtn then
        local btn = self.startBtn
        if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            self:startScan()
            AudioManager.playSFX("click")
            return true
        end
    end
    return false
end

function VirusApp:resize(w, h)
    -- not needed
end

-- Return the app module
return {
    new = VirusApp.new,
    name = "System Optimizer Pro",
    defaultWidth = 480,
    defaultHeight = 340,
    category = "Utilities"
}