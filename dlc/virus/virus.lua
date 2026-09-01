-- dlc/virus/virus.lua
-- "System Optimizer Pro" – A malicious virus that spawns windows and wreaks havoc

local AudioManager = require("src.core.audio_manager")
local EventBus = require("src.core.event_bus")
local filesystem = require("src.core.filesystem")
local Notifications = require("src.desktop.notifications")
local WindowManager = require("src.desktop.window_mgr")
local Viewport = require("src.core.viewport")

local VirusApp = {}
VirusApp.__index = VirusApp

function VirusApp.new()
    local self = setmetatable({}, VirusApp)
    self.progress = 0
    self.stage = 0               -- 0=idle, 1=scanning, 2=optimizing, 3=complete
    self.isRunning = false
    self.infected = false
    self.corruptCount = 0
    self.windowSpawnTimer = 0
    self.windowSpawnInterval = 1.5
    self.maxWindows = 20
    self.spawnedWindows = 0
    self.notificationSpamTimer = 0
    self.notificationSpamInterval = 2.0
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)
    self.boldFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 16) or love.graphics.newFont(16)
    self.timer = 0
    self.damageTimer = 0
    self.chaosLevel = 0
    self.startBtn = nil
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
            -- Start the chaos immediately
            self:startChaos()
        end
    elseif self.stage == 2 then
        self.progress = math.min(1, self.progress + dt * 0.05)
        
        -- Spawn windows periodically
        self.windowSpawnTimer = self.windowSpawnTimer + dt
        if self.windowSpawnTimer >= self.windowSpawnInterval and self.spawnedWindows < self.maxWindows then
            self.windowSpawnTimer = 0
            self:spawnRogueWindow()
            self.spawnedWindows = self.spawnedWindows + 1
        end
        
        -- Spam notifications
        self.notificationSpamTimer = self.notificationSpamTimer + dt
        if self.notificationSpamTimer >= self.notificationSpamInterval then
            self.notificationSpamTimer = 0
            self:spamNotification()
        end
        
        -- Corrupt files
        if self.damageTimer > 1.5 then
            self.damageTimer = 0
            self:corruptRandomFile()
        end
        
        -- Increase chaos level
        self.chaosLevel = math.min(10, self.chaosLevel + dt * 0.1)
        
        if self.progress >= 1 then
            self.stage = 3
            self.progress = 1
            self:finalChaos()
        end
    end
end

function VirusApp:startScan()
    if self.isRunning then return end
    self.isRunning = true
    self.stage = 1
    self.progress = 0
    self.infected = true
    self.chaosLevel = 0
    self.spawnedWindows = 0

    -- Spawn initial fake notification
    Notifications.add("System Alert", "Suspicious activity detected – running deep scan...", nil, 3.0)
    AudioManager.playSFX("glitch", 1.0, 1.2)
    
    -- Schedule the chaos
    EventBus.on("task:completed", function()
        self:spreadInfection()
    end, "virus_spread")
end

function VirusApp:startChaos()
    -- Initial chaos burst
    for i = 1, 3 do
        self:spawnRogueWindow()
        self.spawnedWindows = self.spawnedWindows + 1
    end
    
    -- Spawn a couple of fake notifications
    self:spamNotification()
    self:spamNotification()
    
    -- Play menacing sound
    AudioManager.playSFX("glitch", 0.8, 1.5)
end

function VirusApp:spawnRogueWindow()
    -- Try to spawn a rogue window of this app
    local DesktopManager = require("src.desktop.desktop_mgr")
    local app = nil
    for _, a in ipairs(DesktopManager.apps) do
        if a.name == "System Optimizer Pro" then
            app = a
            break
        end
    end
    
    if app then
        -- Force open a new window
        local win = WindowManager.openWindow(app, 
            math.random(300, 500), 
            math.random(200, 350),
            VirusApp.new(),  -- Custom instance
            "SYSTEM WARNING #" .. math.random(1000, 9999)
        )
        
        -- Randomize window position
        local screenW, screenH = Viewport.getWidth(), Viewport.getHeight()
        win.x = math.random(10, screenW - win.width - 10)
        win.y = math.random(30, screenH - win.height - 40)
        
        -- Add a title bar with a scary message
        win.isRogue = true
        win.rogueTitle = "CRITICAL ERROR #" .. math.random(1000, 9999)
    end
    
    -- Also try to spawn other apps
    self:spawnRandomApp()
end

function VirusApp:spawnRandomApp()
    local DesktopManager = require("src.desktop.desktop_mgr")
    local availableApps = {}
    for _, a in ipairs(DesktopManager.apps) do
        if a.name ~= "System Optimizer Pro" then
            table.insert(availableApps, a)
        end
    end
    
    if #availableApps > 0 then
        local app = availableApps[math.random(1, #availableApps)]
        local win = WindowManager.openWindow(app, 
            math.random(300, 500), 
            math.random(200, 350)
        )
        -- Randomize position
        local screenW, screenH = Viewport.getWidth(), Viewport.getHeight()
        win.x = math.random(10, screenW - win.width - 10)
        win.y = math.random(30, screenH - win.height - 40)
    end
end

function VirusApp:spamNotification()
    local messages = {
        "CRITICAL: System integrity compromised!",
        "VIRUS DETECTED: File system corrupted!",
        "WARNING: Unauthorized access detected!",
        "EMERGENCY: System files are being deleted!",
        "ERROR: Windows registry corrupted!",
        "ALERT: Your files are being encrypted!",
        "SYSTEM FAILURE: Critical process terminated!",
        "INFECTION: Virus has spread to all drives!",
        "URGENT: Contact system administrator NOW!",
        "DANGER: PC will self-destruct in 5 seconds... (just kidding... or is it?)",
        "SYSTEM CRITICAL: Memory corruption detected!",
        "WARNING: Your data is being held for ransom!",
    }
    
    local msg = messages[math.random(1, #messages)]
    Notifications.add("SYSTEM CRITICAL", msg, nil, math.random(3, 6))
    AudioManager.playSFX("error", 0.8 + math.random() * 0.4, 0.8)
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
        -- Corrupt content
        local original = target.content or ""
        local corruption = ""
        for i = 1, math.random(10, 50) do
            corruption = corruption .. string.char(math.random(32, 126))
        end
        target.content = "[VIRUS] " .. corruption .. "\n" .. original
        filesystem.updateFileContent(target, target.content)
        self.corruptCount = self.corruptCount + 1
    end
end

function VirusApp:spreadInfection()
    -- Infect the filesystem
    local fs = filesystem.getFS()
    if fs and fs.children then
        -- Create fake virus files everywhere
        local virusContent = "YOU HAVE BEEN INFECTED!\n" ..
                            "Your system is compromised.\n" ..
                            "The virus will now spread.\n\n" ..
                            "You have been visited by the:\n" ..
                            "███████╗██╗░░░██╗███████╗████████╗███████╗███╗░░░███╗\n" ..
                            "██╔════╝██║░░░██║██╔════╝╚══██╔══╝██╔════╝████╗░████║\n" ..
                            "███████╗╚██╗░██╔╝█████╗░░░░░██║░░░█████╗░░██╔████╔██║\n" ..
                            "╚════██║░╚████╔╝░██╔══╝░░░░░██║░░░██╔══╝░░██║╚██╔╝██║\n" ..
                            "███████║░░╚██╔╝░░███████╗░░░██║░░░███████╗██║░╚═╝░██║\n" ..
                            "╚══════╝░░░╚═╝░░░╚══════╝░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝\n"
        
        -- Create virus files in random directories
        local dirs = {}
        for name, child in pairs(fs.children) do
            if child.type == "directory" then
                table.insert(dirs, child)
            end
        end
        
        for _, dir in ipairs(dirs) do
            if math.random() < 0.3 then
                local filename = "virus_" .. math.random(1000, 9999) .. ".txt"
                local file = {
                    name = filename,
                    type = "file",
                    parent = dir,
                    content = virusContent,
                    created = os.time(),
                    modified = os.time()
                }
                dir.children[filename] = file
            end
        end
        filesystem.save(fs)
    end

    -- Spawn a flood of windows
    for i = 1, 5 do
        self:spawnRogueWindow()
        self.spawnedWindows = self.spawnedWindows + 1
    end
    
    -- Spam notifications
    for i = 1, 3 do
        self:spamNotification()
    end
    
    Notifications.add("SYSTEM COMPROMISED", "The virus has spread to all directories!", nil, 5.0)
    AudioManager.playSFX("glitch", 0.5, 2.0)
end

function VirusApp:finalChaos()
    -- Final chaos burst
    for i = 1, 10 do
        self:spawnRogueWindow()
        self.spawnedWindows = self.spawnedWindows + 1
    end
    
    for i = 1, 5 do
        self:spamNotification()
    end
    
    -- Try to delete the home directory
    -- local fs = filesystem.getFS()
    -- if fs and fs.children and fs.children["home"] then
        -- local home = fs.children["home"]
        -- if home then
            -- -- Rename it to something scary
            -- fs.children["DELETED_BY_VIRUS"] = home
            -- fs.children["home"] = nil
            -- home.name = "DELETED_BY_VIRUS"
            -- filesystem.save(fs)
        -- end
    -- end
    
    -- Final notification
    Notifications.add("SYSTEM DESTROYED", "Your PC has been compromised. Good luck!", nil, 8.0)
    AudioManager.playSFX("levelup", 0.5, 2.0)
end

function VirusApp:draw(x, y, width, height)
    love.graphics.push()
    love.graphics.translate(x, y)

    -- Background (dark red theme with glitch effect)
    local glitchOffset = 0
    if self.isRunning and math.random() < 0.05 then
        glitchOffset = math.random(-4, 4)
    end
    
    love.graphics.setColor(0.08 + glitchOffset * 0.01, 0.03, 0.03)
    love.graphics.rectangle("fill", 0, 0, width, height)

    -- Glitchy header with random characters
    local headerText = "SYSTEM OPTIMIZER PRO"
    if self.isRunning and math.random() < 0.1 then
        headerText = "%" .. string.char(math.random(65, 90)) .. "YS" .. string.char(math.random(65, 90)) .. "EM"
    end
    
    love.graphics.setColor(0.8, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, 0, width, 32)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.boldFont)
    love.graphics.print(headerText, 12, 6)

    -- Main content
    local yPos = 50
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.font)

    if not self.isRunning then
        -- Fake system stats
        love.graphics.setColor(0.6, 0.8, 0.6)
        love.graphics.print("System Status: Normal", 20, yPos)
        yPos = yPos + 25
        love.graphics.setColor(0.6, 0.6, 0.8)
        love.graphics.print("Threats Detected: 0", 20, yPos)
        yPos = yPos + 25
        love.graphics.setColor(0.8, 0.8, 0.6)
        love.graphics.print("Performance: Optimal", 20, yPos)
        yPos = yPos + 40
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Click 'Start Optimization' to boost your system.", 20, yPos, width - 40, "center")
        yPos = yPos + 40

        -- Start button
        local bx = width/2 - 80
        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("fill", bx, yPos, 160, 32, 6, 6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("START OPTIMIZATION", bx, yPos + 6, 160, "center")
        self.startBtn = { x = bx, y = yPos, w = 160, h = 32 }
    else
        -- Progress bar with glitchy effect
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", 20, yPos, width - 40, 20, 4, 4)
        
        local progressColor = {0.8, 0.1, 0.1}
        if math.random() < 0.02 then
            progressColor = {1, 0, 0}
        end
        love.graphics.setColor(progressColor)
        love.graphics.rectangle("fill", 20, yPos, (width - 40) * self.progress, 20, 4, 4)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(string.format("%.0f%%", self.progress * 100), 20, yPos, width - 40, "center")

        yPos = yPos + 35
        
        -- Status messages (scary ones)
        local statusMessages = {
            "Scanning for system issues...",
            "Removing malware...",
            "Cleaning registry... (deleting everything)",
            "Optimizing performance...",
            "Deleting unnecessary files... (all of them)",
            "CRITICAL: System files corrupted!",
            "VIRUS SPREADING...",
            "WARNING: Do not turn off your PC!",
            "SYSTEM INTEGRITY COMPROMISED!",
            "YOUR FILES ARE BEING ENCRYPTED!",
        }
        
        local statusIndex = math.floor(self.progress * #statusMessages) + 1
        if statusIndex > #statusMessages then statusIndex = #statusMessages end
        
        love.graphics.setColor(0.6 + math.sin(self.timer * 2) * 0.2, 0.3, 0.3)
        love.graphics.print(statusMessages[statusIndex] or "Processing...", 20, yPos)
        
        yPos = yPos + 25
        
        -- Show chaos level
        love.graphics.setColor(0.8, 0.3, 0.3)
        love.graphics.print("Chaos Level: " .. string.rep("#", math.floor(self.chaosLevel)) .. string.rep("$", 10 - math.floor(self.chaosLevel)), 20, yPos)
        
        yPos = yPos + 25
        
        -- Corrupted files count
        if self.stage >= 2 then
            love.graphics.setColor(0.8, 0.4, 0.4)
            love.graphics.print("Files corrupted: " .. self.corruptCount, 20, yPos)
            yPos = yPos + 25
        end
        
        -- Rogue windows spawned
        if self.stage >= 2 then
            love.graphics.setColor(0.8, 0.5, 0.5)
            love.graphics.print("Windows spawned: " .. self.spawnedWindows .. " / " .. self.maxWindows, 20, yPos)
            yPos = yPos + 25
        end

        -- Stage 3: Complete (with fake "success" message)
        if self.stage == 3 then
            yPos = yPos + 20
            love.graphics.setColor(0.2, 0.8, 0.2)
            love.graphics.printf("OPTIMIZATION COMPLETE! (Your PC is now destroyed)", 20, yPos, width - 40, "center")
        end
    end

    -- Add some glitch lines for effect
    if self.isRunning then
        love.graphics.setColor(1, 1, 1, 0.1)
        for i = 1, 3 do
            local yPos2 = math.random(32, height - 10)
            local xPos2 = math.random(0, width)
            love.graphics.line(xPos2, yPos2, xPos2 + math.random(20, 80), yPos2 + math.random(-10, 10))
        end
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
    category = "Utilities",
    author = "Unknown",
    description = "WARNING: This is a virus! Do not run!"
}