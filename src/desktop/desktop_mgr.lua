-- src/desktop/desktop_mgr.lua
local json = require("lib/json")
local filesystemModule = require("filesystem")
local AudioManager = require("src.core.audio_manager")
local EventBus = require("src.core.event_bus")
local Taskbar = require("src.desktop.taskbar")
local WindowManager = require("src.desktop.window_mgr")
local TaskHUD = require("src.desktop.task_hud")
local Notifications = require("src.desktop.notifications")

-- Load App Modules
local EmailApp = require("email")
local BrowserApp = require("browser")
local FilesApp = require("files")
local TerminalApp = require("terminal") 
local TextEditor = require("texteditor")
local TessarectApp = require("tessarect")
local ImageViewer = require("imageviewer")
local ObjViewer = require("objviewer")
local ChatApp = require("chat")
local SettingsApp = require("settings")

local DesktopManager = {
    apps = {},
    desktopHomeIcons = {},
    desktopHome = nil,
    currentWallpaper = {
        type = "color",
        color = {0.12, 0.16, 0.24}
    },
    startMenuOpen = false,
    startIcon = nil,
    folderIcon = nil,
    fileIcon = nil,
    shortcutIcon = nil,
    font = nil
}

function DesktopManager.init()
    Taskbar.init()
    WindowManager.init()
    TaskHUD.init()
    Notifications.init()

    DesktopManager.font = love.graphics.newFont("font/Nunito-Regular.ttf", 13) or love.graphics.newFont(13)

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

function DesktopManager.drawWallpaper()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    
    if DesktopManager.currentWallpaper.type == "color" then
        love.graphics.setColor(DesktopManager.currentWallpaper.color)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    else
        -- Clean Minimalist Dark Slate / Charcoal Gradient
        for y = 0, screenH do
            local ratio = y / screenH
            love.graphics.setColor(0.07 + ratio * 0.04, 0.09 + ratio * 0.04, 0.13 + ratio * 0.05)
            love.graphics.line(0, y, screenW, y)
        end
    end

    -- Minimalist subtle retro grid
    love.graphics.setColor(0.2, 0.35, 0.5, 0.05)
    for x = 0, screenW, 36 do
        love.graphics.line(x, 0, x, screenH)
    end
    for y = 0, screenH, 36 do
        love.graphics.line(0, y, screenW, y)
    end
end

function DesktopManager.drawDesktopIcons()
    DesktopManager.desktopHomeIcons = {}
    local iconSize = 36
    local spacingX, spacingY = 72, 70
    local startX, startY = 275, 46 -- Offset so TaskHUD sticky note on left doesn't overlap
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
                love.graphics.setColor(0.2, 0.65, 0.95)
                love.graphics.rectangle("fill", x, y, iconSize, iconSize, 4, 4)
            end

            -- Label
            love.graphics.setFont(DesktopManager.font)
            love.graphics.setColor(0.9, 0.93, 0.97)
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

    -- Dock background (Minimalist Dark Slate)
    love.graphics.setColor(0.08, 0.1, 0.15, 0.96)
    love.graphics.rectangle("fill", 0, dockY, screenW, dockH)
    love.graphics.setColor(0.18, 0.22, 0.3, 0.8)
    love.graphics.line(0, dockY, screenW, dockY)

    -- Start Menu Button
    love.graphics.setColor(DesktopManager.startMenuOpen and 0.22 or 0.13, DesktopManager.startMenuOpen and 0.35 or 0.17, 0.24, 0.95)
    love.graphics.rectangle("fill", 8, dockY + 5, 34, 32, 4, 4)
    love.graphics.setColor(0.2, 0.88, 0.55, 0.7) -- Neon Mint outline
    love.graphics.rectangle("line", 8, dockY + 5, 34, 32, 4, 4)
    
    if DesktopManager.startIcon then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(DesktopManager.startIcon, 16, dockY + 12, 0, 18 / DesktopManager.startIcon:getWidth(), 18 / DesktopManager.startIcon:getHeight())
    else
        love.graphics.setColor(0.2, 0.88, 0.55)
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
            love.graphics.setColor(0.18, 0.3, 0.45, 0.85)
            love.graphics.rectangle("fill", app.x - 2, app.y - 2, app.width + 4, app.height + 4, 4, 4)
            love.graphics.setColor(0.2, 0.75, 1.0, 0.7)
            love.graphics.rectangle("line", app.x - 2, app.y - 2, app.width + 4, app.height + 4, 4, 4)
        elseif isRunning then
            love.graphics.setColor(0.14, 0.18, 0.25, 0.7)
            love.graphics.rectangle("fill", app.x - 2, app.y - 2, app.width + 4, app.height + 4, 4, 4)
        end

        -- Icon
        if app.icon then
            love.graphics.setColor(1, 1, 1, isRunning and 1.0 or 0.8)
            love.graphics.draw(app.icon, app.x, app.y, 0, app.width / app.icon:getWidth(), app.height / app.icon:getHeight())
        else
            love.graphics.setColor(0.2, 0.65, 0.95)
            love.graphics.rectangle("fill", app.x, app.y, app.width, app.height, 4, 4)
        end

        -- Neon Dot Indicator underneath running apps
        if isRunning then
            love.graphics.setColor(0.2, 0.88, 0.55) -- Neon Mint
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
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", menuX + 3, menuY + 3, menuW, menuH, 6, 6)

    -- Background (Minimalist Slate)
    love.graphics.setColor(0.1, 0.12, 0.17, 0.96)
    love.graphics.rectangle("fill", menuX, menuY, menuW, menuH, 6, 6)
    love.graphics.setColor(0.22, 0.28, 0.38, 0.8)
    love.graphics.rectangle("line", menuX, menuY, menuW, menuH, 6, 6)

    -- Header
    love.graphics.setColor(0.2, 0.88, 0.55) -- Neon Mint
    love.graphics.setFont(DesktopManager.font)
    love.graphics.print("Applications", menuX + 12, menuY + 9)
    love.graphics.setColor(0.2, 0.26, 0.36, 0.5)
    love.graphics.line(menuX + 10, menuY + 26, menuX + menuW - 10, menuY + 26)

    -- List apps
    local itemY = menuY + 32
    for _, app in ipairs(DesktopManager.apps) do
        if app.icon then
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.draw(app.icon, menuX + 12, itemY, 0, 16 / app.icon:getWidth(), 16 / app.icon:getHeight())
        end
        love.graphics.setColor(0.9, 0.93, 0.97)
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
        local menuW, menuH = 220, 280
        local menuX, menuY = 8, screenH - Taskbar.bottomBarHeight - menuH - 4
        if x >= menuX and x <= menuX + menuW and y >= menuY and y <= menuY + menuH then
            -- Clicked an app in the start menu
            local itemY = menuY + 34
            for _, app in ipairs(DesktopManager.apps) do
                if y >= itemY and y <= itemY + 22 then
                    WindowManager.toggleApp(app)
                    DesktopManager.startMenuOpen = false
                    return
                end
                itemY = itemY + 24
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

    -- 7. Desktop File/Folder Icons (Double click / single click)
    for _, iconInfo in ipairs(DesktopManager.desktopHomeIcons) do
        if x >= iconInfo.x and x <= iconInfo.x + iconInfo.width and y >= iconInfo.y and y <= iconInfo.y + iconInfo.height + 15 then
            if button == 1 then
                -- Open file in TextEditor or folder in Files
                if iconInfo.node.type == "directory" then
                    local filesApp = DesktopManager.openAppByName("Files")
                    if filesApp and filesApp.instance then
                        filesApp.instance.cwd = iconInfo.node
                        filesApp.instance:updateFileList()
                    end
                else
                    local editorApp = DesktopManager.openAppByName("TextEditor")
                    if editorApp and editorApp.instance then
                        editorApp.instance.filename = iconInfo.name
                        editorApp.instance.fileNode = iconInfo.node
                        if iconInfo.node.content then
                            editorApp.instance:loadContent(iconInfo.node.content)
                        end
                    end
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
        -- Quick mode switch request back to Story
        EventBus.emit("game:request_switch_mode", { mode = "story", transition = "fade" })
        return
    end
    WindowManager.keypressed(key)
end

function DesktopManager.resize(w, h)
    DesktopManager.updateDockLayout()
end

return DesktopManager
