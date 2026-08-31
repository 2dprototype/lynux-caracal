-- src/desktop/desktop_mgr.lua
-- Windows 10 Style Desktop Environment with Start Menu and Taskbar integration

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
    hoveredApp = nil
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

    DesktopManager.font = loadCustomFont("font/x14y24pxHeadUpDaisy.ttf", 18)
    DesktopManager.boldFont = loadCustomFont("font/x14y24pxHeadUpDaisy.ttf", 20)
    DesktopManager.smallFont = loadCustomFont("font/x14y24pxHeadUpDaisy.ttf", 15)

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
        { name = "TextEditor", module = TextEditor, instance = nil, icon = loadImg("assets/file.png") },
        { name = "Terminal", module = TerminalApp, instance = nil, icon = loadImg("assets/terminal.png") },
        { name = "Files", module = FilesApp, instance = nil, icon = loadImg("assets/files.png") },
        { name = "Chat", module = ChatApp, instance = nil, icon = loadImg("assets/chat.png") },
        { name = "Email", module = EmailApp, instance = nil, icon = loadImg("assets/email.png") },
        { name = "Browser", module = BrowserApp, instance = nil, icon = loadImg("assets/browser.png") },
        { name = "ImageViewer", module = ImageViewer, instance = nil, icon = loadImg("assets/image.png") },
        { name = "ObjViewer", module = ObjViewer, instance = nil, icon = loadImg("assets/cube.png") },
        { name = "Tessarect", module = TessarectApp, instance = nil, icon = loadImg("assets/box.png") },
        { name = "Settings", module = SettingsApp, instance = nil, icon = loadImg("assets/settings.png") },
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
    local screenH = love.graphics.getHeight()
    local itemW = 42
    local itemH = 34
    local startX = 196 -- Offset past Search box
    local dockY = screenH - Taskbar.bottomBarHeight + (Taskbar.bottomBarHeight - itemH) / 2

    for _, app in ipairs(DesktopManager.apps) do
        app.x = startX
        app.y = dockY
        app.width = itemW
        app.height = itemH
        startX = startX + itemW + 4
    end
end

function DesktopManager.openAppByName(appName)
    for _, app in ipairs(DesktopManager.apps) do
        if app.name == appName then
            WindowManager.toggleApp(app)
            return app
        end
    end
end

function DesktopManager.openTextFile(node)
    local editorApp = nil
    for _, app in ipairs(DesktopManager.apps) do
        if app.name == "TextEditor" then
            editorApp = app
            break
        end
    end
    if not editorApp then return end

    local existingWin = nil
    for _, win in ipairs(WindowManager.openApps) do
        if win.app == editorApp then
            existingWin = win
            break
        end
    end

    if existingWin then
        existingWin.minimized = false
        WindowManager.setFocus(existingWin)
        if node then
            existingWin.instance.filename = node.name
            existingWin.instance.fileNode = node
            if node.content then
                existingWin.instance:loadContent(node.content)
            end
        end
    else
        editorApp.instance = editorApp.module.new(node and node.name or "untitled.txt", node)
        WindowManager.openWindow(editorApp)
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
        if not imgApp.instance then
            imgApp.instance = imgApp.module.new()
        end
        WindowManager.openWindow(imgApp)
        if imgApp.instance.loadImage then
            imgApp.instance:loadImage(node)
        end
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
        if not objApp.instance then
            objApp.instance = objApp.module.new()
        end
        WindowManager.openWindow(objApp)
    end
end

function DesktopManager.drawWallpaper()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Classic Serene Windows 10 Slate Blue Surface
    love.graphics.setColor(0.09, 0.12, 0.16)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Subtle Windows 10 Light Angle Accent
    love.graphics.setColor(0.0, 0.47, 0.83, 0.08)
    love.graphics.polygon("fill", screenW * 0.4, 0, screenW, 0, screenW, screenH * 0.7, screenW * 0.7, screenH)
end

function DesktopManager.drawDesktopIcons()
    DesktopManager.desktopHomeIcons = {}
    local iconSize = 36
    local spacingX, spacingY = 76, 74
    local startX, startY = 275, 45 -- Offset past Task HUD sticky note
    local cols = 5
    local index = 0

    if DesktopManager.desktopHome and DesktopManager.desktopHome.children then
        for name, node in pairs(DesktopManager.desktopHome.children) do
            local col = index % cols
            local row = math.floor(index / cols)
            local x = startX + col * spacingX
            local y = startY + row * spacingY

            local icon = (node.type == "directory") and DesktopManager.folderIcon or DesktopManager.fileIcon
            if icon then
                love.graphics.setColor(1, 1, 1, 0.95)
                love.graphics.draw(icon, x, y, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
            else
                love.graphics.setColor(0.0, 0.47, 0.83)
                love.graphics.rectangle("fill", x, y, iconSize, iconSize, 2, 2)
            end

            -- Label (Clean typography, no emojis)
            love.graphics.setFont(DesktopManager.smallFont or DesktopManager.font)
            love.graphics.setColor(0.96, 0.96, 0.98)
            love.graphics.printf(name, x - 16, y + iconSize + 3, iconSize + 32, "center")

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
        local isRunning = false
        local isFocused = false
        for _, win in ipairs(WindowManager.openApps) do
            if win.app == app then
                isRunning = true
                if win == WindowManager.focusedWindow and not win.minimized then
                    isFocused = true
                end
                break
            end
        end

        -- Windows 10 Taskbar Button Highlight
        if isFocused then
            love.graphics.setColor(0.24, 0.26, 0.32, 0.95)
            love.graphics.rectangle("fill", app.x, dockY + 2, app.width, dockH - 4, 2, 2)
        elseif isRunning then
            love.graphics.setColor(0.18, 0.19, 0.24, 0.8)
            love.graphics.rectangle("fill", app.x, dockY + 2, app.width, dockH - 4, 2, 2)
        end

        -- App Icon
        if app.icon then
            love.graphics.setColor(1, 1, 1, isRunning and 1.0 or 0.75)
            love.graphics.draw(app.icon, app.x + (app.width - 20) / 2, dockY + (dockH - 20) / 2, 0, 20 / app.icon:getWidth(), 20 / app.icon:getHeight())
        else
            love.graphics.setColor(0.0, 0.47, 0.83)
            love.graphics.rectangle("fill", app.x + (app.width - 18) / 2, dockY + (dockH - 18) / 2, 18, 18, 2, 2)
        end

        -- Windows 10 Active Underline Indicator Bar
        if isRunning then
            if isFocused then
                love.graphics.setColor(0.0, 0.47, 0.83) -- Windows Accent Blue
                love.graphics.rectangle("fill", app.x + 4, dockY + dockH - 3, app.width - 8, 2)
            else
                love.graphics.setColor(0.6, 0.65, 0.7)
                love.graphics.rectangle("fill", app.x + 8, dockY + dockH - 3, app.width - 16, 2)
            end
        end
    end

    love.graphics.pop()
end

function DesktopManager.drawStartMenu()
    if not DesktopManager.startMenuOpen then return end

    local screenH = love.graphics.getHeight()
    local menuW, menuH = 220, 280
    local menuX, menuY = 0, screenH - Taskbar.bottomBarHeight - menuH

    love.graphics.push()

    -- Drop shadow
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", menuX + 2, menuY + 2, menuW, menuH)

    -- Windows 10 Start Menu Plate
    love.graphics.setColor(0.12, 0.12, 0.15, 0.98)
    love.graphics.rectangle("fill", menuX, menuY, menuW, menuH)
    love.graphics.setColor(0.22, 0.22, 0.26)
    love.graphics.line(menuX, menuY, menuX + menuW, menuY)
    love.graphics.line(menuX + menuW, menuY, menuX + menuW, menuY + menuH)

    -- Header
    love.graphics.setColor(0.9, 0.92, 0.96)
    love.graphics.setFont(DesktopManager.boldFont or DesktopManager.font)
    love.graphics.print("Applications", menuX + 16, menuY + 12)
    love.graphics.setColor(0.2, 0.22, 0.28)
    love.graphics.line(menuX + 14, menuY + 36, menuX + menuW - 14, menuY + 36)

    -- List apps
    local itemY = menuY + 44
    for _, app in ipairs(DesktopManager.apps) do
        if app.icon then
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.draw(app.icon, menuX + 16, itemY, 0, 16 / app.icon:getWidth(), 16 / app.icon:getHeight())
        end
        love.graphics.setFont(DesktopManager.font)
        love.graphics.setColor(0.9, 0.92, 0.96)
        love.graphics.print(app.name, menuX + 40, itemY)
        itemY = itemY + 22
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
    -- 1. Toast Notifications
    if Notifications.mousepressed(x, y, button) then return end

    -- 2. Taskbar System Tray Controls
    if Taskbar.mousepressed(x, y, button) then return end

    -- 3. Start Menu handling
    if DesktopManager.startMenuOpen then
        local screenH = love.graphics.getHeight()
        local menuW, menuH = 220, 280
        local menuX, menuY = 0, screenH - Taskbar.bottomBarHeight - menuH
        if x >= menuX and x <= menuX + menuW and y >= menuY and y <= menuY + menuH then
            local itemY = menuY + 44
            for _, app in ipairs(DesktopManager.apps) do
                if y >= itemY and y <= itemY + 22 then
                    WindowManager.toggleApp(app)
                    DesktopManager.startMenuOpen = false
                    return
                end
                itemY = itemY + 22
            end
            return
        else
            DesktopManager.startMenuOpen = false
        end
    end

    -- 4. Bottom Taskbar Start Button & App Icons
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

        -- Taskbar App Launcher Icons
        for _, app in ipairs(DesktopManager.apps) do
            if x >= app.x and x <= app.x + app.width then
                WindowManager.toggleApp(app)
                return
            end
        end
        return
    end

    -- 5. Windows
    if WindowManager.mousepressed(x, y, button) then return end

    -- 6. Task HUD
    if TaskHUD.mousepressed(x, y, button) then return end

    -- 7. Desktop File/Folder Icons
    for _, iconInfo in ipairs(DesktopManager.desktopHomeIcons) do
        if x >= iconInfo.x and x <= iconInfo.x + iconInfo.width and y >= iconInfo.y and y <= iconInfo.y + iconInfo.height + 18 then
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
    if key == "tab" then
        EventBus.emit("game:request_switch_mode", { mode = "story", transition = "fade" })
        return
    end
    WindowManager.keypressed(key)
end

function DesktopManager.resize(w, h)
    DesktopManager.updateDockLayout()
end

return DesktopManager
