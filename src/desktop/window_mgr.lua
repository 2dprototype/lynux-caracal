-- src/desktop/window_mgr.lua
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
    minWidth = 360,
    minHeight = 240,
    titleBarHeight = 30,
    font = nil
}

function WindowManager.init()
    WindowManager.openApps = {}
    WindowManager.focusedWindow = nil
    WindowManager.draggingWindow = nil
    WindowManager.resizingWindow = nil
    WindowManager.font = love.graphics.newFont("font/Nunito-Regular.ttf", 13) or love.graphics.newFont(13)
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
    defaultW = defaultW or 540
    defaultH = defaultH or 340
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local x = (screenW - defaultW) / 2 + (#WindowManager.openApps * 20) % 80
    local y = 35 + ((screenH - 75 - defaultH) / 2) + (#WindowManager.openApps * 20) % 60

    local newWindow = {
        app = app,
        instance = app.instance,
        x = x,
        y = y,
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

            -- Subtle Minimalist Drop Shadow
            love.graphics.setColor(0, 0, 0, isFocused and 0.35 or 0.18)
            love.graphics.rectangle("fill", win.x + 3, win.y + 3, win.width, win.height, 6, 6)

            -- Window Body Background (Clean Warm Slate)
            love.graphics.setColor(0.12, 0.11, 0.15)
            love.graphics.rectangle("fill", win.x, win.y, win.width, win.height, 6, 6)

            -- Title Bar (Warm Retro Toast / Charcoal)
            if isFocused then
                love.graphics.setColor(0.18, 0.16, 0.22)
            else
                love.graphics.setColor(0.14, 0.13, 0.17)
            end
            love.graphics.rectangle("fill", win.x, win.y, win.width, titleH, 6, 6)
            love.graphics.rectangle("fill", win.x, win.y + titleH - 6, win.width, 6)

            -- Title Bar Separator Line
            love.graphics.setColor(1.0, 0.82, 0.25, isFocused and 0.5 or 0.2)
            love.graphics.line(win.x, win.y + titleH, win.x + win.width, win.y + titleH)

            -- Kawaii Retro Window Controls (Left side: Pastel Strawberry, Lemon, Mint)
            local btnCloseX = win.x + 12
            local btnMinX = win.x + 28
            local btnMaxX = win.x + 44
            local btnY = win.y + 15

            -- Close Button (Kawaii Strawberry Pink)
            love.graphics.setColor(1.0, 0.44, 0.65, isFocused and 1.0 or 0.6)
            love.graphics.circle("fill", btnCloseX, btnY, 5)

            -- Minimize Button (Sunny Lemon Yellow)
            love.graphics.setColor(1.0, 0.85, 0.3, isFocused and 1.0 or 0.6)
            love.graphics.circle("fill", btnMinX, btnY, 5)

            -- Maximize / Active Dot (Pastel Soda Mint)
            love.graphics.setColor(0.2, 0.88, 0.55, isFocused and 1.0 or 0.4)
            love.graphics.circle("fill", btnMaxX, btnY, 5)

            -- App Icon & Title
            if win.app and win.app.icon then
                love.graphics.setColor(1, 1, 1, isFocused and 0.95 or 0.6)
                love.graphics.draw(win.app.icon, win.x + 64, win.y + 7, 0, 16 / win.app.icon:getWidth(), 16 / win.app.icon:getHeight())
            end

            love.graphics.setFont(WindowManager.font)
            love.graphics.setColor(isFocused and {1.0, 0.96, 0.88} or {0.65, 0.62, 0.7})
            local titleText = (win.app and win.app.name) or "Application"
            love.graphics.print(titleText, win.x + 86, win.y + 6)

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

            -- Clean Retro Border (Sunny Yellow Highlight when focused!)
            if isFocused then
                love.graphics.setColor(1.0, 0.82, 0.25, 0.95) -- Sunny Yellow
                love.graphics.setLineWidth(1.5)
            else
                love.graphics.setColor(0.25, 0.22, 0.3, 0.6)
                love.graphics.setLineWidth(1)
            end
            love.graphics.rectangle("line", win.x, win.y, win.width, win.height, 6, 6)

            -- Resize corner grip
            love.graphics.setColor(1.0, 0.82, 0.25, isFocused and 0.6 or 0.2)
            local rx = win.x + win.width
            local ry = win.y + win.height
            love.graphics.line(rx - 10, ry - 2, rx - 2, ry - 10)
            love.graphics.line(rx - 6, ry - 2, rx - 2, ry - 6)

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
                    local btnCloseX = win.x + 12
                    local btnMinX = win.x + 28
                    
                    if math.abs(x - btnCloseX) <= 8 and math.abs(y - (win.y + 15)) <= 8 then
                        WindowManager.closeWindow(win)
                        return true
                    end
                    if math.abs(x - btnMinX) <= 8 and math.abs(y - (win.y + 15)) <= 8 then
                        win.minimized = true
                        return true
                    end

                    WindowManager.draggingWindow = win
                    WindowManager.dragOffsetX = x - win.x
                    WindowManager.dragOffsetY = y - win.y
                    return true
                end

                if x >= win.x + win.width - 16 and y >= win.y + win.height - 16 then
                    WindowManager.resizingWindow = win
                    WindowManager.resizeOffsetX = win.width - x
                    WindowManager.resizeOffsetY = win.height - y
                    return true
                end

                -- Relative coordinate pass-through
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
