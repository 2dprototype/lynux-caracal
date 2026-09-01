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
local Viewport = require("src.core.viewport")
local DLCManager = require("src.core.dlc_manager")

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
    startMenuScroll = 0,
    startMenuMaxScroll = 0,
    isDraggingStartMenuScroll = false,
    startMenuDragStartY = 0,
    startMenuDragStartScroll = 0,
    lastMouseX = -1,
    lastMouseY = -1,
    startIcon = nil,
    folderIcon = nil,
    fileIcon = nil,
    shortcutIcon = nil,
    font = nil,
    boldFont = nil,
    smallFont = nil,
    taskbarIcons = {}
}

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

local function loadImg(path)
    local ok, img = pcall(love.graphics.newImage, path)
    return ok and img or nil
end

function DesktopManager.reloadApps()
    DLCManager.init()

    DesktopManager.apps = {
        { name = "TextEditor", module = TextEditor, icon = loadImg("assets/file.png"), defaultWidth = 560, defaultHeight = 350 },
        { name = "Terminal", module = TerminalApp, icon = loadImg("assets/terminal.png"), defaultWidth = 560, defaultHeight = 350 },
        { name = "Files", module = FilesApp, icon = loadImg("assets/files.png"), defaultWidth = 560, defaultHeight = 350 },
        { name = "Chat", module = ChatApp, icon = loadImg("assets/chat.png"), defaultWidth = 540, defaultHeight = 360 },
        { name = "Email", module = EmailApp, icon = loadImg("assets/email.png"), defaultWidth = 560, defaultHeight = 350 },
        { name = "Browser", module = BrowserApp, icon = loadImg("assets/browser.png"), defaultWidth = 560, defaultHeight = 360 },
        { name = "ImageViewer", module = ImageViewer, icon = loadImg("assets/image.png"), defaultWidth = 540, defaultHeight = 340 },
        { name = "ObjViewer", module = ObjViewer, icon = loadImg("assets/cube.png"), defaultWidth = 540, defaultHeight = 340 },
        { name = "Tessarect", module = TessarectApp, icon = loadImg("assets/box.png"), defaultWidth = 540, defaultHeight = 340 },
        { name = "Settings", module = SettingsApp, icon = loadImg("assets/settings.png"), defaultWidth = 480, defaultHeight = 340 },
    }

    -- Append dynamically discovered DLC apps
    for _, dlcApp in ipairs(DLCManager.getLoadedApps()) do
        dlcApp.defaultWidth = dlcApp.defaultWidth or dlcApp.width or 520
        dlcApp.defaultHeight = dlcApp.defaultHeight or dlcApp.height or 360
        table.insert(DesktopManager.apps, dlcApp)
    end

    DesktopManager.updateDockLayout()
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

    DesktopManager.reloadApps()
end

function DesktopManager.updateDockLayout()
    local screenW = Viewport.getWidth()
    local screenH = Viewport.getHeight()
    local dockH = Taskbar.bottomBarHeight
    local dockY = screenH - dockH

    -- Calculate available space for app icons (between Start button and system tray)
    local startBtnWidth = 44
    local systemTrayWidth = 225
    local availableWidth = screenW - startBtnWidth - systemTrayWidth - 20
    
    local numApps = #DesktopManager.apps
    local minItemWidth = 40
    local maxItemWidth = 52
    local spacing = 4
    
    local idealItemWidth = math.min(maxItemWidth, math.max(minItemWidth, (availableWidth - (numApps - 1) * spacing) / numApps))
    local itemW = math.floor(idealItemWidth)
    local itemH = math.floor(itemW * 0.8)
    
    local startX = startBtnWidth + 8
    local totalWidth = numApps * itemW + (numApps - 1) * spacing
    if totalWidth < availableWidth then
        startX = startX + (availableWidth - totalWidth) / 2
    end
    
    local maxIterations = 3
    while totalWidth > availableWidth and itemW > 28 and maxIterations > 0 do
        itemW = itemW - 2
        itemH = math.floor(itemW * 0.8)
        totalWidth = numApps * itemW + (numApps - 1) * spacing
        maxIterations = maxIterations - 1
    end
    
    local visibleApps = numApps
    if totalWidth > availableWidth then
        local maxVisible = math.floor((availableWidth + spacing) / (minItemWidth + spacing))
        visibleApps = math.max(3, maxVisible)
    end

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
        local newInstance = imgApp.module.new(node and node.name, node)
        WindowManager.openWindow(imgApp, 540, 340, newInstance, node and (node.name .. " - ImageViewer") or "ImageViewer")
    end
    AudioManager.playSFX("click")
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
        local newInstance = objApp.module.new(node and node.name, node)
        WindowManager.openWindow(objApp, 540, 340, newInstance, node and (node.name .. " - 3D Viewer") or "3D Viewer")
    end
    AudioManager.playSFX("click")
end

function DesktopManager.drawWallpaper()
    local screenW, screenH = Viewport.getWidth(), Viewport.getHeight()
    
    -- Modern deep blue (Windows 11 style)
    love.graphics.setColor(0.10, 0.15, 0.25)  -- #192A3E
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)
    
    -- Subtle top accent line
    love.graphics.setColor(0.2, 0.35, 0.55, 0.4)
    love.graphics.rectangle("fill", 0, 0, screenW, 2)
end
-- ============================================================
--  FIXED: Desktop icons now left‑aligned and dynamically gridded
-- ============================================================
function DesktopManager.drawDesktopIcons()
    DesktopManager.desktopHomeIcons = {}
    local iconSize = 40
    local spacingX = 84
    local spacingY = 80
    local leftMargin = 20
    local topMargin = 40
    local rightMargin = 20
    local screenW, screenH = Viewport.getWidth(), Viewport.getHeight()

    local availWidth = screenW - leftMargin - rightMargin
    local cols = math.max(1, math.floor((availWidth + spacingX) / (iconSize + spacingX)))

    local index = 0
    if DesktopManager.desktopHome and DesktopManager.desktopHome.children then
        for name, node in pairs(DesktopManager.desktopHome.children) do
            local col = index % cols
            local row = math.floor(index / cols)
            local x = leftMargin + col * spacingX
            local y = topMargin + row * spacingY

            -- Icon background with subtle shadow
            love.graphics.setColor(0, 0, 0, 0.25)
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

            -- Label with semi-transparent background for readability
            love.graphics.setFont(DesktopManager.smallFont or DesktopManager.font)
            
            -- Measure text for background
            local labelWidth = love.graphics.getFont():getWidth(name)
            local labelHeight = love.graphics.getFont():getHeight()
            local labelX = x + (iconSize - labelWidth) / 2 - 4
            local labelY = y + iconSize + 4
            
            -- Subtle dark background behind text
            love.graphics.setColor(0, 0, 0, 0.35)
            love.graphics.rectangle("fill", labelX - 2, labelY - 1, labelWidth + 4, labelHeight + 2, 2, 2)
            
            -- Text shadow
            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.printf(name, x - 16 + 1, y + iconSize + 4 + 1, iconSize + 32, "center")
            
            -- Main white text
            love.graphics.setColor(1, 1, 1, 0.98)
            love.graphics.printf(name, x - 16, y + iconSize + 4, iconSize + 32, "center")

            table.insert(DesktopManager.desktopHomeIcons, {
                x = x, y = y,
                width = iconSize, height = iconSize,
                node = node,
                name = name
            })
            index = index + 1
        end
    end
end

function DesktopManager.drawTaskbarApps()
    local screenH = Viewport.getHeight()
    local dockH = Taskbar.bottomBarHeight
    local dockY = screenH - dockH

    love.graphics.push()

    for _, app in ipairs(DesktopManager.apps) do
        if not app.visible then break end
        
        local instances = WindowManager.getAppInstances(app)
        local isRunning = #instances > 0
        local isFocused = false

        for _, win in ipairs(instances) do
            if win == WindowManager.focusedWindow and not win.minimized then
                isFocused = true
                break
            end
        end

        if isFocused then
            love.graphics.setColor(0.85, 0.9, 0.95, 0.7)
            love.graphics.rectangle("fill", app.x, dockY + 2, app.width, dockH - 4, 2, 2)
        elseif isRunning then
            love.graphics.setColor(0.75, 0.8, 0.85, 0.5)
            love.graphics.rectangle("fill", app.x, dockY + 2, app.width, dockH - 4, 2, 2)
        end

        local iconSize = math.min(app.width - 8, app.height - 8, 24)
        if app.icon then
            love.graphics.setColor(1, 1, 1, isRunning and 1.0 or 0.7)
            local scale = iconSize / app.icon:getWidth()
            love.graphics.draw(app.icon, app.x + (app.width - iconSize) / 2, app.y + (app.height - iconSize) / 2, 0, scale, scale)
        else
            love.graphics.setColor(0.0, 0.47, 0.83)
            love.graphics.rectangle("fill", app.x + (app.width - 18) / 2, app.y + (app.height - 18) / 2, 18, 18, 2, 2)
        end

        if #instances > 1 then
            love.graphics.setFont(DesktopManager.smallFont)
            love.graphics.setColor(0.0, 0.65, 1.0)
            love.graphics.print(tostring(#instances), app.x + app.width - 14, dockY + 4)
        end

        if isRunning then
            if isFocused then
                love.graphics.setColor(0.0, 0.47, 0.83)
                love.graphics.rectangle("fill", app.x + 6, dockY + dockH - 3, app.width - 12, 2)
            else
                love.graphics.setColor(0.5, 0.55, 0.6)
                love.graphics.rectangle("fill", app.x + 10, dockY + dockH - 3, app.width - 20, 2)
            end
        end
    end
    
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

    local screenH = Viewport.getHeight()
    local menuW = 240
    local menuH = math.min(330, screenH - Taskbar.bottomBarHeight - 12)
    local menuX, menuY = 0, screenH - Taskbar.bottomBarHeight - menuH

    love.graphics.push()
    love.graphics.setColor(0, 0, 0, 0.15)
    love.graphics.rectangle("fill", menuX + 4, menuY + 4, menuW, menuH)
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

    local headerH = 42
    local listX = menuX
    local listY = menuY + headerH
    local listW = menuW
    local listH = menuH - headerH - 6
    local itemH = 26
    local totalHeight = #DesktopManager.apps * itemH

    DesktopManager.startMenuMaxScroll = math.max(0, totalHeight - listH)
    DesktopManager.startMenuScroll = math.max(0, math.min(DesktopManager.startMenuMaxScroll, DesktopManager.startMenuScroll or 0))

    -- Scissor clip for scrollable apps
    local barW = 6
    local contentW = listW - (DesktopManager.startMenuMaxScroll > 0 and (barW + 8) or 0)
    love.graphics.setScissor(listX, listY, contentW, listH)

    for i, app in ipairs(DesktopManager.apps) do
        local itemY = listY + (i - 1) * itemH - DesktopManager.startMenuScroll
        if itemY + itemH >= listY and itemY <= listY + listH then
            -- Hover highlight
            local mx, my = DesktopManager.lastMouseX or -1, DesktopManager.lastMouseY or -1
            if mx >= listX + 8 and mx <= listX + contentW - 4 and my >= itemY and my <= itemY + itemH then
                love.graphics.setColor(0.92, 0.95, 0.98)
                love.graphics.rectangle("fill", listX + 8, itemY, contentW - 12, itemH - 2, 3, 3)
            end

            if app.icon then
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(app.icon, menuX + 16, itemY + 3, 0, 18 / app.icon:getWidth(), 18 / app.icon:getHeight())
            else
                love.graphics.setColor(0.0, 0.47, 0.83)
                love.graphics.rectangle("fill", menuX + 16, itemY + 3, 18, 18, 2, 2)
            end
            love.graphics.setFont(DesktopManager.font)
            love.graphics.setColor(0.1, 0.12, 0.16)
            love.graphics.print(app.name, menuX + 42, itemY + 3)
        end
    end

    love.graphics.setScissor()

    -- Scrollbar Track and Grabable Thumb
    if DesktopManager.startMenuMaxScroll > 0 then
        local barX = menuX + menuW - barW - 6
        local barY = listY + 2
        local barH = listH - 4

        love.graphics.setColor(0.92, 0.93, 0.95)
        love.graphics.rectangle("fill", barX, barY, barW, barH, 3, 3)

        local thumbH = math.max(20, math.floor(barH * (listH / totalHeight)))
        local thumbY = barY + (barH - thumbH) * (DesktopManager.startMenuScroll / DesktopManager.startMenuMaxScroll)

        if DesktopManager.isDraggingStartMenuScroll then
            love.graphics.setColor(0.20, 0.50, 0.85)
        else
            love.graphics.setColor(0.65, 0.70, 0.76)
        end
        love.graphics.rectangle("fill", barX, thumbY, barW, thumbH, 3, 3)
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

    if DesktopManager.startMenuOpen then
        local screenH = Viewport.getHeight()
        local menuW = 240
        local menuH = math.min(330, screenH - Taskbar.bottomBarHeight - 12)
        local menuX, menuY = 0, screenH - Taskbar.bottomBarHeight - menuH
        local headerH = 42
        local listX = menuX
        local listY = menuY + headerH
        local listW = menuW
        local listH = menuH - headerH - 6
        local itemH = 26

        if x >= menuX and x <= menuX + menuW and y >= menuY and y <= menuY + menuH then
            -- Check if clicking on scrollbar track / thumb
            if DesktopManager.startMenuMaxScroll > 0 and x >= menuX + menuW - 16 and y >= listY and y <= listY + listH then
                DesktopManager.isDraggingStartMenuScroll = true
                DesktopManager.startMenuDragStartY = y
                DesktopManager.startMenuDragStartScroll = DesktopManager.startMenuScroll
                return true
            end

            -- Check if clicking on an app item
            if y >= listY and y <= listY + listH then
                local clickedIdx = math.floor((y - listY + DesktopManager.startMenuScroll) / itemH) + 1
                local app = DesktopManager.apps[clickedIdx]
                if app then
                    WindowManager.toggleApp(app, button == 2)
                    DesktopManager.startMenuOpen = false
                    AudioManager.playSFX("click")
                    return true
                end
            end
            return true
        else
            DesktopManager.startMenuOpen = false
            DesktopManager.isDraggingStartMenuScroll = false
        end
    end

    local screenH = Viewport.getHeight()
    local dockH = Taskbar.bottomBarHeight
    local dockY = screenH - dockH

    if y >= dockY then
        if x >= 0 and x <= 44 then
            DesktopManager.startMenuOpen = not DesktopManager.startMenuOpen
            AudioManager.playSFX("click")
            return
        end
        for _, app in ipairs(DesktopManager.apps) do
            if app.visible and x >= app.x and x <= app.x + app.width then
                WindowManager.toggleApp(app, button == 2)
                return
            end
        end
        return
    end

    if WindowManager.mousepressed(x, y, button) then return end
    if TaskHUD.mousepressed(x, y, button) then return end

    -- Desktop icons hit detection
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
    DesktopManager.lastMouseX = x
    DesktopManager.lastMouseY = y

    if DesktopManager.isDraggingStartMenuScroll and DesktopManager.startMenuMaxScroll > 0 then
        local screenH = Viewport.getHeight()
        local menuH = math.min(330, screenH - Taskbar.bottomBarHeight - 12)
        local headerH = 42
        local listH = menuH - headerH - 6
        local itemH = 26
        local totalHeight = #DesktopManager.apps * itemH
        local barH = listH - 4
        local thumbH = math.max(20, math.floor(barH * (listH / totalHeight)))
        local trackSpan = math.max(1, barH - thumbH)

        local deltaY = y - DesktopManager.startMenuDragStartY
        local newScroll = DesktopManager.startMenuDragStartScroll + (deltaY / trackSpan) * DesktopManager.startMenuMaxScroll
        DesktopManager.startMenuScroll = math.max(0, math.min(DesktopManager.startMenuMaxScroll, newScroll))
        return
    end

    Taskbar.mousemoved(x, y)
    TaskHUD.mousemoved(x, y, dx, dy)
    WindowManager.mousemoved(x, y, dx, dy)
end

function DesktopManager.mousereleased(x, y, button)
    if button == 1 and DesktopManager.isDraggingStartMenuScroll then
        DesktopManager.isDraggingStartMenuScroll = false
    end
    WindowManager.mousereleased(x, y, button)
    TaskHUD.mousereleased(x, y, button)
end

function DesktopManager.wheelmoved(x, y)
    if DesktopManager.startMenuOpen and DesktopManager.startMenuMaxScroll > 0 then
        DesktopManager.startMenuScroll = math.max(0, math.min(DesktopManager.startMenuMaxScroll, DesktopManager.startMenuScroll - y * 26))
        return
    end
    if TaskHUD.wheelmoved and TaskHUD.wheelmoved(x, y) then return end
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
    TaskHUD.resize()
    -- Desktop icon positions are recalculated on the next draw, nothing more needed.
end

return DesktopManager