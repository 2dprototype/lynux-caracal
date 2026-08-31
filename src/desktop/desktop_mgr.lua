-- src/desktop/desktop_mgr.lua
-- Windows 10 Style Desktop Environment with Multi-Process Management & Standard Fonts
-- Light theme, modern minimalist professional color scheme

local json = require("lib/json")
local filesystemModule = require("src.core.filesystem")
local AudioManager = require("src.core.audio_manager")
local EventBus = require("src.core.event_bus")
local Taskbar = require("src.desktop.taskbar")
local WindowManager = require("src.desktop.window_mgr")
local TaskHUD = require("src.desktop.task_hud")
local Notifications = require("src.desktop.notifications")

-- Load App Modules
local EmailApp = require("src.apps.email")
local BrowserApp = require("src.apps.browser")
local FilesApp = require("src.apps.files")
local TerminalApp = require("src.apps.terminal") 
local TextEditor = require("src.apps.texteditor")
local TessarectApp = require("src.apps.tessarect")
local ImageViewer = require("src.apps.imageviewer")
local ObjViewer = require("src.apps.objviewer")
local ChatApp = require("src.apps.chat")
local SettingsApp = require("src.apps.settings")

local DesktopManager = {
    apps = {},
    desktopHomeIcons = {},
    desktopHome = nil,
    startMenuOpen = false,
    startIcon = nil,
    folderIcon = nil,
    fileIcon = nil,
    shortcutIcon = nil,
    font = nil,
    boldFont = nil,
    smallFont = nil,
    taskbarIcons = {} -- store calculated positions
}

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

function DesktopManager.init()
    Taskbar.init()
    WindowManager.init()
    TaskHUD.init()
    Notifications.init()

    DesktopManager.font = loadCustomFont("font/Nunito-Regular.ttf", 14)
    DesktopManager.boldFont = loadCustomFont("font/IBMPlexSans-Bold.ttf", 15) or loadCustomFont("font/Nunito-Regular.ttf", 15)
    DesktopManager.smallFont = loadCustomFont("font/Nunito-Regular.ttf", 12)

    pcall(function()
        DesktopManager.folderIcon = love.graphics.newImage("assets/folder.png")
        DesktopManager.fileIcon = love.graphics.newImage("assets/file.png")
        DesktopManager.shortcutIcon = love.graphics.newImage("assets/shortcut.png")
        DesktopManager.startIcon = love.graphics.newImage("assets/layers.png")
    end)

    local sharedFS = filesystemModule.getFS()
    if not sharedFS.children["home"] then
        sharedFS.children["home"] = { 
            name = "home", 
            type = "directory", 
            parent = sharedFS, 
            children = {} 
        }
    end
    DesktopManager.desktopHome = sharedFS.children["home"]

    local function loadImg(path)
        local ok, img = pcall(love.graphics.newImage, path)
        return ok and img or nil
    end

    DesktopManager.apps = {
        { name = "TextEditor", module = TextEditor, icon = loadImg("assets/file.png") },
        { name = "Terminal", module = TerminalApp, icon = loadImg("assets/terminal.png") },
        { name = "Files", module = FilesApp, icon = loadImg("assets/files.png") },
        { name = "Chat", module = ChatApp, icon = loadImg("assets/chat.png") },
        { name = "Email", module = EmailApp, icon = loadImg("assets/email.png") },
        { name = "Browser", module = BrowserApp, icon = loadImg("assets/browser.png") },
        { name = "ImageViewer", module = ImageViewer, icon = loadImg("assets/image.png") },
        { name = "ObjViewer", module = ObjViewer, icon = loadImg("assets/cube.png") },
        { name = "Tessarect", module = TessarectApp, icon = loadImg("assets/box.png") },
        { name = "Settings", module = SettingsApp, icon = loadImg("assets/settings.png") },
    }

    _G.openFileDirectly = function(node)
        if not node then return end
        local ext = node.name:match("^.+(%..+)$") or ""
        ext = ext:lower()
        if ext == ".png" or ext == ".jpg" or ext == ".jpeg" then
            DesktopManager.openImageFile(node)
        elseif ext == ".obj" then
            DesktopManager.openObjFile(node)
        else
            DesktopManager.openTextFile(node)
        end
    end

    DesktopManager.updateDockLayout()
end

function DesktopManager.updateDockLayout()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local dockH = Taskbar.bottomBarHeight
    local dockY = screenH - dockH

    -- Calculate available space for app icons (between Start button and system tray)
    local startBtnWidth = 44
    local systemTrayWidth = 225 -- space for clock + level bar + margins
    local availableWidth = screenW - startBtnWidth - systemTrayWidth - 20
    
    -- Determine icon size based on available space
    local numApps = #DesktopManager.apps
    local minItemWidth = 40
    local maxItemWidth = 52
    local spacing = 4
    
    -- Calculate how many icons can fit with reasonable size
    local idealItemWidth = math.min(maxItemWidth, math.max(minItemWidth, (availableWidth - (numApps - 1) * spacing) / numApps))
    local itemW = math.floor(idealItemWidth)
    local itemH = math.floor(itemW * 0.8) -- slightly shorter than wide
    
    -- Start position after Start button
    local startX = startBtnWidth + 8
    
    -- Center the icons in the available space
    local totalWidth = numApps * itemW + (numApps - 1) * spacing
    if totalWidth < availableWidth then
        startX = startX + (availableWidth - totalWidth) / 2
    end
    
    -- Check if we need to reduce icon size to fit
    local maxIterations = 3
    while totalWidth > availableWidth and itemW > 28 and maxIterations > 0 do
        itemW = itemW - 2
        itemH = math.floor(itemW * 0.8)
        totalWidth = numApps * itemW + (numApps - 1) * spacing
        maxIterations = maxIterations - 1
    end
    
    -- If still too many, hide some icons (show scroll indicator later)
    local visibleApps = numApps
    if totalWidth > availableWidth then
        -- Calculate max visible
        local maxVisible = math.floor((availableWidth + spacing) / (minItemWidth + spacing))
        visibleApps = math.max(3, maxVisible)
    end

    -- Position each app icon
    local currentX = startX
    for i, app in ipairs(DesktopManager.apps) do
        if i <= visibleApps then
            app.x = math.floor(currentX)
            app.y = math.floor(dockY + (dockH - itemH) / 2)
            app.width = itemW
            app.height = itemH
            app.visible = true
            currentX = currentX + itemW + spacing
        else
            app.visible = false
        end
    end
    
    -- Store for later use
    DesktopManager.taskbarIcons = {
        startX = startX,
        itemW = itemW,
        itemH = itemH,
        spacing = spacing,
        visibleApps = visibleApps,
        totalApps = numApps
    }
end

function DesktopManager.openAppByName(appName, forceNew)
    for _, app in ipairs(DesktopManager.apps) do
        if app.name == appName then
            return WindowManager.toggleApp(app, forceNew)
        end
    end
end

-- Opens a text file in a dedicated process instance or focuses existing instance
function DesktopManager.openTextFile(node)
    local editorApp = nil
    for _, app in ipairs(DesktopManager.apps) do
        if app.name == "TextEditor" then
            editorApp = app
            break
        end
    end
    if not editorApp then return end

    -- Check if an open window is already viewing this exact file
    local existingWin = nil
    if node then
        for _, win in ipairs(WindowManager.openApps) do
            if win.app == editorApp and win.instance and win.instance.filename == node.name then
                existingWin = win
                break
            end
        end
    end

    if existingWin then
        existingWin.minimized = false
        WindowManager.setFocus(existingWin)
    else
        -- Launch a new process instance for this file!
        local newInstance = editorApp.module.new(node and node.name or "untitled.txt", node)
        if node and node.content then
            newInstance:loadContent(node.content)
        end
        WindowManager.openWindow(editorApp, 560, 350, newInstance, node and (node.name .. " - TextEditor") or "TextEditor")
    end
    AudioManager.playSFX("click")
end

function DesktopManager.openImageFile(node)
    local imgApp = nil
    for _, app in ipairs(DesktopManager.apps) do
        if app.name == "ImageViewer" then
            imgApp = app
            break
        end
    end
    if imgApp then
        local newInstance = imgApp.module.new()
        if newInstance.loadImage then
            newInstance:loadImage(node)
        end
        WindowManager.openWindow(imgApp, 540, 340, newInstance, node and (node.name .. " - ImageViewer") or "ImageViewer")
    end
end

function DesktopManager.openObjFile(node)
    local objApp = nil
    for _, app in ipairs(DesktopManager.apps) do
        if app.name == "ObjViewer" then
            objApp = app
            break
        end
    end
    if objApp then
        local newInstance = objApp.module.new()
        WindowManager.openWindow(objApp, 540, 340, newInstance, node and (node.name .. " - 3D Viewer") or "3D Viewer")
    end
end

function DesktopManager.drawWallpaper()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Clean white/light gray gradient (modern minimal)
    love.graphics.setColor(0.96, 0.97, 0.98)  -- very light gray
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    -- Subtle top accent line
    love.graphics.setColor(0.9, 0.92, 0.95)
    love.graphics.rectangle("fill", 0, 0, screenW, 2)
end

function DesktopManager.drawDesktopIcons()
    DesktopManager.desktopHomeIcons = {}
    local iconSize = 40
    local spacingX, spacingY = 84, 80
    local startX, startY = 275, 45
    local cols = 5
    local index = 0

    if DesktopManager.desktopHome and DesktopManager.desktopHome.children then
        for name, node in pairs(DesktopManager.desktopHome.children) do
            local col = index % cols
            local row = math.floor(index / cols)
            local x = startX + col * spacingX
            local y = startY + row * spacingY

            -- Icon with subtle shadow
            love.graphics.setColor(0, 0, 0, 0.08)
            love.graphics.rectangle("fill", x + 2, y + 2, iconSize, iconSize, 4)
            love.graphics.setColor(1, 1, 1, 0.95)
            love.graphics.rectangle("fill", x, y, iconSize, iconSize, 4)

            local icon = (node.type == "directory") and DesktopManager.folderIcon or DesktopManager.fileIcon
            if icon then
                love.graphics.setColor(1, 1, 1, 0.95)
                love.graphics.draw(icon, x, y, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
            else
                love.graphics.setColor(0.0, 0.47, 0.83)
                love.graphics.rectangle("fill", x, y, iconSize, iconSize, 4)
            end

            -- Label
            love.graphics.setFont(DesktopManager.smallFont or DesktopManager.font)
            love.graphics.setColor(0.12, 0.14, 0.18)
            love.graphics.printf(name, x - 16, y + iconSize + 4, iconSize + 32, "center")

            table.insert(DesktopManager.desktopHomeIcons, {
                x = x, y = y, width = iconSize, height = iconSize, node = node, name = name
            })
            index = index + 1
        end
    end
end

function DesktopManager.drawTaskbarApps()
    local screenH = love.graphics.getHeight()
    local dockH = Taskbar.bottomBarHeight
    local dockY = screenH - dockH

    love.graphics.push()

    for _, app in ipairs(DesktopManager.apps) do
        if not app.visible then break end -- Skip hidden icons
        
        local instances = WindowManager.getAppInstances(app)
        local isRunning = #instances > 0
        local isFocused = false

        for _, win in ipairs(instances) do
            if win == WindowManager.focusedWindow and not win.minimized then
                isFocused = true
                break
            end
        end

        -- Light theme taskbar button background
        if isFocused then
            love.graphics.setColor(0.85, 0.9, 0.95, 0.7)
            love.graphics.rectangle("fill", app.x, dockY + 2, app.width, dockH - 4, 2, 2)
        elseif isRunning then
            love.graphics.setColor(0.75, 0.8, 0.85, 0.5)
            love.graphics.rectangle("fill", app.x, dockY + 2, app.width, dockH - 4, 2, 2)
        end

        -- App Icon (proportional to button size)
        local iconSize = math.min(app.width - 8, app.height - 8, 24)
        if app.icon then
            love.graphics.setColor(1, 1, 1, isRunning and 1.0 or 0.7)
            local scale = iconSize / app.icon:getWidth()
            love.graphics.draw(app.icon, app.x + (app.width - iconSize) / 2, app.y + (app.height - iconSize) / 2, 0, scale, scale)
        else
            love.graphics.setColor(0.0, 0.47, 0.83)
            love.graphics.rectangle("fill", app.x + (app.width - 18) / 2, app.y + (app.height - 18) / 2, 18, 18, 2, 2)
        end

        -- Multi-process instance counter badge
        if #instances > 1 then
            love.graphics.setFont(DesktopManager.smallFont)
            love.graphics.setColor(0.0, 0.65, 1.0)
            love.graphics.print(tostring(#instances), app.x + app.width - 14, dockY + 4)
        end

        -- Active underline indicator
        if isRunning then
            if isFocused then
                love.graphics.setColor(0.0, 0.47, 0.83) -- Accent Blue
                love.graphics.rectangle("fill", app.x + 6, dockY + dockH - 3, app.width - 12, 2)
            else
                love.graphics.setColor(0.5, 0.55, 0.6)
                love.graphics.rectangle("fill", app.x + 10, dockY + dockH - 3, app.width - 20, 2)
            end
        end
    end
    
    -- Show "more apps" indicator if some are hidden
    if DesktopManager.taskbarIcons and DesktopManager.taskbarIcons.visibleApps < DesktopManager.taskbarIcons.totalApps then
        local lastApp = DesktopManager.apps[DesktopManager.taskbarIcons.visibleApps]
        if lastApp then
            local x = lastApp.x + lastApp.width + 4
            love.graphics.setFont(DesktopManager.smallFont)
            love.graphics.setColor(0.4, 0.42, 0.46)
            love.graphics.print("›", x, dockY + (dockH - 14) / 2)
        end
    end

    love.graphics.pop()
end

function DesktopManager.drawStartMenu()
    if not DesktopManager.startMenuOpen then return end

    local screenH = love.graphics.getHeight()
    local menuW, menuH = 240, 300
    local menuX, menuY = 0, screenH - Taskbar.bottomBarHeight - menuH

    love.graphics.push()

    -- Drop shadow
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.rectangle("fill", menuX + 4, menuY + 4, menuW, menuH)

    -- White background with subtle border
    love.graphics.setColor(1, 1, 1, 0.98)
    love.graphics.rectangle("fill", menuX, menuY, menuW, menuH)
    love.graphics.setColor(0.85, 0.88, 0.92)
    love.graphics.rectangle("line", menuX, menuY, menuW, menuH)

    -- Header
    love.graphics.setColor(0.1, 0.12, 0.16)
    love.graphics.setFont(DesktopManager.boldFont or DesktopManager.font)
    love.graphics.print("Applications", menuX + 18, menuY + 14)
    love.graphics.setColor(0.85, 0.88, 0.92)
    love.graphics.line(menuX + 14, menuY + 38, menuX + menuW - 14, menuY + 38)

    -- List apps
    local itemY = menuY + 46
    for _, app in ipairs(DesktopManager.apps) do
        if app.icon then
            love.graphics.setColor(0.2, 0.22, 0.26)
            love.graphics.draw(app.icon, menuX + 16, itemY, 0, 18 / app.icon:getWidth(), 18 / app.icon:getHeight())
        end
        love.graphics.setFont(DesktopManager.font)
        love.graphics.setColor(0.1, 0.12, 0.16)
        love.graphics.print(app.name, menuX + 42, itemY + 2)
        itemY = itemY + 26
    end

    love.graphics.pop()
end

function DesktopManager.update(dt)
    WindowManager.update(dt)
    TaskHUD.update(dt)
    Notifications.update(dt)
end

function DesktopManager.draw()
    DesktopManager.drawWallpaper()
    DesktopManager.drawDesktopIcons()
    TaskHUD.draw()
    WindowManager.draw()
    Taskbar.drawBottomBar()
    DesktopManager.drawTaskbarApps()
    DesktopManager.drawStartMenu()
    Notifications.draw()
end

function DesktopManager.mousepressed(x, y, button)
    if Notifications.mousepressed(x, y, button) then return end
    if Taskbar.mousepressed(x, y, button) then return end

    -- Start Menu handling
    if DesktopManager.startMenuOpen then
        local screenH = love.graphics.getHeight()
        local menuW, menuH = 240, 300
        local menuX, menuY = 0, screenH - Taskbar.bottomBarHeight - menuH
        if x >= menuX and x <= menuX + menuW and y >= menuY and y <= menuY + menuH then
            local itemY = menuY + 46
            for _, app in ipairs(DesktopManager.apps) do
                if y >= itemY and y <= itemY + 26 then
                    WindowManager.toggleApp(app, button == 2)
                    DesktopManager.startMenuOpen = false
                    return
                end
                itemY = itemY + 26
            end
            return
        else
            DesktopManager.startMenuOpen = false
        end
    end

    -- Bottom Taskbar Start Button & App Icons
    local screenH = love.graphics.getHeight()
    local dockH = Taskbar.bottomBarHeight
    local dockY = screenH - dockH

    if y >= dockY then
        -- Windows Start Button
        if x >= 0 and x <= 44 then
            DesktopManager.startMenuOpen = not DesktopManager.startMenuOpen
            AudioManager.playSFX("click")
            return
        end

        -- Taskbar App Launcher Icons (only visible ones)
        for _, app in ipairs(DesktopManager.apps) do
            if app.visible and x >= app.x and x <= app.x + app.width then
                WindowManager.toggleApp(app, button == 2)
                return
            end
        end
        return
    end

    -- Windows
    if WindowManager.mousepressed(x, y, button) then return end

    -- Task HUD
    if TaskHUD.mousepressed(x, y, button) then return end

    -- Desktop File/Folder Icons
    for _, iconInfo in ipairs(DesktopManager.desktopHomeIcons) do
        if x >= iconInfo.x and x <= iconInfo.x + iconInfo.width and y >= iconInfo.y and y <= iconInfo.y + iconInfo.height + 20 then
            if button == 1 then
                if iconInfo.node.type == "directory" then
                    local filesApp = DesktopManager.openAppByName("Files")
                    if filesApp and filesApp.instance then
                        filesApp.instance.cwd = iconInfo.node
                        filesApp.instance:updateFileList()
                    end
                else
                    _G.openFileDirectly(iconInfo.node)
                end
                AudioManager.playSFX("click")
                return
            end
        end
    end
end

function DesktopManager.mousemoved(x, y, dx, dy)
    Taskbar.mousemoved(x, y)
    WindowManager.mousemoved(x, y, dx, dy)
end

function DesktopManager.mousereleased(x, y, button)
    WindowManager.mousereleased(x, y, button)
    TaskHUD.mousereleased(x, y, button)
end

function DesktopManager.wheelmoved(x, y)
    WindowManager.wheelmoved(x, y)
end

function DesktopManager.textinput(text)
    WindowManager.textinput(text)
end

function DesktopManager.keypressed(key)
    WindowManager.keypressed(key)
end

function DesktopManager.resize(w, h)
    DesktopManager.updateDockLayout()
end

return DesktopManager