-- main.lua
local json = require "lib/json"
local moonshine = require 'lib/moonshine'
local EmailApp = require("email")
local BrowserApp = require("browser")
local FilesApp = require("files")
local TerminalApp = require("terminal") 
local RouletteApp = require("roulette")
local TextEditor = require("texteditor")
local DinoApp = require("dino")
local TessarectApp = require("tessarect")
local ImageViewer = require("imageviewer")
local ObjViewer = require("objviewer")
local NexusAI = require("nexusai")
local SettingsApp = require("settings")
local PokerApp = require("poker")
local filesystemModule = require("filesystem")

effect = moonshine(moonshine.effects.scanlines).chain(moonshine.effects.crt)
effect.scanlines.opacity = 0.6

focusedWindow = nil  -- global variable tracking the focused window

-- Constants for window resizing.
local MIN_WINDOW_WIDTH = 300
local MIN_WINDOW_HEIGHT = 200
local MAX_WINDOW_WIDTH = 1000
local MAX_WINDOW_HEIGHT = 800

local draggingWindow = nil
local dragOffsetX = 0
local dragOffsetY = 0

local resizingWindow = nil
local resizeOffsetX = 0
local resizeOffsetY = 0
local effectEnabled = false
local screenWidth = love.graphics.getWidth()
local screenHeight = love.graphics.getHeight()

desktopHomeIcons = {}
desktopLayout = {}
draggingIcon = nil
dragIconOffsetX = 0
dragIconOffsetY = 0
startMenuOpen = false
ellipsisMenuOpen = false
visibleApps = {}
hiddenApps = {}

-- Desktop context menu
local contextMenuOpen = false
local contextMenuX = 0
local contextMenuY = 0
local contextMenuItems = {
    {text = "New Folder", action = "new_folder"},
    {text = "New Text File", action = "new_file"},
    {text = "New Shortcut", action = "new_shortcut"},
    {text = "Change Wallpaper", action = "change_wallpaper"},
    {text = "Settings", action = "open_settings"},
    {text = "Refresh", action = "refresh"}
}

-- Wallpaper system
local wallpapers = {}
local currentWallpaper = {
    type = "color",
    color = {0.15, 0.25, 0.35},
    gradient = {
        top = {0.15, 0.25, 0.35},
        bottom = {0.25, 0.35, 0.45}
    },
    image = nil
}

-- Start menu scroll variables
local startMenuScroll = 0
local startMenuMaxScroll = 0
local scrollBarHeight = 0
local scrollBarDragging = false
local scrollBarDragOffset = 0

-- Utility function to set focus on a window.
local function setFocus(window)
    for i, win in ipairs(openApps) do
        if win == window then
            table.remove(openApps, i)
            break
        end
    end
    table.insert(openApps, window)
    focusedWindow = window
end

-- Load desktop config
local function loadDesktopConfig()
    if love.filesystem.getInfo("desktop_config.json") then
        local data = love.filesystem.read("desktop_config.json")
        local config = json.decode(data) or {}

        if config.wallpaper then
            currentWallpaper.type = config.wallpaper.type

            if config.wallpaper.type == "color" then
                currentWallpaper.color = config.wallpaper.color

            elseif config.wallpaper.type == "gradient" then
                currentWallpaper.gradient = config.wallpaper.gradient

            elseif config.wallpaper.type == "image" then
                if config.wallpaper.filename then
                    -- Reload image from saved path
                    currentWallpaper.image = love.graphics.newImage("wallpaper/" .. config.wallpaper.filename)
                    currentWallpaper.filename = config.wallpaper.filename
                end
            end
        end
    end
end


-- Save desktop config
local function saveDesktopConfig()
    local config = {
        wallpaper = {
            type = currentWallpaper.type,
            color = currentWallpaper.color,
            gradient = currentWallpaper.gradient,
            filename = currentWallpaper.filename  -- saves image reference safely
        }
    }

    love.filesystem.write("desktop_config.json", json.encode(config))
end


-- Load available wallpapers
local function loadWallpapers()
    wallpapers = {}
    -- Add color wallpapers
    table.insert(wallpapers, {
        name = "Blue",
        type = "color",
        color = {0.15, 0.25, 0.35}
    })
    table.insert(wallpapers, {
        name = "Dark Gray",
        type = "color", 
        color = {0.1, 0.1, 0.1}
    })
    table.insert(wallpapers, {
        name = "Green",
        type = "color",
        color = {0.1, 0.3, 0.2}
    })
    
    -- Add gradient wallpapers
    table.insert(wallpapers, {
        name = "Blue Gradient",
        type = "gradient",
        gradient = {
            top = {0.15, 0.25, 0.35},
            bottom = {0.25, 0.35, 0.45}
        }
    })
    table.insert(wallpapers, {
        name = "Sunset",
        type = "gradient",
        gradient = {
            top = {0.8, 0.2, 0.2},
            bottom = {0.2, 0.1, 0.4}
        }
    })
    
    -- Load image wallpapers from /wallpaper/ folder
    if love.filesystem.getInfo("wallpaper") then
        local wallpaperFiles = love.filesystem.getDirectoryItems("wallpaper")
        for _, filename in ipairs(wallpaperFiles) do
            local ext = filename:match("^.+(%..+)$")
            if ext then
                ext = ext:lower()
                if ext == ".png" or ext == ".jpg" or ext == ".jpeg" then
                    local success, image = pcall(love.graphics.newImage, "wallpaper/" .. filename)
                    if success then
                        table.insert(wallpapers, {
                            name = filename:gsub("%..+$", ""),
                            type = "image",
                            image = image,
                            filename = filename
                        })
                    end
                end
            end
        end
    end
end

-- Draw wallpaper based on current settings
local function drawWallpaper()
    if currentWallpaper.type == "color" then
        love.graphics.setColor(currentWallpaper.color)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    elseif currentWallpaper.type == "gradient" then
        -- Simple gradient implementation
        for y = 0, screenHeight do
            local ratio = y / screenHeight
            local r = currentWallpaper.gradient.top[1] * (1 - ratio) + currentWallpaper.gradient.bottom[1] * ratio
            local g = currentWallpaper.gradient.top[2] * (1 - ratio) + currentWallpaper.gradient.bottom[2] * ratio
            local b = currentWallpaper.gradient.top[3] * (1 - ratio) + currentWallpaper.gradient.bottom[3] * ratio
            love.graphics.setColor(r, g, b)
            love.graphics.line(0, y, screenWidth, y)
        end
	elseif currentWallpaper.type == "image" and currentWallpaper.image then
		love.graphics.setColor(1, 1, 1)

		local img = currentWallpaper.image
		local imgW, imgH = img:getWidth(), img:getHeight()

		-- Uniform scale to cover screen (no stretch, may crop)
		local scale = math.max(screenWidth / imgW, screenHeight / imgH)

		-- Center image
		local drawX = (screenWidth - imgW * scale) / 2
		local drawY = (screenHeight - imgH * scale) / 2

		love.graphics.draw(img, drawX, drawY, 0, scale, scale)
    else
        -- Fallback
        love.graphics.setColor(0.15, 0.25, 0.35)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    end
end

-- Create new folder in desktop home
local function createNewFolder(name)
    if not name or name == "" then
        name = "New Folder"
    end
    
    -- Ensure unique name
    local baseName = name
    local counter = 1
    while desktopHome.children[name] do
        name = baseName .. " (" .. counter .. ")"
        counter = counter + 1
    end
    
    desktopHome.children[name] = {
        name = name,
        type = "directory",
        parent = desktopHome,
        children = {}
    }
    
    -- Update layout
    local startX = 10
    local startY = topBarHeight + 10
    local iconSize = 40
    local padding = 20
    local index = #desktopHomeIcons + 1
    local col = (index - 1) % 4
    local row = math.floor((index - 1) / 4)
    local x = startX + col * (iconSize + padding)
    local y = startY + row * (iconSize + padding)
    
    desktopLayout[name] = {x = x, y = y}
    
    -- Save filesystem
    filesystemModule.save(filesystemModule.getFS())
end

-- Create new file in desktop home
local function createNewFile(name)
    if not name or name == "" then
        name = "New File.txt"
    elseif not name:match("%..+$") then
        name = name .. ".txt"
    end
    
    -- Ensure unique name
    local baseName = name:gsub("%..+$", "")
    local ext = name:match("(%..+)$") or ""
    local counter = 1
    while desktopHome.children[name] do
        name = baseName .. " (" .. counter .. ")" .. ext
        counter = counter + 1
    end
    
    desktopHome.children[name] = {
        name = name,
        type = "file",
        parent = desktopHome,
        content = ""
    }
    
    -- Update layout
    local startX = 10
    local startY = topBarHeight + 10
    local iconSize = 40
    local padding = 20
    local index = #desktopHomeIcons + 1
    local col = (index - 1) % 4
    local row = math.floor((index - 1) / 4)
    local x = startX + col * (iconSize + padding)
    local y = startY + row * (iconSize + padding)
    
    desktopLayout[name] = {x = x, y = y}
    
    -- Save filesystem
    filesystemModule.save(filesystemModule.getFS())
end

-- Create new shortcut in desktop home
local function createNewShortcut(name)
    if not name or name == "" then
        name = "New Shortcut.lnk"
    elseif not name:match("%.lnk$") then
        name = name .. ".lnk"
    end
    
    local baseName = name:gsub("%.lnk$", "")
    local counter = 1
    while desktopHome.children[name] do
        name = baseName .. " (" .. counter .. ").lnk"
        counter = counter + 1
    end
    
    desktopHome.children[name] = {
        name = name,
        type = "file",
        parent = desktopHome,
        content = "target=/"
    }
    
    local startX = 10
    local startY = topBarHeight + 10
    local iconSize = 40
    local padding = 20
    local index = #desktopHomeIcons + 1
    local col = (index - 1) % 4
    local row = math.floor((index - 1) / 4)
    local x = startX + col * (iconSize + padding)
    local y = startY + row * (iconSize + padding)
    
    desktopLayout[name] = {x = x, y = y}
    filesystemModule.save(filesystemModule.getFS())
end

-- Draw context menu
local function drawContextMenu()
    local menuWidth = 220
    local itemHeight = 32
    local menuPadding = 4
    local menuHeight = #contextMenuItems * itemHeight + (menuPadding * 2)
    
    -- Menu background (Windows 10 Dark Mode)
    love.graphics.setColor(0.17, 0.17, 0.17, 0.98)
    love.graphics.rectangle("fill", contextMenuX, contextMenuY, menuWidth, menuHeight)
    
    -- Subtle Border
    love.graphics.setColor(0.3, 0.3, 0.3, 1.0)
    love.graphics.rectangle("line", contextMenuX, contextMenuY, menuWidth, menuHeight)
    
    -- Menu items
    for i, item in ipairs(contextMenuItems) do
        local itemY = contextMenuY + menuPadding + (i-1) * itemHeight
        
        -- Highlight on hover
        local mouseX, mouseY = love.mouse.getPosition()
        local isHovered = mouseX >= contextMenuX and mouseX <= contextMenuX + menuWidth and
                          mouseY >= itemY and mouseY <= itemY + itemHeight
                          
        if isHovered then
            love.graphics.setColor(0.3, 0.3, 0.3, 1.0)
            love.graphics.rectangle("fill", contextMenuX + 2, itemY, menuWidth - 4, itemHeight)
        end
        
        love.graphics.setColor(0.95, 0.95, 0.95)
        love.graphics.print(item.text, contextMenuX + 32, itemY + 8)
    end
end

-- Handle context menu actions
local function handleContextMenuAction(action)
    if action == "new_folder" then
        createNewFolder()
    elseif action == "new_file" then
        createNewFile()
    elseif action == "new_shortcut" then
        createNewShortcut()
    elseif action == "change_wallpaper" then
        -- Open Settings app to wallpaper section
        for i, app in ipairs(apps) do
            if app.name == "Settings" then
                if not app.instance then
                    app.instance = app.module.new(wallpapers, currentWallpaper, function(wallpaper)
                        currentWallpaper = wallpaper
                        saveDesktopConfig()
                    end)
                else
                    app.instance:setWallpaperTab()
                end
                toggleApp(app)
                break
            end
        end
    elseif action == "open_settings" then
        for i, app in ipairs(apps) do
            if app.name == "Settings" then
                toggleApp(app)
                break
            end
        end
    elseif action == "refresh" then
        -- Refresh desktop (reload icons)
        -- This is handled automatically in drawDesktopHome
    end
end

-- Draw the desktop and also draw the home folder icons.
function drawDesktop()
    love.graphics.setFont(font)
    
    -- Draw the desktop "home" area.
    drawDesktopHome()
    
    -- Draw bottom bar (taskbar)
    love.graphics.setColor(0.1, 0.1, 0.12, 0.95)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - bottomBarHeight, love.graphics.getWidth(), bottomBarHeight)
    
    -- Draw start button
    local startBtnWidth = 48
    if love.mouse.getX() >= 0 and love.mouse.getX() <= startBtnWidth and love.mouse.getY() >= love.graphics.getHeight() - bottomBarHeight then
        love.graphics.setColor(0.2, 0.2, 0.25, 0.95)
    else
        love.graphics.setColor(0.15, 0.15, 0.18, 0.95)
    end
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - bottomBarHeight, startBtnWidth, bottomBarHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(startIcon, (startBtnWidth - 24) / 2, love.graphics.getHeight() - bottomBarHeight + (bottomBarHeight - 24) / 2, 0, 24/startIcon:getWidth(), 24/startIcon:getHeight())
    
    -- Draw date and time on taskbar (right side)
    love.graphics.setColor(0.9, 0.9, 0.9)
    local currentTime = os.date("%H:%M")
    local currentDate = os.date("%Y-%m-%d")
    local timeWidth = font:getWidth(currentTime)
    local dateWidth = font:getWidth(currentDate)
    local maxTextWidth = math.max(timeWidth, dateWidth)
    local dateTimeX = love.graphics.getWidth() - maxTextWidth - 10
    love.graphics.print(currentTime, dateTimeX + (maxTextWidth - timeWidth) / 2, love.graphics.getHeight() - bottomBarHeight + 4)
    love.graphics.print(currentDate, dateTimeX + (maxTextWidth - dateWidth) / 2, love.graphics.getHeight() - bottomBarHeight + 20)
    
    -- Draw visible app icons on taskbar
    for _, app in ipairs(visibleApps) do
        local state = "closed"
        local isFocused = false
        for _, window in ipairs(openApps) do
            if window.app == app then
                if window == focusedWindow and not window.minimized then
                    isFocused = true
                end
                if window.minimized then
                    state = "minimized"
                else
                    state = "maximized"
                end
                break
            end
        end
        
        local iconMargin = 6
        local targetIconHeight = bottomBarHeight - iconMargin * 2
        local scale = targetIconHeight / app.icon:getHeight()
        local iconSize = targetIconHeight
        local btnWidth = iconSize + iconMargin * 2 + 10
        local isHovered = love.mouse.getX() >= app.x and love.mouse.getX() <= app.x + btnWidth and love.mouse.getY() >= love.graphics.getHeight() - bottomBarHeight

        -- draw taskbar button background
        if isFocused then
            love.graphics.setColor(0.3, 0.3, 0.35, 0.8)
        elseif isHovered then
            love.graphics.setColor(0.25, 0.25, 0.3, 0.8)
        elseif state ~= "closed" then
            love.graphics.setColor(0.2, 0.2, 0.25, 0.5)
        else
            love.graphics.setColor(0, 0, 0, 0)
        end
        love.graphics.rectangle("fill", app.x, love.graphics.getHeight() - bottomBarHeight, btnWidth, bottomBarHeight)
        
        -- Active indicator line (Windows 10 style)
        if state ~= "closed" then
            if isFocused then
                love.graphics.setColor(0.4, 0.6, 1.0)
                love.graphics.rectangle("fill", app.x + 4, love.graphics.getHeight() - 3, btnWidth - 8, 3)
            else
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.rectangle("fill", app.x + 8, love.graphics.getHeight() - 3, btnWidth - 16, 3)
            end
        end

        -- draw the icon
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(app.icon, app.x + 5 + iconMargin, love.graphics.getHeight() - bottomBarHeight + iconMargin, 0, scale, scale)
    end
    
    -- Draw ellipsis button if there are hidden apps
    if #hiddenApps > 0 then
        local ellipsisX = love.graphics.getWidth() - 40
        love.graphics.setColor(0.15, 0.15, 0.2)
        love.graphics.rectangle("fill", ellipsisX, love.graphics.getHeight() - bottomBarHeight, 40, bottomBarHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(ellipsisIcon, ellipsisX + 10, love.graphics.getHeight() - bottomBarHeight + (bottomBarHeight - 30) / 2, 0, 30/ellipsisIcon:getWidth(), 30/ellipsisIcon:getHeight())
    end

    -- Draw ellipsis menu if open
    if ellipsisMenuOpen then
        love.graphics.setColor(0.15, 0.15, 0.2, 0.95)
        local menuX = love.graphics.getWidth() - 160
        local menuY = love.graphics.getHeight() - bottomBarHeight - #hiddenApps * 40 - 10
        local menuWidth = 150
        local menuHeight = #hiddenApps * 40 + 10
        love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight)
        love.graphics.setColor(0.7, 0.8, 1.0)
        love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight)
        
        for i, app in ipairs(hiddenApps) do
            local appY = menuY + 5 + (i-1)*40
            love.graphics.setColor(0.3, 0.4, 0.5)
            love.graphics.rectangle("fill", menuX + 5, appY, 140, 35)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(app.icon, menuX + 10, appY + 5, 0, 25/app.icon:getWidth(), 25/app.icon:getHeight())
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(app.name, menuX + 40, appY + 10)
        end
    end
    
    -- Draw start menu if open
    if startMenuOpen then
        local menuWidth = 400
        local menuHeight = 450
        local menuX = 0
        local menuY = love.graphics.getHeight() - bottomBarHeight - menuHeight
        local sidebarWidth = 48
        
        -- Calculate content height
        local cols = 3
        local iconSize = 90
        local padding = 10
        local rows = math.ceil(#apps / cols)
        local contentHeight = rows * (iconSize + padding) + padding
        
        -- Update max scroll
        startMenuMaxScroll = math.max(0, contentHeight - menuHeight)
        
        -- Background (Main)
        love.graphics.setColor(0.12, 0.12, 0.12, 0.98)
        love.graphics.rectangle("fill", menuX + sidebarWidth, menuY, menuWidth - sidebarWidth, menuHeight)
        
        -- Background (Sidebar)
        love.graphics.setColor(0.1, 0.1, 0.1, 0.98)
        love.graphics.rectangle("fill", menuX, menuY, sidebarWidth, menuHeight)
        
        -- Border
        love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
        love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight)
        
        -- Sidebar icons (Power, Settings, User etc.)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("fill", menuX + 16, menuY + menuHeight - 40, 16, 16) -- Power
        love.graphics.rectangle("fill", menuX + 16, menuY + menuHeight - 80, 16, 16) -- Settings
        love.graphics.circle("fill", menuX + 24, menuY + menuHeight - 120, 8) -- User
        
        -- Set scissor for content area
        love.graphics.setScissor(menuX + sidebarWidth, menuY, menuWidth - sidebarWidth, menuHeight)
        love.graphics.setFont(font)
        
        -- Draw apps in grid with scroll offset
        for i, app in ipairs(apps) do
            local col = (i-1) % cols
            local row = math.floor((i-1) / cols)
            local x = menuX + sidebarWidth + padding + col * (iconSize + padding)
            local y = menuY + padding + row * (iconSize + padding) - startMenuScroll
            
            local isHovered = love.mouse.getX() >= x and love.mouse.getX() <= x + iconSize and love.mouse.getY() >= y and love.mouse.getY() <= y + iconSize
            
            if isHovered then
                love.graphics.setColor(0.1, 0.35, 0.6) -- Windows Blue hover
            else
                love.graphics.setColor(0, 0.47, 0.84) -- Windows Blue tile
            end
            love.graphics.rectangle("fill", x, y, iconSize, iconSize)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(app.icon, x + (iconSize - 32)/2, y + 15, 0, 32/app.icon:getWidth(), 32/app.icon:getHeight())
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(app.name, x, y + 55, iconSize, "center")
        end
        
        love.graphics.setScissor()
        
        -- Draw scrollbar if needed
        if startMenuMaxScroll > 0 then
            local scrollBarWidth = 4
            local scrollBarX = menuX + menuWidth - scrollBarWidth - 2
            local scrollTrackHeight = menuHeight
            scrollBarHeight = (menuHeight / contentHeight) * scrollTrackHeight
            
            -- Scroll track
            love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
            love.graphics.rectangle("fill", scrollBarX, menuY, scrollBarWidth, scrollTrackHeight)
            
            -- Scroll thumb
            local scrollThumbY = menuY + (startMenuScroll / startMenuMaxScroll) * (scrollTrackHeight - scrollBarHeight)
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
            if scrollBarDragging then love.graphics.setColor(0.5, 0.5, 0.5, 0.8) end
            love.graphics.rectangle("fill", scrollBarX, scrollThumbY, scrollBarWidth, scrollBarHeight)
        end
    end

    -- Draw open app windows.
    for _, window in ipairs(openApps) do
        if not window.minimized then
            love.graphics.setFont(font)
            local titleBarHeight = 30
            
            -- Window content background
            love.graphics.setColor(0.9, 0.9, 0.95)
            love.graphics.rectangle("fill", window.x, window.y, window.width, window.height)
            
            -- Title bar
            if window == focusedWindow then
                love.graphics.setColor(0.15, 0.15, 0.18, 1) -- Active window title bar (Windows 10 dark mode)
            else
                love.graphics.setColor(0.2, 0.2, 0.25, 0.95) -- Inactive window
            end
            love.graphics.rectangle("fill", window.x, window.y, window.width, titleBarHeight)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(window.app.name, window.x + 10, window.y + (titleBarHeight - 13)/2)
            
            local btnSize = 40
            local closeX = window.x + window.width - btnSize
            local maxX = window.x + window.width - 2 * btnSize
            local minX = window.x + window.width - 3 * btnSize
            
            -- Close button
            love.graphics.setColor(0.9, 0.2, 0.2)
            love.graphics.rectangle("fill", closeX, window.y, btnSize, titleBarHeight)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("X", closeX, window.y + (titleBarHeight - 13)/2, btnSize, "center")
            
            -- Maximize button
            love.graphics.setColor(0.25, 0.25, 0.3)
            love.graphics.rectangle("fill", maxX, window.y, btnSize, titleBarHeight)
            love.graphics.setColor(1, 1, 1)
            if window.maximized then
                love.graphics.printf("[-]", maxX, window.y + (titleBarHeight - 13)/2, btnSize, "center")
            else
                love.graphics.printf("[+]", maxX, window.y + (titleBarHeight - 13)/2, btnSize, "center")
            end
            
            -- Minimize button
            love.graphics.setColor(0.3, 0.3, 0.35)
            love.graphics.rectangle("fill", minX, window.y, btnSize, titleBarHeight)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("_", minX, window.y + (titleBarHeight - 13)/2, btnSize, "center")
            
            -- Scissor and draw content
            if window.instance and window.instance.draw then
                love.graphics.setColor(1, 1, 1)
                love.graphics.setScissor(window.x, window.y + titleBarHeight, window.width, window.height - titleBarHeight)
                love.graphics.push()
                window.instance:draw(window.x, window.y + titleBarHeight, window.width, window.height - titleBarHeight)
                love.graphics.pop()
                love.graphics.setScissor()
            else
                love.graphics.setColor(0, 0, 0)
                love.graphics.print("Content of " .. window.app.name, window.x + 10, window.y + titleBarHeight + 10)
            end
            
            -- Resize handle (only if not maximized)
            if not window.maximized then
                local handleSize = 12
                love.graphics.setColor(0.5, 0.6, 0.7)
                love.graphics.polygon("fill", 
                    window.x + window.width, window.y + window.height - handleSize,
                    window.x + window.width - handleSize, window.y + window.height,
                    window.x + window.width, window.y + window.height
                )
            end
            
            -- Border
            love.graphics.setColor(0.1, 0.1, 0.1, 0.5)
            love.graphics.rectangle("line", window.x, window.y, window.width, window.height)
        end
    end
end

-- Draw desktop home icons (children of /home) using saved layout.
function drawDesktopHome()
    desktopHomeIcons = {}  -- reset icons table
    local startX = 10
    local startY = topBarHeight + 10
    local iconSize = 40
    local padding = 20
    local index = 0
    if desktopHome and desktopHome.children then
        -- Iterate through children in /home.
        for name, node in pairs(desktopHome.children) do
            index = index + 1
            local x, y
            if desktopLayout[name] then
                x = desktopLayout[name].x
                y = desktopLayout[name].y
            else
                local col = (index - 1) % 4
                local row = math.floor((index - 1) / 4)
                x = startX + col * (iconSize + padding)
                y = startY + row * (iconSize + padding)
                desktopLayout[name] = {x = x, y = y}
            end
            local icon = home_fileIcon  -- default to file icon
            if node.type == "directory" then
                icon = home_folderIcon
            elseif node.name:match("%.lnk$") then
                icon = home_shortcutIcon
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(icon, x, y, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
            love.graphics.setColor(0.9, 0.95, 1.0)
            love.graphics.printf(name, x, y + iconSize + 2, iconSize, "center")
            -- Save icon's bounding box and node for click detection.
            table.insert(desktopHomeIcons, {x = x, y = y, width = iconSize, height = iconSize, node = node, name = name})
        end
    end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Desktop")
    love.window.setMode(700, 450, {resizable=true, minwidth=600, minheight=400})
    love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)
    
    font = love.graphics.newFont("font/Nunito-Regular.ttf", 13)
    topBarHeight = 30
    bottomBarHeight = 40

    -- Load PNG icons.
    home_folderIcon = love.graphics.newImage("assets/folder.png")
    home_fileIcon   = love.graphics.newImage("assets/file.png")
    home_shortcutIcon = love.graphics.newImage("assets/shortcut.png")
    emailIcon = love.graphics.newImage("assets/email.png")
    browserIcon = love.graphics.newImage("assets/browser.png")
    filesIcon = love.graphics.newImage("assets/files.png")
    terminalIcon = love.graphics.newImage("assets/terminal.png")
    rouletteIcon = love.graphics.newImage("assets/roulette.png")
    texteditorIcon = love.graphics.newImage("assets/file.png")
    tessarectIcon = love.graphics.newImage("assets/box.png")
    objviewerIcon = love.graphics.newImage("assets/cube.png")
    dinoIcon = love.graphics.newImage("assets/dino.png")
    chatIcon = love.graphics.newImage("assets/chat.png")
    imageviewerIcon = love.graphics.newImage("assets/image.png")
    startIcon = love.graphics.newImage("assets/layers.png")
    ellipsisIcon = love.graphics.newImage("assets/option.png")
    settingsIcon = love.graphics.newImage("assets/settings.png")
	pokerIcon = love.graphics.newImage("assets/dino.png")
    
    local sharedFS = filesystemModule.getFS()
    -- Ensure there is a "/home" folder in the root.
    if not sharedFS.children["home"] then
        sharedFS.children["home"] = { 
            name = "home", 
            type = "directory", 
            parent = sharedFS, 
            children = {} 
        }
    end
    desktopHome = sharedFS.children["home"]
    
    -- Load desktop layout and config
    if love.filesystem.getInfo("desktop_layout.json") then
        local data = love.filesystem.read("desktop_layout.json")
        desktopLayout = json.decode(data) or {}
    end
    
    loadDesktopConfig()
    loadWallpapers()

    apps = {
        { name = "Email", module = EmailApp, instance = nil, icon = emailIcon },
        { name = "Browser", module = BrowserApp, instance = nil, icon = browserIcon },
        { name = "Files", module = FilesApp, instance = nil, icon = filesIcon },
        { name = "Terminal", module = TerminalApp, instance = nil, icon = terminalIcon },
        { name = "Roulette", module = RouletteApp, instance = nil, icon = rouletteIcon },
        { name = "TextEditor", module = TextEditor, instance = nil, icon = texteditorIcon },
        { name = "Tessarect", module = TessarectApp, instance = nil, icon = tessarectIcon },
        { name = "Dino", module = DinoApp, instance = nil, icon = dinoIcon },
        { name = "ImageViewer", module = ImageViewer, instance = nil, icon = imageviewerIcon },
        { name = "ObjViewer", module = ObjViewer, instance = nil, icon = objviewerIcon },
        { name = "NexusAI", module = NexusAI, instance = nil, icon = chatIcon },
        { name = "Settings", module = SettingsApp, instance = nil, icon = settingsIcon },
        { name = "Poker", module = PokerApp, instance = nil, icon = pokerIcon },
    }

    iconWidth = 40
    iconHeight = 40
    iconSpacing = 8
    local startX = iconSpacing + 40  -- Space for start button
    for i, app in ipairs(apps) do
        app.x = startX
        app.y = love.graphics.getHeight() - bottomBarHeight + (bottomBarHeight - iconHeight) / 2
        app.width = iconWidth
        app.height = iconHeight
        startX = startX + iconWidth + iconSpacing
    end

    openApps = {}  -- List of open windows
    
    -- Calculate visible apps for ellipsis menu
    updateVisibleApps()
end

function updateVisibleApps()
    local availableWidth = love.graphics.getWidth() - 120  -- Space for start button and ellipsis
    local currentX = 80  -- Start after start button
    visibleApps = {}
    hiddenApps = {}
    
    for i, app in ipairs(apps) do
        if currentX + app.width <= availableWidth then
            table.insert(visibleApps, app)
            currentX = currentX + app.width + iconSpacing
        else
            table.insert(hiddenApps, app)
        end
    end
end

function love.update(dt)
    for _, window in ipairs(openApps) do
        if window.instance and window.instance.update then
            window.instance:update(dt)
        end
    end
end

function love.draw()
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()

    
    if effectEnabled then
        effect(function()
			drawWallpaper()
            drawDesktop()
        end)
    else
		drawWallpaper()
        drawDesktop()
    end
    
    -- Draw context menu if open (on top of everything)
    if contextMenuOpen then
        drawContextMenu()
    end
end

function love.mousepressed(x, y, button)
    if button == 2 then  -- Right click
        -- Close context menu if already open
        if contextMenuOpen then
            contextMenuOpen = false
            return
        end
        
        -- Check if clicking on empty desktop area (not on icons, taskbar, or windows)
        local onIcon = false
        for _, icon in ipairs(desktopHomeIcons) do
            if x >= icon.x and x <= icon.x + icon.width and y >= icon.y and y <= icon.y + icon.height then
                onIcon = true
                break
            end
        end
        
        local onTaskbar = (y >= love.graphics.getHeight() - bottomBarHeight)
        local onWindow = false
        for _, window in ipairs(openApps) do
            if not window.minimized and x >= window.x and x <= window.x + window.width and
               y >= window.y and y <= window.y + window.height then
                onWindow = true
                break
            end
        end
        
        if not onIcon and not onTaskbar and not onWindow then
            contextMenuOpen = true
            contextMenuX = x
            contextMenuY = y
            return
        end
    elseif button == 1 then  -- Left click
        -- Close context menu if clicking outside
        if contextMenuOpen then
            contextMenuOpen = false
        end
        
        -- Check start button
        if x >= 0 and x <= 40 and y >= love.graphics.getHeight() - bottomBarHeight then
            startMenuOpen = not startMenuOpen
            ellipsisMenuOpen = false
            return
        end
        
        -- Check ellipsis button
        if #hiddenApps > 0 and x >= love.graphics.getWidth() - 40 and x <= love.graphics.getWidth() and y >= love.graphics.getHeight() - bottomBarHeight then
            ellipsisMenuOpen = not ellipsisMenuOpen
            startMenuOpen = false
            return
        end
        
        -- Check taskbar app clicks
        for _, app in ipairs(visibleApps) do
            local iconMargin = 6
            local iconSize = bottomBarHeight - iconMargin * 2
            local btnWidth = iconSize + iconMargin * 2 + 10
            
            if x >= app.x and x <= app.x + btnWidth and y >= love.graphics.getHeight() - bottomBarHeight then
                toggleApp(app)
                return
            end
        end
        
        -- Check ellipsis menu
        if ellipsisMenuOpen then
            local menuX = love.graphics.getWidth() - 160
            local menuY = love.graphics.getHeight() - bottomBarHeight - #hiddenApps * 40 - 10
            for i, app in ipairs(hiddenApps) do
                local appY = menuY + 5 + (i-1)*40
                if x >= menuX + 5 and x <= menuX + 145 and y >= appY and y <= appY + 35 then
                    toggleApp(app)
                    ellipsisMenuOpen = false
                    return
                end
            end
            -- Clicked outside menu, close it
            ellipsisMenuOpen = false
        end
        
        -- Check start menu
        if startMenuOpen then
            local menuWidth = 400
            local menuHeight = 450
            local menuX = 0
            local menuY = love.graphics.getHeight() - bottomBarHeight - menuHeight
            local sidebarWidth = 48
            
            -- Check scrollbar
            if startMenuMaxScroll > 0 then
                local scrollBarWidth = 4
                local scrollBarX = menuX + menuWidth - scrollBarWidth - 2
                local scrollTrackHeight = menuHeight
                local scrollThumbY = menuY + (startMenuScroll / startMenuMaxScroll) * (scrollTrackHeight - scrollBarHeight)
                
                -- Making hit target wider for usability
                if x >= scrollBarX - 4 and x <= scrollBarX + scrollBarWidth + 4 and 
                   y >= scrollThumbY and y <= scrollThumbY + scrollBarHeight then
                    scrollBarDragging = true
                    scrollBarDragOffset = y - scrollThumbY
                    return
                end
            end
            
            -- Check app icons
            local cols = 3
            local iconSize = 90
            local padding = 10
            for i, app in ipairs(apps) do
                local col = (i-1) % cols
                local row = math.floor((i-1) / cols)
                local appX = menuX + sidebarWidth + padding + col * (iconSize + padding)
                local appY = menuY + padding + row * (iconSize + padding) - startMenuScroll
                
                if x >= appX and x <= appX + iconSize and y >= appY and y <= appY + iconSize then
                    toggleApp(app)
                    startMenuOpen = false
                    return
                end
            end
            
            if x >= menuX and x <= menuX + menuWidth and y >= menuY and y <= menuY + menuHeight then
                return -- Clicked inside menu but not on an app
            end
            
            -- Clicked outside menu, close it
            startMenuOpen = false
        end
        
        -- Check if the click is in the desktop home area.
        for _, icon in ipairs(desktopHomeIcons) do
            if x >= icon.x and x <= icon.x + icon.width and y >= icon.y and y <= icon.y + icon.height then
                -- Found a desktop icon click. 
                if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
                    -- Start dragging the icon
                    draggingIcon = icon
                    dragIconOffsetX = x - icon.x
                    dragIconOffsetY = y - icon.y
                    return
                else
                    -- Open FilesApp at icon.node.
                    local FilesApp = require("files")
                    local fileExplorer = FilesApp.new()
                    fileExplorer.cwd = icon.node  -- set explorer to this folder or file's parent.
                    fileExplorer:updateFileList()
                    -- Toggle FilesApp.
                    for i, app in ipairs(apps) do
                        if app.name == "Files" then
                            app.instance = fileExplorer
                            toggleApp(app)
                            break
                        end
                    end
                    return  -- consume the click.
                end
            end
        end

        local resizeHandleSize = 12
        local titleBarHeight = 30
        
        -- Check resize handles first, top to bottom
        for i = #openApps, 1, -1 do
            local window = openApps[i]
            if not window.minimized and not window.maximized then
                if x >= window.x + window.width - resizeHandleSize and x <= window.x + window.width and
                   y >= window.y + window.height - resizeHandleSize and y <= window.y + window.height then
                    resizingWindow = window
                    resizeOffsetX = window.x + window.width - x
                    resizeOffsetY = window.y + window.height - y
                    setFocus(window)
                    return
                end
            end
        end

        -- Check windows top to bottom
        for i = #openApps, 1, -1 do
            local window = openApps[i]
            if not window.minimized then
                if x >= window.x and x <= window.x + window.width and
                   y >= window.y and y <= window.y + window.height then
                    
                    setFocus(window)
                    
                    local btnSize = 40
                    local closeX = window.x + window.width - btnSize
                    local maxX = window.x + window.width - 2 * btnSize
                    local minX = window.x + window.width - 3 * btnSize
                    
                    -- Close button
                    if x >= closeX and x <= closeX + btnSize and y >= window.y and y <= window.y + titleBarHeight then
                        for i2, win in ipairs(openApps) do
                            if win == window then
                                table.remove(openApps, i2)
                                if window == focusedWindow then focusedWindow = nil end
                                if window.app.instance and window.app.instance.close then window.app.instance:close() end
                                window.app.instance = nil
                                break
                            end
                        end
                        return
                    end
                    
                    -- Maximize button
                    if x >= maxX and x <= maxX + btnSize and y >= window.y and y <= window.y + titleBarHeight then
                        if not window.maximized then
                            window.prevX, window.prevY = window.x, window.y
                            window.prevWidth, window.prevHeight = window.width, window.height
                            window.x = 0
                            window.y = topBarHeight
                            window.width = love.graphics.getWidth()
                            window.height = love.graphics.getHeight() - topBarHeight - bottomBarHeight
                            window.maximized = true
                        else
                            window.x, window.y = window.prevX, window.prevY
                            window.width, window.height = window.prevWidth, window.prevHeight
                            window.maximized = false
                        end
                        if window.instance and window.instance.resize then
                            window.instance:resize(window.width, window.height - titleBarHeight)
                        end
                        return
                    end
                    
                    -- Minimize button
                    if x >= minX and x <= minX + btnSize and y >= window.y and y <= window.y + titleBarHeight then
                        window.minimized = true
                        return
                    end
                    
                    -- Title bar drag
                    if y >= window.y and y <= window.y + titleBarHeight then
                        if not window.maximized then
                            draggingWindow = window
                            dragOffsetX = x - window.x
                            dragOffsetY = y - window.y
                        end
                        return
                    end
                    
                    -- App content click
                    if window.instance and window.instance.mousepressed then
                        window.instance:mousepressed(x - window.x, y - window.y - titleBarHeight, button, x, y)
                    end
                    return
                end
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if resizingWindow then
        local newWidth = x + resizeOffsetX - resizingWindow.x
        local newHeight = y + resizeOffsetY - resizingWindow.y
        newWidth = math.max(MIN_WINDOW_WIDTH, math.min(newWidth, MAX_WINDOW_WIDTH))
        newHeight = math.max(MIN_WINDOW_HEIGHT, math.min(newHeight, MAX_WINDOW_HEIGHT))
        resizingWindow.width = newWidth
        resizingWindow.height = newHeight
        if resizingWindow.instance and resizingWindow.instance.resize then
            resizingWindow.instance:resize(newWidth, newHeight - 30)
        end
    elseif draggingWindow then
        draggingWindow.x = x - dragOffsetX
        draggingWindow.y = y - dragOffsetY
        
        -- Constraint to screen boundaries
        draggingWindow.y = math.max(topBarHeight, draggingWindow.y)
        draggingWindow.y = math.min(love.graphics.getHeight() - bottomBarHeight - 30, draggingWindow.y)
        draggingWindow.x = math.max(-draggingWindow.width + 50, draggingWindow.x)
        draggingWindow.x = math.min(love.graphics.getWidth() - 50, draggingWindow.x)
    elseif draggingIcon then
        desktopLayout[draggingIcon.name].x = x - dragIconOffsetX
        desktopLayout[draggingIcon.name].y = y - dragIconOffsetY
    elseif scrollBarDragging then
        local menuHeight = 450
        local menuY = love.graphics.getHeight() - bottomBarHeight - menuHeight
        local scrollTrackHeight = menuHeight
        local relativeY = y - menuY - scrollBarDragOffset
        startMenuScroll = (relativeY / (scrollTrackHeight - scrollBarHeight)) * startMenuMaxScroll
        startMenuScroll = math.max(0, math.min(startMenuScroll, startMenuMaxScroll))
    end
    
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.mousemoved then
        focusedWindow.instance:mousemoved(x, y, dx, dy)
    end
end

function love.mousereleased(x, y, button)
    -- if button == 1 and contextMenuOpen then
    if button == 1 then
        local menuWidth = 220
        local itemHeight = 32
        local menuPadding = 4
        
        for i, item in ipairs(contextMenuItems) do
            local itemY = contextMenuY + menuPadding + (i-1) * itemHeight
            if x >= contextMenuX and x <= contextMenuX + menuWidth and
               y >= itemY and y <= itemY + itemHeight then
                handleContextMenuAction(item.action)
                break
            end
        end
        
        contextMenuOpen = false
    end

    if button == 1 then
        draggingWindow = nil
        resizingWindow = nil
        scrollBarDragging = false
        if draggingIcon then
            draggingIcon = nil
            -- Save desktop layout
            local data = json.encode(desktopLayout)
            love.filesystem.write("desktop_layout.json", data)
        end
    end
    
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.mousereleased then
        focusedWindow.instance:mousereleased(x, y, button)
    end
end

function love.wheelmoved(x, y)
    if startMenuOpen then
        startMenuScroll = startMenuScroll - y * 20
        startMenuScroll = math.max(0, math.min(startMenuScroll, startMenuMaxScroll))
        return
    end
    
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.wheelmoved then
        focusedWindow.instance:wheelmoved(x, y)
    end
end

function love.textinput(text)
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.textinput then
        focusedWindow.instance:textinput(text)
    end
end

function love.keypressed(key)
    if key == "g" and love.keyboard.isDown("lctrl") then
        effectEnabled = not effectEnabled
    end
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.keypressed then
        focusedWindow.instance:keypressed(key)
    end
end

function love.resize(w, h)
    for _, window in ipairs(openApps) do
        if window.instance and window.instance.resize then
            window.instance:resize(w, h)
        end
    end
    updateVisibleApps()
end

function toggleApp(app)
    local found = nil
    for _, window in ipairs(openApps) do
        if window.app == app then
            found = window
            break
        end
    end

    if found then
        found.minimized = not found.minimized
        setFocus(found)
    else
        -- For TextEditor, check if an instance already exists:
        if (app.name == "TextEditor" or app.name == "ImageViewer" or app.name == "ObjViewer" or app.name == "Files") and app.instance then
            -- re-open using existing instance instead of creating new
            local screenWidth = love.graphics.getWidth()
            local screenHeight = love.graphics.getHeight()
            local windowWidth = 500
            local windowHeight = 300
            local x = (screenWidth - windowWidth) / 2
            local y = topBarHeight + ((screenHeight - topBarHeight - bottomBarHeight) - windowHeight) / 2
            local newWindow = { app = app, instance = app.instance, x = x, y = y, width = windowWidth, height = windowHeight, minimized = false }
            table.insert(openApps, newWindow)
            setFocus(newWindow)
        else
            -- Special case for Settings app - pass wallpapers
            if app.name == "Settings" then
                app.instance = app.module.new(wallpapers, currentWallpaper, function(wallpaper)
                    currentWallpaper = wallpaper
                    saveDesktopConfig()
                end)
            else
                app.instance = app.module.new()
            end
            local screenWidth = love.graphics.getWidth()
            local screenHeight = love.graphics.getHeight()
            local windowWidth = 500
            local windowHeight = 300
            local x = (screenWidth - windowWidth) / 2
            local y = topBarHeight + ((screenHeight - topBarHeight - bottomBarHeight) - windowHeight) / 2
            local newWindow = { app = app, instance = app.instance, x = x, y = y, width = windowWidth, height = windowHeight, minimized = false }
            table.insert(openApps, newWindow)
            setFocus(newWindow)
        end
    end
end