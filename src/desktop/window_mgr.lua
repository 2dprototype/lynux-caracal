-- src/desktop/window_mgr.lua
-- Windows 10 Style Window Manager with Multi-Process / Multi-Instance App Management
-- Light theme, no window borders, focus highlighted in title bar

local AudioManager = require("src.core.audio_manager")
local EventBus = require("src.core.event_bus")

local WindowManager = {
    openApps = {},
    focusedWindow = nil,
    draggingWindow = nil,
    dragOffsetX = 0,
    dragOffsetY = 0,
    resizingWindow = nil,
    resizeOffsetX = 0,
    resizeOffsetY = 0,
    minWidth = 380,
    minHeight = 240,
    titleBarHeight = 32,
    font = nil,
    nextPid = 100
}

local function loadCustomFont(path, size)
    local ok, f = pcall(love.graphics.newFont, path, size)
    if ok and f then return f end
    return love.graphics.newFont(size)
end

function WindowManager.init()
    WindowManager.openApps = {}
    WindowManager.focusedWindow = nil
    WindowManager.draggingWindow = nil
    WindowManager.resizingWindow = nil
    WindowManager.font = loadCustomFont("font/Nunito-Regular.ttf", 14)
    WindowManager.nextPid = 100
end

function WindowManager.setFocus(window)
    if not window then
        WindowManager.focusedWindow = nil
        _G.focusedWindow = nil
        return
    end

    for i, win in ipairs(WindowManager.openApps) do
        if win == window then
            table.remove(WindowManager.openApps, i)
            break
        end
    end
    table.insert(WindowManager.openApps, window)
    WindowManager.focusedWindow = window
    _G.focusedWindow = window
end

-- Open a new window / process instance of an app
function WindowManager.openWindow(app, defaultW, defaultH, customInstance, customTitle)
    defaultW = defaultW or 560
    defaultH = defaultH or 350
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local x = (screenW - defaultW) / 2 + (#WindowManager.openApps * 24) % 100
    local y = 35 + ((screenH - 75 - defaultH) / 2) + (#WindowManager.openApps * 20) % 80

    WindowManager.nextPid = WindowManager.nextPid + 1
    local instance = customInstance
    if not instance and app.module and app.module.new then
        instance = app.module.new()
    end

    local newWindow = {
        pid = WindowManager.nextPid,
        app = app,
        instance = instance,
        title = customTitle or (app and app.name) or "Application",
        x = math.floor(x),
        y = math.floor(y),
        width = defaultW,
        height = defaultH,
        minimized = false
    }

    table.insert(WindowManager.openApps, newWindow)
    WindowManager.setFocus(newWindow)
    AudioManager.playSFX("click")
    EventBus.emit("window:opened", { app = app, window = newWindow, pid = newWindow.pid })
    return newWindow
end

function WindowManager.closeWindow(window)
    for i, win in ipairs(WindowManager.openApps) do
        if win == window then
            table.remove(WindowManager.openApps, i)
            if WindowManager.focusedWindow == window then
                WindowManager.focusedWindow = WindowManager.openApps[#WindowManager.openApps]
                _G.focusedWindow = WindowManager.focusedWindow
            end
            AudioManager.playSFX("click")
            EventBus.emit("window:closed", { app = window.app, window = window, pid = window.pid })
            break
        end
    end
end

-- Toggles focus or launches new process instance
function WindowManager.toggleApp(app, forceNew)
    local instances = {}
    for _, win in ipairs(WindowManager.openApps) do
        if win.app == app then
            table.insert(instances, win)
        end
    end

    if forceNew or #instances == 0 then
        return WindowManager.openWindow(app)
    elseif #instances == 1 then
        local win = instances[1]
        win.minimized = not win.minimized
        if not win.minimized then
            WindowManager.setFocus(win)
        end
        return win
    else
        local nextWin = instances[1]
        for idx, win in ipairs(instances) do
            if win == WindowManager.focusedWindow and not win.minimized then
                nextWin = instances[(idx % #instances) + 1]
                break
            end
        end
        nextWin.minimized = false
        WindowManager.setFocus(nextWin)
        return nextWin
    end
end

function WindowManager.getAppInstances(app)
    local list = {}
    for _, win in ipairs(WindowManager.openApps) do
        if win.app == app then
            table.insert(list, win)
        end
    end
    return list
end

function WindowManager.update(dt)
    for _, win in ipairs(WindowManager.openApps) do
        if not win.minimized and win.instance and win.instance.update then
            pcall(function() win.instance:update(dt) end)
        end
    end
end

function WindowManager.draw()
    local titleH = WindowManager.titleBarHeight

    for _, win in ipairs(WindowManager.openApps) do
        if not win.minimized then
            local isFocused = (win == WindowManager.focusedWindow)

            love.graphics.push()

            -- Subtle shadow (light theme: softer)
            love.graphics.setColor(0, 0, 0, isFocused and 0.12 or 0.06)
            love.graphics.rectangle("fill", win.x + 3, win.y + 3, win.width, win.height)

            -- Window body: white with subtle border on bottom/right? We'll use a very light gray for content area.
            love.graphics.setColor(0.98, 0.98, 0.99)
            love.graphics.rectangle("fill", win.x, win.y, win.width, win.height)

            -- Title bar
            if isFocused then
                -- Highlighted title bar: light blue accent
                love.graphics.setColor(0.92, 0.96, 1.0)  -- very light blue
            else
                love.graphics.setColor(0.96, 0.97, 0.98)
            end
            love.graphics.rectangle("fill", win.x, win.y, win.width, titleH)

            -- Separator line below title bar
            love.graphics.setColor(0.88, 0.9, 0.92)
            love.graphics.line(win.x, win.y + titleH, win.x + win.width, win.y + titleH)

            -- App Icon & Title on the left
            if win.app and win.app.icon then
                love.graphics.setColor(0.2, 0.22, 0.26)
                local iconSize = 16
                local scale = iconSize / win.app.icon:getWidth()
                love.graphics.draw(win.app.icon, win.x + 8, win.y + (titleH - iconSize) / 2, 0, scale, scale)
            end

            love.graphics.setFont(WindowManager.font)
            love.graphics.setColor(isFocused and {0.0, 0.0, 0.0} or {0.3, 0.32, 0.36})
            local titleText = win.instance and win.instance.filename and (win.instance.filename .. " - " .. win.app.name) 
                           or (win.title or (win.app and win.app.name) or "Application")
            love.graphics.print(titleText, win.x + 30, win.y + (titleH - 14) / 2 + 1)

            -- Windows 10 Top-Right Controls: [ _ ] [ □ ] [ ✕ ] (light theme, subtle)
            local btnCloseW = 44
            local btnOtherW = 38
            local closeX = win.x + win.width - btnCloseW
            local maxX = closeX - btnOtherW
            local minX = maxX - btnOtherW

            -- Minimize Button
            love.graphics.setColor(0.3, 0.32, 0.36, isFocused and 0.7 or 0.4)
            love.graphics.line(minX + 14, win.y + 16, minX + 24, win.y + 16)

            -- Maximize / Restore Button
            if win.isMaximized then
                love.graphics.setColor(0.3, 0.32, 0.36, isFocused and 0.7 or 0.4)
                love.graphics.rectangle("line", maxX + 16, win.y + 9, 8, 8)
                love.graphics.setColor(0.98, 0.98, 0.99)
                love.graphics.rectangle("fill", maxX + 13, win.y + 12, 8, 8)
                love.graphics.setColor(0.3, 0.32, 0.36, isFocused and 0.7 or 0.4)
                love.graphics.rectangle("line", maxX + 13, win.y + 12, 8, 8)
            else
                love.graphics.setColor(0.3, 0.32, 0.36, isFocused and 0.7 or 0.4)
                love.graphics.rectangle("line", maxX + 14, win.y + 11, 10, 10)
            end

            -- Close Button (X)
            love.graphics.setColor(0.3, 0.32, 0.36, isFocused and 0.7 or 0.4)
            love.graphics.line(closeX + 17, win.y + 11, closeX + 27, win.y + 21)
            love.graphics.line(closeX + 27, win.y + 11, closeX + 17, win.y + 21)

            -- Content Area (with scissor clipping)
            local contentY = win.y + titleH
            local contentH = win.height - titleH
            love.graphics.setScissor(win.x, contentY, win.width, contentH)

            if win.instance and win.instance.draw then
                pcall(function()
                    win.instance:draw(win.x, contentY, win.width, contentH)
                end)
            end

            love.graphics.setScissor()

            -- No window border drawn at all (as requested)

            love.graphics.pop()
        end
    end
end

function WindowManager.toggleMaximize(win)
    if not win then return end
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local taskbarH = 38
    local titleH = WindowManager.titleBarHeight
    
    if win.isMaximized then
        win.x = win.preMaxX or 50
        win.y = win.preMaxY or 35
        win.width = win.preMaxW or 560
        win.height = win.preMaxH or 350
        win.isMaximized = false
    else
        win.preMaxX = win.x
        win.preMaxY = win.y
        win.preMaxW = win.width
        win.preMaxH = win.height
        
        win.x = 0
        win.y = 0
        win.width = screenW
        win.height = screenH - taskbarH
        win.isMaximized = true
    end
    
    AudioManager.playSFX("click")
    if win.instance and win.instance.resize then
        pcall(function()
            win.instance:resize(win.width, win.height - titleH)
        end)
    end
end

function WindowManager.mousepressed(x, y, button)
    local titleH = WindowManager.titleBarHeight

    for i = #WindowManager.openApps, 1, -1 do
        local win = WindowManager.openApps[i]
        if not win.minimized then
            if x >= win.x and x <= win.x + win.width and y >= win.y and y <= win.y + win.height then
                WindowManager.setFocus(win)

                if y <= win.y + titleH then
                    local btnCloseW = 44
                    local btnOtherW = 38
                    local closeX = win.x + win.width - btnCloseW
                    local maxX = closeX - btnOtherW
                    local minX = maxX - btnOtherW

                    -- Close button click
                    if x >= closeX and x <= win.x + win.width then
                        WindowManager.closeWindow(win)
                        return true
                    end
                    -- Maximize button click
                    if x >= maxX and x < closeX then
                        WindowManager.toggleMaximize(win)
                        return true
                    end
                    -- Minimize button click
                    if x >= minX and x < maxX then
                        win.minimized = true
                        if WindowManager.focusedWindow == win then
                            WindowManager.focusedWindow = nil
                            for j = #WindowManager.openApps, 1, -1 do
                                if not WindowManager.openApps[j].minimized then
                                    WindowManager.setFocus(WindowManager.openApps[j])
                                    break
                                end
                            end
                        end
                        AudioManager.playSFX("click")
                        return true
                    end

                    -- Double click titlebar to toggle maximize
                    local now = love.timer.getTime()
                    if WindowManager.lastTitleClickWin == win and (now - (WindowManager.lastTitleClickTime or 0)) < 0.35 then
                        WindowManager.toggleMaximize(win)
                        WindowManager.lastTitleClickTime = 0
                        WindowManager.lastTitleClickWin = nil
                        return true
                    else
                        WindowManager.lastTitleClickTime = now
                        WindowManager.lastTitleClickWin = win
                    end

                    -- Start Dragging
                    WindowManager.draggingWindow = win
                    if win.isMaximized then
                        win.isMaximized = false
                        local prevW = win.preMaxW or 560
                        local prevH = win.preMaxH or 350
                        local ratioX = math.max(0.1, math.min(0.9, x / win.width))
                        win.width = prevW
                        win.height = prevH
                        win.x = math.max(0, math.floor(x - (win.width * ratioX)))
                        win.y = math.max(0, y - 15)
                        if win.instance and win.instance.resize then
                            pcall(function() win.instance:resize(win.width, win.height - titleH) end)
                        end
                    end
                    WindowManager.dragOffsetX = x - win.x
                    WindowManager.dragOffsetY = y - win.y
                    return true
                end

                -- Resize handle (Bottom-Right)
                if x >= win.x + win.width - 18 and y >= win.y + win.height - 18 then
                    WindowManager.resizingWindow = win
                    WindowManager.resizeOffsetX = win.width - x
                    WindowManager.resizeOffsetY = win.height - y
                    return true
                end

                -- Relative and absolute coordinate pass-through
                local contentY = win.y + titleH
                local relX = x - win.x
                local relY = y - contentY
                if win.instance and win.instance.mousepressed then
                    pcall(function()
                        win.instance:mousepressed(relX, relY, button, x, y)
                    end)
                end
                return true
            end
        end
    end
    return false
end

function WindowManager.mousemoved(x, y, dx, dy)
    local titleH = WindowManager.titleBarHeight

    if WindowManager.draggingWindow then
        WindowManager.draggingWindow.x = x - WindowManager.dragOffsetX
        WindowManager.draggingWindow.y = y - WindowManager.dragOffsetY
        return true
    end

    if WindowManager.resizingWindow then
        local win = WindowManager.resizingWindow
        local newW = math.max(WindowManager.minWidth, x + WindowManager.resizeOffsetX)
        local newH = math.max(WindowManager.minHeight, y + WindowManager.resizeOffsetY)
        win.width = newW
        win.height = newH
        win.isMaximized = false
        if win.instance and win.instance.resize then
            pcall(function()
                win.instance:resize(win.width, win.height - titleH)
            end)
        end
        return true
    end

    if WindowManager.focusedWindow and not WindowManager.focusedWindow.minimized then
        local win = WindowManager.focusedWindow
        local contentY = win.y + titleH
        local relX = x - win.x
        local relY = y - contentY
        if win.instance and win.instance.mousemoved then
            pcall(function()
                win.instance:mousemoved(relX, relY, dx, dy, x, y)
            end)
        end
    end
    return false
end

function WindowManager.mousereleased(x, y, button)
    local titleH = WindowManager.titleBarHeight

    if WindowManager.draggingWindow then
        WindowManager.draggingWindow = nil
        return true
    end
    if WindowManager.resizingWindow then
        WindowManager.resizingWindow = nil
        return true
    end
    if WindowManager.focusedWindow and not WindowManager.focusedWindow.minimized then
        local win = WindowManager.focusedWindow
        local contentY = win.y + titleH
        local relX = x - win.x
        local relY = y - contentY
        if win.instance and win.instance.mousereleased then
            pcall(function()
                win.instance:mousereleased(relX, relY, button, x, y)
            end)
        end
    end
    return false
end

function WindowManager.wheelmoved(x, y)
    if WindowManager.focusedWindow and not WindowManager.focusedWindow.minimized then
        local win = WindowManager.focusedWindow
        if win.instance and win.instance.wheelmoved then
            pcall(function()
                win.instance:wheelmoved(x, y)
            end)
        end
    end
end

function WindowManager.textinput(text)
    if WindowManager.focusedWindow and not WindowManager.focusedWindow.minimized then
        local win = WindowManager.focusedWindow
        if win.instance and win.instance.textinput then
            pcall(function()
                win.instance:textinput(text)
            end)
        end
    end
end

function WindowManager.keypressed(key)
    if WindowManager.focusedWindow and not WindowManager.focusedWindow.minimized then
        local win = WindowManager.focusedWindow
        if win.instance and win.instance.keypressed then
            pcall(function()
                win.instance:keypressed(key)
            end)
        end
    end
end

return WindowManager