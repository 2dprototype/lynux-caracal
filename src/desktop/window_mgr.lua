-- src/desktop/window_mgr.lua
-- Windows 10 Style Window Manager with standard titlebar and controls

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
    titleBarHeight = 30,
    font = nil,
    hoveredBtn = nil -- "close", "min", "max"
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
    WindowManager.font = loadCustomFont("font/x14y24pxHeadUpDaisy.ttf", 18)
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

function WindowManager.openWindow(app, defaultW, defaultH)
    defaultW = defaultW or 560
    defaultH = defaultH or 350
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local x = (screenW - defaultW) / 2 + (#WindowManager.openApps * 20) % 80
    local y = 35 + ((screenH - 75 - defaultH) / 2) + (#WindowManager.openApps * 20) % 60

    local newWindow = {
        app = app,
        instance = app.instance,
        x = math.floor(x),
        y = math.floor(y),
        width = defaultW,
        height = defaultH,
        minimized = false
    }
    table.insert(WindowManager.openApps, newWindow)
    WindowManager.setFocus(newWindow)
    AudioManager.playSFX("click")
    EventBus.emit("window:opened", { app = app, window = newWindow })
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
            EventBus.emit("window:closed", { app = window.app, window = window })
            break
        end
    end
end

function WindowManager.toggleApp(app)
    local found = nil
    for _, win in ipairs(WindowManager.openApps) do
        if win.app == app then
            found = win
            break
        end
    end

    if found then
        found.minimized = not found.minimized
        if not found.minimized then
            WindowManager.setFocus(found)
        end
    else
        if not app.instance then
            if app.module and app.module.new then
                app.instance = app.module.new()
            end
        end
        WindowManager.openWindow(app)
    end
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

            -- Subtle Windows Drop Shadow
            love.graphics.setColor(0, 0, 0, isFocused and 0.35 or 0.18)
            love.graphics.rectangle("fill", win.x + 2, win.y + 2, win.width, win.height)

            -- Window Body (Clean Dark / Neutral surface)
            love.graphics.setColor(0.12, 0.12, 0.14)
            love.graphics.rectangle("fill", win.x, win.y, win.width, win.height)

            -- Windows 10 Title Bar
            if isFocused then
                love.graphics.setColor(0.18, 0.18, 0.2)
            else
                love.graphics.setColor(0.14, 0.14, 0.16)
            end
            love.graphics.rectangle("fill", win.x, win.y, win.width, titleH)

            -- Titlebar Separator
            love.graphics.setColor(0.25, 0.25, 0.28)
            love.graphics.line(win.x, win.y + titleH, win.x + win.width, win.y + titleH)

            -- App Icon & Title on the Left
            if win.app and win.app.icon then
                love.graphics.setColor(1, 1, 1, isFocused and 0.95 or 0.6)
                love.graphics.draw(win.app.icon, win.x + 8, win.y + 7, 0, 16 / win.app.icon:getWidth(), 16 / win.app.icon:getHeight())
            end

            love.graphics.setFont(WindowManager.font)
            love.graphics.setColor(isFocused and {0.96, 0.96, 0.96} or {0.65, 0.65, 0.65})
            local titleText = (win.app and win.app.name) or "Application"
            love.graphics.print(titleText, win.x + 30, win.y + 6)

            -- Windows 10 Top-Right Controls: [ _ ] [ □ ] [ ✕ ]
            local btnCloseW = 42
            local btnOtherW = 36
            local closeX = win.x + win.width - btnCloseW
            local maxX = closeX - btnOtherW
            local minX = maxX - btnOtherW

            -- Minimize Button
            love.graphics.setColor(0.8, 0.8, 0.8, isFocused and 0.9 or 0.5)
            love.graphics.line(minX + 13, win.y + 16, minX + 23, win.y + 16)

            -- Maximize Button
            love.graphics.rectangle("line", maxX + 13, win.y + 10, 10, 10)

            -- Close Button (Standard Windows 10 Red Hover when active/closed)
            love.graphics.line(closeX + 16, win.y + 10, closeX + 26, win.y + 20)
            love.graphics.line(closeX + 26, win.y + 10, closeX + 16, win.y + 20)

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

            -- 1px Flat Windows Border (Accent Blue when focused, subtle grey when inactive)
            if isFocused then
                love.graphics.setColor(0.0, 0.47, 0.83, 0.9) -- Windows 10 Accent Blue
            else
                love.graphics.setColor(0.24, 0.24, 0.26, 0.7)
            end
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", win.x, win.y, win.width, win.height)

            love.graphics.pop()
        end
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
                    local btnCloseW = 42
                    local btnOtherW = 36
                    local closeX = win.x + win.width - btnCloseW
                    local maxX = closeX - btnOtherW
                    local minX = maxX - btnOtherW

                    -- Close button click
                    if x >= closeX and x <= win.x + win.width then
                        WindowManager.closeWindow(win)
                        return true
                    end
                    -- Maximize toggle
                    if x >= maxX and x < closeX then
                        -- Optional toggle or ignore
                        return true
                    end
                    -- Minimize button click
                    if x >= minX and x < maxX then
                        win.minimized = true
                        return true
                    end

                    -- Start Dragging
                    WindowManager.draggingWindow = win
                    WindowManager.dragOffsetX = x - win.x
                    WindowManager.dragOffsetY = y - win.y
                    return true
                end

                -- Resize handle (Bottom right corner)
                if x >= win.x + win.width - 16 and y >= win.y + win.height - 16 then
                    WindowManager.resizingWindow = win
                    WindowManager.resizeOffsetX = win.width - x
                    WindowManager.resizeOffsetY = win.height - y
                    return true
                end

                -- Relative coordinate pass-through to app instance
                local contentY = win.y + titleH
                local relX = x - win.x
                local relY = y - contentY
                if win.instance and win.instance.mousepressed then
                    pcall(function()
                        win.instance:mousepressed(relX, relY, button)
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
        local newW = math.max(WindowManager.minWidth, x + WindowManager.resizeOffsetX)
        local newH = math.max(WindowManager.minHeight, y + WindowManager.resizeOffsetY)
        WindowManager.resizingWindow.width = newW
        WindowManager.resizingWindow.height = newH
        return true
    end

    if WindowManager.focusedWindow and not WindowManager.focusedWindow.minimized then
        local win = WindowManager.focusedWindow
        local contentY = win.y + titleH
        local relX = x - win.x
        local relY = y - contentY
        if win.instance and win.instance.mousemoved then
            pcall(function()
                win.instance:mousemoved(relX, relY, dx, dy)
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
                win.instance:mousereleased(relX, relY, button)
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
