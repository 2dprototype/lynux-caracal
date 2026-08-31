-- src/desktop/desktop_mgr.lua
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
    currentWallpaper = {
        type = "retro_yellow",
        color = {0.14, 0.12, 0.16}
    },
    startMenuOpen = false,
    startIcon = nil,
    folderIcon = nil,
    fileIcon = nil,
    shortcutIcon = nil,
    font = nil,
    boldFont = nil,
    lastClickTime = 0,
    lastClickIcon = nil
}

function DesktopManager.init()
    Taskbar.init()
    WindowManager.init()
    TaskHUD.init()
    Notifications.init()

    DesktopManager.font = love.graphics.newFont("font/Nunito-Regular.ttf", 13) or love.graphics.newFont(13)
    DesktopManager.boldFont = love.graphics.newFont("font/Nunito-Regular.ttf", 14) or love.graphics.newFont(14)

    -- Load icons
    pcall(function()
        DesktopManager.folderIcon = love.graphics.newImage("assets/folder.png")
        DesktopManager.fileIcon = love.graphics.newImage("assets/file.png")
        DesktopManager.shortcutIcon = love.graphics.newImage("assets/shortcut.png")
        DesktopManager.startIcon = love.graphics.newImage("assets/layers.png")
    end)

    -- Filesystem setup
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

    -- Register Apps
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

    -- Global file opener hook for FilesApp and Desktop icons!
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

    -- Position taskbar launcher icons
    DesktopManager.updateDockLayout()
end

function DesktopManager.updateDockLayout()
    local screenH = love.graphics.getHeight()
    local iconSize = 34
    local iconSpacing = 8
    local startX = 60
    local dockY = screenH - Taskbar.bottomBarHeight + (Taskbar.bottomBarHeight - iconSize) / 2

    for _, app in ipairs(DesktopManager.apps) do
        app.x = startX
        app.y = dockY
        app.width = iconSize
        app.height = iconSize
        startX = startX + iconSize + iconSpacing
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

    -- Check if an existing TextEditor window is open
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
    
    -- Retro Yellow Gaming / Warm Cozy Wallpaper (Fast, lag-free rendering)
    love.graphics.setColor(0.13, 0.12, 0.15) -- Warm dark espresso base
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Soft Retro Grid in Honey Gold
    love.graphics.setColor(1.0, 0.82, 0.25, 0.05)
    for x = 0, screenW, 36 do
        love.graphics.line(x, 0, x, screenH)
    end
    for y = 0, screenH, 36 do
        love.graphics.line(0, y, screenW, y)
    end

    -- Cute Retro Pixel Art Watermark in Center (Lynux Caracal)
    love.graphics.setColor(1.0, 0.82, 0.25, 0.06)
    love.graphics.circle("fill", screenW * 0.58, screenH * 0.46, 90)
end

function DesktopManager.drawDesktopIcons()
    DesktopManager.desktopHomeIcons = {}
    local iconSize = 36
    local spacingX, spacingY = 74, 72
    local startX, startY = 275, 45 -- Offset so TaskHUD sticky note on left doesn't overlap
    local cols = 5
    local index = 0

    if DesktopManager.desktopHome and DesktopManager.desktopHome.children then
        for name, node in pairs(DesktopManager.desktopHome.children) do
            local col = index % cols
            local row = math.floor(index / cols)
            local x = startX + col * spacingX
            local y = startY + row * spacingY

            -- Cute Retro Icon Frame
            local icon = (node.type == "directory") and DesktopManager.folderIcon or DesktopManager.fileIcon
            if icon then
                love.graphics.setColor(1, 1, 1, 0.95)
                love.graphics.draw(icon, x, y, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
            else
                love.graphics.setColor(1.0, 0.82, 0.25, 0.9)
                love.graphics.rectangle("fill", x, y, iconSize, iconSize, 4, 4)
            end

            -- Label (Crisp Warm Cream)
            love.graphics.setFont(DesktopManager.font)
            love.graphics.setColor(0.98, 0.96, 0.92)
            love.graphics.printf(name, x - 14, y + iconSize + 2, iconSize + 28, "center")

            table.insert(DesktopManager.desktopHomeIcons, {
                x = x, y = y, width = iconSize, height = iconSize, node = node, name = name
            })
            index = index + 1
        end
    end
end

function DesktopManager.drawBottomDock()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local dockH = Taskbar.bottomBarHeight
    local dockY = screenH - dockH

    love.graphics.push()

    -- Dock background (Warm Retro Dark Charcoal)
    love.graphics.setColor(0.11, 0.1, 0.13, 0.96)
    love.graphics.rectangle("fill", 0, dockY, screenW, dockH)
    love.graphics.setColor(1.0, 0.82, 0.25, 0.4) -- Sunny Yellow Accent Line
    love.graphics.line(0, dockY, screenW, dockY)

    -- Start Menu Button (Cute Retro Yellow / Pink)
    love.graphics.setColor(DesktopManager.startMenuOpen and 0.25 or 0.16, DesktopManager.startMenuOpen and 0.22 or 0.14, 0.18, 0.95)
    love.graphics.rectangle("fill", 8, dockY + 5, 34, 32, 5, 5)
    love.graphics.setColor(1.0, 0.82, 0.25, 0.8) -- Sunny Yellow border
    love.graphics.setLineWidth(1.2)
    love.graphics.rectangle("line", 8, dockY + 5, 34, 32, 5, 5)
    
    if DesktopManager.startIcon then
        love.graphics.setColor(1.0, 0.88, 0.4)
        love.graphics.draw(DesktopManager.startIcon, 16, dockY + 12, 0, 18 / DesktopManager.startIcon:getWidth(), 18 / DesktopManager.startIcon:getHeight())
    else
        love.graphics.setColor(1.0, 0.82, 0.25)
        love.graphics.circle("fill", 25, dockY + 21, 6)
    end

    -- App Launcher Icons
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

        -- Background highlight if focused
        if isFocused then
            love.graphics.setColor(0.24, 0.2, 0.18, 0.9)
            love.graphics.rectangle("fill", app.x - 2, app.y - 2, app.width + 4, app.height + 4, 5, 5)
            love.graphics.setColor(1.0, 0.82, 0.25, 0.9)
            love.graphics.rectangle("line", app.x - 2, app.y - 2, app.width + 4, app.height + 4, 5, 5)
        elseif isRunning then
            love.graphics.setColor(0.18, 0.16, 0.2, 0.7)
            love.graphics.rectangle("fill", app.x - 2, app.y - 2, app.width + 4, app.height + 4, 5, 5)
        end

        -- App Icon
        if app.icon then
            love.graphics.setColor(1, 1, 1, isRunning and 1.0 or 0.85)
            love.graphics.draw(app.icon, app.x, app.y, 0, app.width / app.icon:getWidth(), app.height / app.icon:getHeight())
        else
            love.graphics.setColor(1.0, 0.82, 0.25)
            love.graphics.rectangle("fill", app.x, app.y, app.width, app.height, 4, 4)
        end

        -- Cute Retro Dot Indicator underneath running apps (Sunny Yellow or Mint)
        if isRunning then
            love.graphics.setColor(1.0, 0.82, 0.25) -- Sunny Yellow Dot
            love.graphics.circle("fill", app.x + app.width / 2, dockY + dockH - 4, 2.5)
        end
    end

    love.graphics.pop()
end

function DesktopManager.drawStartMenu()
    if not DesktopManager.startMenuOpen then return end

    local screenH = love.graphics.getHeight()
    local menuW, menuH = 210, 270
    local menuX, menuY = 8, screenH - Taskbar.bottomBarHeight - menuH - 4

    love.graphics.push()

    -- Drop shadow
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", menuX + 3, menuY + 3, menuW, menuH, 6, 6)

    -- Background (Warm Retro Charcoal)
    love.graphics.setColor(0.13, 0.12, 0.16, 0.96)
    love.graphics.rectangle("fill", menuX, menuY, menuW, menuH, 6, 6)
    love.graphics.setColor(1.0, 0.82, 0.25, 0.7) -- Sunny Yellow Border
    love.graphics.setLineWidth(1.2)
    love.graphics.rectangle("line", menuX, menuY, menuW, menuH, 6, 6)

    -- Header (Cute Gaming Menu)
    love.graphics.setColor(1.0, 0.85, 0.3) -- Sunny Yellow
    love.graphics.setFont(DesktopManager.boldFont or DesktopManager.font)
    love.graphics.print("★ Applications", menuX + 12, menuY + 8)
    love.graphics.setColor(1.0, 0.82, 0.25, 0.3)
    love.graphics.line(menuX + 10, menuY + 26, menuX + menuW - 10, menuY + 26)

    -- List apps
    local itemY = menuY + 32
    for _, app in ipairs(DesktopManager.apps) do
        if app.icon then
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.draw(app.icon, menuX + 12, itemY, 0, 16 / app.icon:getWidth(), 16 / app.icon:getHeight())
        end
        love.graphics.setFont(DesktopManager.font)
        love.graphics.setColor(0.95, 0.95, 0.95)
        love.graphics.print(app.name, menuX + 34, itemY)
        itemY = itemY + 23
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
    Taskbar.drawTopBar()
    DesktopManager.drawBottomDock()
    DesktopManager.drawStartMenu()
    Notifications.draw()
end

function DesktopManager.mousepressed(x, y, button)
    -- 1. Toast Notifications
    if Notifications.mousepressed(x, y, button) then return end

    -- 2. Taskbar Top controls
    if Taskbar.mousepressed(x, y, button) then return end

    -- 3. Start Menu handling
    if DesktopManager.startMenuOpen then
        local screenH = love.graphics.getHeight()
        local menuW, menuH = 210, 270
        local menuX, menuY = 8, screenH - Taskbar.bottomBarHeight - menuH - 4
        if x >= menuX and x <= menuX + menuW and y >= menuY and y <= menuY + menuH then
            local itemY = menuY + 32
            for _, app in ipairs(DesktopManager.apps) do
                if y >= itemY and y <= itemY + 22 then
                    WindowManager.toggleApp(app)
                    DesktopManager.startMenuOpen = false
                    return
                end
                itemY = itemY + 23
            end
            return
        else
            DesktopManager.startMenuOpen = false
        end
    end

    -- 4. Bottom Dock Start Button & App Icons
    local screenH = love.graphics.getHeight()
    local dockH = Taskbar.bottomBarHeight
    local dockY = screenH - dockH

    if y >= dockY then
        -- Start Button
        if x >= 8 and x <= 44 then
            DesktopManager.startMenuOpen = not DesktopManager.startMenuOpen
            AudioManager.playSFX("click")
            return
        end

        -- Dock App Icons
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

    -- 7. Desktop File/Folder Icons (Single click / Double click to open)
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
                    -- Open file in TextEditor or appropriate viewer!
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
