-- main.lua
local utf8 = require("utf8")
local json = require "lib/json"
local moonshine = require 'lib/moonshine'
local EmailApp = require("email")
local BrowserApp = require("browser")
local FilesApp = require("files")
local TerminalApp = require("terminal") 
local TextEditor = require("texteditor")
local DinoApp = require("dino")
local TessarectApp = require("tessarect")
local ImageViewer = require("imageviewer")
local ObjViewer = require("objviewer")
local ChatApp = require("chat")
local SettingsApp = require("settings")
local filesystemModule = require("filesystem")

_G.bw_shader = love.graphics.newShader[[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 texcolor = Texel(texture, texture_coords);
        float gray = dot(texcolor.rgb, vec3(0.299, 0.587, 0.114));
        return vec4(gray, gray, gray, texcolor.a) * color;
    }
]]

-- effect = moonshine(moonshine.effects.scanlines).chain(moonshine.effects.crt).chain(moonshine.effects.godsray)
effect = moonshine(moonshine.effects.filmgrain).chain(moonshine.effects.godsray)
-- effect.scanlines.opacity = 0.6
effect.godsray.exposure= 0.09
effect.godsray.density = 0.04

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

-- Context menu state
local contextMenuOpen = false
local contextMenuX = 0
local contextMenuY = 0
local contextMenuType = "desktop" -- "desktop" or "file"
local contextMenuTarget = nil -- The node (file/folder) being right-clicked
local contextMenuParent = nil -- The parent directory of the target
local contextMenuItems = {}

-- Clipboard state
local clipboard = { node = nil, type = nil } -- type: "cut" or "copy"

-- Properties window state
local propertiesWindow = nil -- { node = node, x = x, y = y, w = 300, h = 400, renameInput = "" }

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
            filename = currentWallpaper.filename
        }
    }

    love.filesystem.write("desktop_config.json", json.encode(config))
end


-- Load available wallpapers
local function loadWallpapers()
    wallpapers = {}
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

    -- Additional modern colors
    table.insert(wallpapers, {
        name = "Soft Teal",
        type = "color",
        color = {0.1, 0.35, 0.35}
    })
    table.insert(wallpapers, {
        name = "Warm Coral",
        type = "color",
        color = {0.9, 0.4, 0.35}
    })
    table.insert(wallpapers, {
        name = "Deep Purple",
        type = "color",
        color = {0.35, 0.2, 0.45}
    })
    table.insert(wallpapers, {
        name = "Mint",
        type = "color",
        color = {0.3, 0.7, 0.6}
    })
    table.insert(wallpapers, {
        name = "Sunset Orange",
        type = "color",
        color = {0.9, 0.5, 0.2}
    })
    table.insert(wallpapers, {
        name = "Slate",
        type = "color",
        color = {0.3, 0.35, 0.4}
    })
    table.insert(wallpapers, {
        name = "Rose Gold",
        type = "color",
        color = {0.85, 0.55, 0.6}
    })

    -- Windows 10 accent colors
    table.insert(wallpapers, {
        name = "Win10 Blue",
        type = "color",
        color = {0.0, 0.45, 0.7}
    })
    table.insert(wallpapers, {
        name = "Win10 Teal",
        type = "color",
        color = {0.0, 0.6, 0.6}
    })
    table.insert(wallpapers, {
        name = "Win10 Green",
        type = "color",
        color = {0.5, 0.7, 0.1}
    })
    table.insert(wallpapers, {
        name = "Win10 Purple",
        type = "color",
        color = {0.6, 0.2, 0.7}
    })
    table.insert(wallpapers, {
        name = "Win10 Pink",
        type = "color",
        color = {0.9, 0.2, 0.5}
    })
    table.insert(wallpapers, {
        name = "Win10 Red",
        type = "color",
        color = {0.85, 0.25, 0.25}
    })
    table.insert(wallpapers, {
        name = "Win10 Orange",
        type = "color",
        color = {0.9, 0.5, 0.1}
    })
    table.insert(wallpapers, {
        name = "Win10 Yellow",
        type = "color",
        color = {0.95, 0.8, 0.1}
    })
    table.insert(wallpapers, {
        name = "Win10 Light Blue",
        type = "color",
        color = {0.3, 0.7, 0.9}
    })
    
    -- table.insert(wallpapers, {
        -- name = "Blue Gradient",
        -- type = "gradient",
        -- gradient = {
            -- top = {0.15, 0.25, 0.35},
            -- bottom = {0.25, 0.35, 0.45}
        -- }
    -- })
    -- table.insert(wallpapers, {
        -- name = "Sunset",
        -- type = "gradient",
        -- gradient = {
            -- top = {0.8, 0.2, 0.2},
            -- bottom = {0.2, 0.1, 0.4}
        -- }
    -- })
    
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

		local scale = math.max(screenWidth / imgW, screenHeight / imgH)

		local drawX = (screenWidth - imgW * scale) / 2
		local drawY = (screenHeight - imgH * scale) / 2

		love.graphics.draw(img, drawX, drawY, 0, scale, scale)
    else
        love.graphics.setColor(0.15, 0.25, 0.35)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    end
end

-- Create new folder in desktop home
local function createNewFolder(name)
    if not name or name == "" then
        name = "New Folder"
    end
    
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
    
    refreshDesktopLayout()
    filesystemModule.save(filesystemModule.getFS())
end

-- Create new file in desktop home
local function createNewFile(name)
    if not name or name == "" then
        name = "New File.txt"
    elseif not name:match("%..+$") then
        name = name .. ".txt"
    end
    
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
    
    refreshDesktopLayout()
    filesystemModule.save(filesystemModule.getFS())
end

-- Create new shortcut
local function createNewShortcut(targetNode, parent)
    parent = parent or desktopHome
    local targetPath = filesystemModule.getPath(targetNode)
    local name = targetNode.name .. " - Shortcut.lnk"
    
    local baseName, counter = name:gsub("%.lnk$", ""), 1
    while parent.children[name] do
        name = baseName .. " (" .. counter .. ").lnk"
        counter = counter + 1
    end
    
    parent.children[name] = {
        name = name,
        type = "file",
        parent = parent,
        content = targetPath
    }
    
    if parent == desktopHome then
        refreshDesktopLayout()
    end
    filesystemModule.save(filesystemModule.getFS())
    
    -- Refresh any open file explorer apps
    for _, win in ipairs(openApps) do
        if win.app.name == "Files" and win.instance then
            win.instance:updateFileList()
        end
    end
end


-- Draw context menu
local function drawContextMenu()
    local menuWidth = 220
    local itemHeight = 32
    local menuPadding = 4
    local menuHeight = #contextMenuItems * itemHeight + (menuPadding * 2)
    
    love.graphics.setColor(0.17, 0.17, 0.17, 0.98)
    love.graphics.rectangle("fill", contextMenuX, contextMenuY, menuWidth, menuHeight, 4)
    
    love.graphics.setColor(0.3, 0.3, 0.3, 1.0)
    love.graphics.rectangle("line", contextMenuX, contextMenuY, menuWidth, menuHeight, 4)
    
    for i, item in ipairs(contextMenuItems) do
        local itemY = contextMenuY + menuPadding + (i-1) * itemHeight
        
        local mouseX, mouseY = love.mouse.getPosition()
        local isHovered = mouseX >= contextMenuX and mouseX <= contextMenuX + menuWidth and
                          mouseY >= itemY and mouseY <= itemY + itemHeight
                          
        if isHovered then
            love.graphics.setColor(0.3, 0.3, 0.3, 1.0)
            love.graphics.rectangle("fill", contextMenuX + 2, itemY, menuWidth - 4, itemHeight, 4)
        end
        
        love.graphics.setColor(0.95, 0.95, 0.95)
        love.graphics.print(item.text, contextMenuX + 32, itemY + 8)
    end
end

-- Draw properties window
local function drawPropertiesWindow()
    if not propertiesWindow then return end
    local pw = propertiesWindow
    
    -- Overlay shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", pw.x + 4, pw.y + 4, pw.w, pw.h, 8)
    
    -- Window background
    love.graphics.setColor(0.95, 0.95, 0.95)
    love.graphics.rectangle("fill", pw.x, pw.y, pw.w, pw.h, 8)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("line", pw.x, pw.y, pw.w, pw.h, 8)
    
    -- Title bar
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.rectangle("fill", pw.x, pw.y, pw.w, 30, 8, 8, 0, 0)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print("Properties: " .. pw.node.name, pw.x + 10, pw.y + 8)
    
    -- Close button
    local closeHovered = love.mouse.getX() >= pw.x + pw.w - 30 and love.mouse.getX() <= pw.x + pw.w and
                         love.mouse.getY() >= pw.y and love.mouse.getY() <= pw.y + 30
    if closeHovered then
        love.graphics.setColor(0.9, 0.2, 0.2)
    else
        love.graphics.setColor(0.7, 0.7, 0.7)
    end
    love.graphics.print("X", pw.x + pw.w - 20, pw.y + 8)
    
    -- Content
    love.graphics.setColor(0.3, 0.3, 0.3)
    local cy = pw.y + 50
    
    -- Icon (large)
    local icon = (pw.node.type == "directory") and home_folderIcon or home_fileIcon
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(icon, pw.x + 20, cy, 0, 48/icon:getWidth(), 48/icon:getHeight())
    
    -- Name / Rename
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.print("Name:", pw.x + 80, cy)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", pw.x + 80, cy + 20, pw.w - 100, 24, 4)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.rectangle("line", pw.x + 80, cy + 20, pw.w - 100, 24, 4)
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(pw.renameInput, pw.x + 85, cy + 24)
    
    -- Cursor for rename
    if math.floor(love.timer.getTime() * 2) % 2 == 0 then
        local tw = love.graphics.getFont():getWidth(pw.renameInput)
        love.graphics.line(pw.x + 85 + tw, cy + 22, pw.x + 85 + tw, cy + 42)
    end
    
    cy = cy + 70
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.line(pw.x + 20, cy, pw.x + pw.w - 20, cy)
    cy = cy + 20
    
    -- Info
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.print("Type: " .. pw.node.type:gsub("^%l", string.upper), pw.x + 20, cy)
    cy = cy + 25
    
    local path = filesystemModule.getPath(pw.node)
    love.graphics.print("Location: " .. path, pw.x + 20, cy)
    cy = cy + 25
    
    if pw.node.type == "file" then
        local size = pw.node.content and #pw.node.content or 0
        love.graphics.print("Size: " .. size .. " bytes", pw.x + 20, cy)
    else
        local count = 0
        for _ in pairs(pw.node.children or {}) do count = count + 1 end
        love.graphics.print("Contains: " .. count .. " items", pw.x + 20, cy)
    end
    cy = cy + 25
    
    local created = pw.node.created and os.date("%d/%m/%Y %H:%M", pw.node.created) or "Unknown"
    love.graphics.print("Created: " .. created, pw.x + 20, cy)
    cy = cy + 25
    
    local modified = pw.node.modified and os.date("%d/%m/%Y %H:%M", pw.node.modified) or "Unknown"
    love.graphics.print("Modified: " .. modified, pw.x + 20, cy)
    cy = cy + 25
    
    -- Apply button
    cy = pw.y + pw.h - 50
    local btnHovered = love.mouse.getX() >= pw.x + pw.w - 100 and love.mouse.getX() <= pw.x + pw.w - 20 and
                       love.mouse.getY() >= cy and love.mouse.getY() <= cy + 30
    love.graphics.setColor(btnHovered and {0.2, 0.5, 0.8} or {0.3, 0.6, 0.9})
    love.graphics.rectangle("fill", pw.x + pw.w - 100, cy, 80, 30, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Apply", pw.x + pw.w - 100, cy + 8, 80, "center")
end

function _G.showFileContextMenu(node, parent)
    local x, y = love.mouse.getPosition()
    contextMenuOpen = true
    contextMenuX, contextMenuY = x, y
    contextMenuType = "file"
    contextMenuTarget = node
    contextMenuParent = parent
    contextMenuItems = {
        {text = "Cut", action = "cut"},
        {text = "Copy", action = "copy"},
        {text = "Create Shortcut", action = "create_shortcut"},
        {text = "Delete", action = "delete"},
        {text = "Properties", action = "properties"}
    }
    -- Adjust menu position
    if contextMenuX + 220 > love.graphics.getWidth() then contextMenuX = x - 220 end
    local menuH = #contextMenuItems * 32 + 8
    if contextMenuY + menuH > love.graphics.getHeight() - 40 then contextMenuY = y - menuH end
end

function _G.showFolderContextMenu(parent)
    local x, y = love.mouse.getPosition()
    contextMenuOpen = true
    contextMenuX, contextMenuY = x, y
    contextMenuType = "desktop"
    contextMenuTarget = nil
    contextMenuParent = parent
    contextMenuItems = {
        {text = "New Folder", action = "new_folder"},
        {text = "New Text File", action = "new_file"},
        {text = "Paste", action = "paste"},
        {text = "Refresh", action = "refresh"}
    }
    if not clipboard.node then
        for i, item in ipairs(contextMenuItems) do
            if item.action == "paste" then table.remove(contextMenuItems, i); break end
        end
    end
    -- Adjust menu position
    if contextMenuX + 220 > love.graphics.getWidth() then contextMenuX = x - 220 end
    local menuH = #contextMenuItems * 32 + 8
    if contextMenuY + menuH > love.graphics.getHeight() - 40 then contextMenuY = y - menuH end
end

-- Handle context menu actions
local function handleContextMenuAction(action)
    if action == "new_folder" then
        createNewFolder()
    elseif action == "new_file" then
        createNewFile()
    elseif action == "create_shortcut" then
        if contextMenuTarget then
            createNewShortcut(contextMenuTarget, contextMenuParent)
        end
    elseif action == "new_shortcut" then
        -- This was the old desktop context menu action, let's just make it create a shortcut to root for now or remove it
        createNewShortcut(filesystemModule.getFS(), desktopHome)
    elseif action == "change_wallpaper" then
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
        refreshDesktopLayout()
    elseif action == "delete" then
        if contextMenuTarget then
            filesystemModule.delete(contextMenuTarget)
            refreshDesktopLayout()
        end
    elseif action == "cut" then
        clipboard.node = contextMenuTarget
        clipboard.type = "cut"
    elseif action == "copy" then
        clipboard.node = contextMenuTarget
        clipboard.type = "copy"
    elseif action == "paste" then
        if clipboard.node then
            local dest = contextMenuParent or desktopHome
            if clipboard.type == "cut" then
                filesystemModule.move(clipboard.node, dest)
                clipboard.node = nil -- Clear after move
            else
                filesystemModule.copy(clipboard.node, dest)
            end
            refreshDesktopLayout()
            -- Refresh any open file explorer apps
            for _, win in ipairs(openApps) do
                if win.app.name == "Files" and win.instance then
                    win.instance:updateFileList()
                end
            end
        end
    elseif action == "properties" then
        if contextMenuTarget then
            propertiesWindow = {
                node = contextMenuTarget,
                x = love.graphics.getWidth()/2 - 150,
                y = love.graphics.getHeight()/2 - 200,
                w = 300,
                h = 400,
                renameInput = contextMenuTarget.name
            }
        end
    end
end

-- Draw the desktop
function drawDesktop()
    love.graphics.setFont(font)
    
    drawDesktopHome()
    
    -- Taskbar Background (Win10 Dark)
    love.graphics.setColor(0.05, 0.05, 0.05, 0.98)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - bottomBarHeight, love.graphics.getWidth(), bottomBarHeight)
    
    local startBtnWidth = 48
    local isStartHovered = love.mouse.getX() >= 0 and love.mouse.getX() <= startBtnWidth and love.mouse.getY() >= love.graphics.getHeight() - bottomBarHeight
    
    if startMenuOpen then
        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() - bottomBarHeight, startBtnWidth, bottomBarHeight)
    elseif isStartHovered then
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.rectangle("fill", 0, love.graphics.getHeight() - bottomBarHeight, startBtnWidth, bottomBarHeight)
    end
    
    -- Start Logo (Simplified Win10)
    love.graphics.setColor(1, 1, 1)
    if isStartHovered or startMenuOpen then
        love.graphics.setColor(0, 0.47, 0.84) -- Win10 Blue on hover
    end
    
    local cx, cy = startBtnWidth / 2, love.graphics.getHeight() - bottomBarHeight + bottomBarHeight / 2
    local s = 6
    local g = 2
    love.graphics.rectangle("fill", cx - s - g/2, cy - s - g/2, s, s)
    love.graphics.rectangle("fill", cx + g/2, cy - s - g/2, s, s)
    love.graphics.rectangle("fill", cx - s - g/2, cy + g/2, s, s)
    love.graphics.rectangle("fill", cx + g/2, cy + g/2, s, s)
    
    -- Taskbar Clock Area
    love.graphics.setColor(0.9, 0.9, 0.9)
    local currentTime = os.date("%I:%M %p")
    local currentDate = os.date("%d/%m/%Y")
    local timeWidth = font:getWidth(currentTime)
    local dateWidth = font:getWidth(currentDate)
    local maxTextWidth = math.max(timeWidth, dateWidth)
    local dateTimeX = love.graphics.getWidth() - maxTextWidth - 15
    
    -- Subtle hover for tray area
    if love.mouse.getX() >= dateTimeX - 5 and love.mouse.getY() >= love.graphics.getHeight() - bottomBarHeight then
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.rectangle("fill", dateTimeX - 5, love.graphics.getHeight() - bottomBarHeight, maxTextWidth + 20, bottomBarHeight)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.9, 0.9, 0.9)
    end
    
    love.graphics.print(currentTime, dateTimeX + (maxTextWidth - timeWidth) / 2, love.graphics.getHeight() - bottomBarHeight + 4)
    love.graphics.print(currentDate, dateTimeX + (maxTextWidth - dateWidth) / 2, love.graphics.getHeight() - bottomBarHeight + 20)
    
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
        
        if state ~= "closed" then
            if isFocused then
                love.graphics.setColor(0.4, 0.6, 1.0)
                love.graphics.rectangle("fill", app.x + 4, love.graphics.getHeight() - 3, btnWidth - 8, 3)
            else
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.rectangle("fill", app.x + 8, love.graphics.getHeight() - 3, btnWidth - 16, 3)
            end
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(app.icon, app.x + 5 + iconMargin, love.graphics.getHeight() - bottomBarHeight + iconMargin, 0, scale, scale)
    end
    
    if #hiddenApps > 0 then
        local ellipsisX = love.graphics.getWidth() - 40
        love.graphics.setColor(0.15, 0.15, 0.2)
        love.graphics.rectangle("fill", ellipsisX, love.graphics.getHeight() - bottomBarHeight, 40, bottomBarHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(ellipsisIcon, ellipsisX + 10, love.graphics.getHeight() - bottomBarHeight + (bottomBarHeight - 30) / 2, 0, 30/ellipsisIcon:getWidth(), 30/ellipsisIcon:getHeight())
    end

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
    
    if startMenuOpen then
        local menuWidth = 400
        local menuHeight = math.min(500, love.graphics.getHeight() - bottomBarHeight)
        local menuX = 0
        local menuY = love.graphics.getHeight() - bottomBarHeight - menuHeight
        local sidebarWidth = 48
        
        local cols = 3
        local iconSize = 90
        local padding = 10
        local rows = math.ceil(#apps / cols)
        local contentHeight = rows * (iconSize + padding) + padding
        
        startMenuMaxScroll = math.max(0, contentHeight - menuHeight)
        
        love.graphics.setColor(0.12, 0.12, 0.12, 0.98)
        love.graphics.rectangle("fill", menuX + sidebarWidth, menuY, menuWidth - sidebarWidth, menuHeight)
        
        love.graphics.setColor(0.1, 0.1, 0.1, 0.98)
        love.graphics.rectangle("fill", menuX, menuY, sidebarWidth, menuHeight)
        
        love.graphics.setColor(0.2, 0.2, 0.2, 1.0)
        love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight)
        
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("fill", menuX + 16, menuY + menuHeight - 40, 16, 16) 
        love.graphics.rectangle("fill", menuX + 16, menuY + menuHeight - 80, 16, 16) 
        love.graphics.circle("fill", menuX + 24, menuY + menuHeight - 120, 8) 
        
        love.graphics.setScissor(menuX + sidebarWidth, menuY, menuWidth - sidebarWidth, menuHeight)
        love.graphics.setFont(font)
        
        for i, app in ipairs(apps) do
            local col = (i-1) % cols
            local row = math.floor((i-1) / cols)
            local x = menuX + sidebarWidth + padding + col * (iconSize + padding)
            local y = menuY + padding + row * (iconSize + padding) - startMenuScroll
            
            local isHovered = love.mouse.getX() >= x and love.mouse.getX() <= x + iconSize and love.mouse.getY() >= y and love.mouse.getY() <= y + iconSize
            
            if isHovered then
                love.graphics.setColor(0.1, 0.35, 0.6)
            else
                love.graphics.setColor(0, 0.47, 0.84)
            end
            love.graphics.rectangle("fill", x, y, iconSize, iconSize)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(app.icon, x + (iconSize - 32)/2, y + 15, 0, 32/app.icon:getWidth(), 32/app.icon:getHeight())
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(app.name, x, y + 55, iconSize, "center")
        end
        
        love.graphics.setScissor()
        
        if startMenuMaxScroll > 0 then
            local scrollBarWidth = 4
            local scrollBarX = menuX + menuWidth - scrollBarWidth - 2
            local scrollTrackHeight = menuHeight
            scrollBarHeight = (menuHeight / contentHeight) * scrollTrackHeight
            
            love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
            love.graphics.rectangle("fill", scrollBarX, menuY, scrollBarWidth, scrollTrackHeight)
            
            local scrollThumbY = menuY + (startMenuScroll / startMenuMaxScroll) * (scrollTrackHeight - scrollBarHeight)
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
            if scrollBarDragging then love.graphics.setColor(0.5, 0.5, 0.5, 0.8) end
            love.graphics.rectangle("fill", scrollBarX, scrollThumbY, scrollBarWidth, scrollBarHeight)
        end
    end

    for _, window in ipairs(openApps) do
        if not window.minimized then
            love.graphics.setFont(font)
            local titleBarHeight = 25
            
            -- love.graphics.setColor(0.9, 0.9, 0.95)
            -- love.graphics.rectangle("fill", window.x, window.y, window.width, window.height)
            
            if window == focusedWindow then
                love.graphics.setColor(1, 1, 1, 1)
            else
                love.graphics.setColor(0.95, 0.95, 0.95, 0.95)
            end
            love.graphics.rectangle("fill", window.x, window.y, window.width, titleBarHeight)
            
            if window == focusedWindow then
                love.graphics.setColor(0, 0, 0)
            else
                love.graphics.setColor(0.5, 0.5, 0.5)
            end
            
            if window.app.instance then
                love.graphics.print(window.app.instance.title or window.app.name, window.x + 10, window.y + (titleBarHeight - 20)/2)
            else 
                love.graphics.print(window.app.name, window.x + 10, window.y + (titleBarHeight - 20)/2)
            end
            
            local btnSize = 40
            local closeX = window.x + window.width - btnSize
            local maxX = window.x + window.width - 2 * btnSize
            local minX = window.x + window.width - 3 * btnSize
            
            local isCloseHovered = love.mouse.getX() >= closeX and love.mouse.getX() <= closeX + btnSize and love.mouse.getY() >= window.y and love.mouse.getY() <= window.y + titleBarHeight
            if isCloseHovered then
                love.graphics.setColor(0.9, 0.1, 0.1)
                love.graphics.rectangle("fill", closeX, window.y, btnSize, titleBarHeight)
                love.graphics.setColor(1, 1, 1)
            else
                if window == focusedWindow then love.graphics.setColor(0, 0, 0) else love.graphics.setColor(0.5, 0.5, 0.5) end
            end
            love.graphics.printf("X", closeX, window.y + (titleBarHeight - 20)/2, btnSize, "center")
            
            local isMaxHovered = love.mouse.getX() >= maxX and love.mouse.getX() <= maxX + btnSize and love.mouse.getY() >= window.y and love.mouse.getY() <= window.y + titleBarHeight
            if isMaxHovered then
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.rectangle("fill", maxX, window.y, btnSize, titleBarHeight)
            end
            if window == focusedWindow or isMaxHovered then love.graphics.setColor(0, 0, 0) else love.graphics.setColor(0.5, 0.5, 0.5) end
            if window.maximized then
                love.graphics.printf("[-]", maxX, window.y + (titleBarHeight - 20)/2, btnSize, "center")
            else
                love.graphics.printf("[+]", maxX, window.y + (titleBarHeight - 20)/2, btnSize, "center")
            end
            
            local isMinHovered = love.mouse.getX() >= minX and love.mouse.getX() <= minX + btnSize and love.mouse.getY() >= window.y and love.mouse.getY() <= window.y + titleBarHeight
            if isMinHovered then
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.rectangle("fill", minX, window.y, btnSize, titleBarHeight)
            end
            if window == focusedWindow or isMinHovered then love.graphics.setColor(0, 0, 0) else love.graphics.setColor(0.5, 0.5, 0.5) end
            love.graphics.printf("-", minX, window.y + (titleBarHeight - 20)/2, btnSize, "center")
            
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
            
            -- if not window.maximized then
                -- local handleSize = 12
                -- love.graphics.setColor(0.5, 0.6, 0.7)
                -- love.graphics.polygon("fill", 
                    -- window.x + window.width, window.y + window.height - handleSize,
                    -- window.x + window.width - handleSize, window.y + window.height,
                    -- window.x + window.width, window.y + window.height
                -- )
            -- end
            
            -- love.graphics.setColor(0.1, 0.1, 0.1, 0.5)
            -- love.graphics.rectangle("line", window.x, window.y, window.width, window.height)
        end
    end
end

-- Helper function to truncate text with ellipsis
local function getEllipsisText(text, maxWidth, font)
    if font:getWidth(text) <= maxWidth then return text end
    local s = text
    local ellipsis = "..."
    while font:getWidth(s .. ellipsis) > maxWidth and #s > 0 do
        s = s:sub(1, #s - 1)
    end
    return s .. ellipsis
end

-- Refreshes the grid positions (Windows 10 Style: Vertical Columns)
function refreshDesktopLayout()
    local startX, startY = 15, 15
    local iconSize = 42
    local paddingX, paddingY = 20, 20 -- Extra vertical space for labels
    local colHeight = love.graphics.getHeight() - bottomBarHeight - 40
    local iconsPerCol = math.max(1, math.floor(colHeight / (iconSize + paddingY)))

    -- Sort icons: Directories first, then alphabetical
    local keys = {}
    for name, _ in pairs(desktopHome.children) do table.insert(keys, name) end
    table.sort(keys, function(a, b)
        local nodeA, nodeB = desktopHome.children[a], desktopHome.children[b]
        if nodeA.type ~= nodeB.type then return nodeA.type == "directory" end
        return a:lower() < b:lower()
    end)

    for i, name in ipairs(keys) do
        local row = (i - 1) % iconsPerCol
        local col = math.floor((i - 1) / iconsPerCol)
        desktopLayout[name] = {
            x = startX + col * (iconSize + paddingX),
            y = startY + row * (iconSize + paddingY)
        }
    end
end

function drawDesktopHome()
    desktopHomeIcons = {} 
    local iconSize = 40
    
    if desktopHome and desktopHome.children then
        for name, node in pairs(desktopHome.children) do
            local pos = desktopLayout[name]
            if not pos then 
                refreshDesktopLayout() 
                pos = desktopLayout[name]
            end
            
            local x, y = pos.x, pos.y
            local icon = (node.type == "directory") and home_folderIcon or home_fileIcon
            local isShortcut = name:match("%.lnk$")

            if isShortcut then
                local targetPath = node.content or node.target
                local targetNode = targetPath and filesystemModule.getNodeByPath(targetPath) or nil
                if targetNode and targetNode.type == "directory" then
                    icon = home_folderIcon
                else
                    icon = home_fileIcon
                end
                
                love.graphics.setShader(_G.bw_shader)
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(icon, x, y, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
                love.graphics.setShader()
                
                -- Draw little link icon at bottom right
                local shortcutSize = iconSize * 0.4
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(home_shortcutIcon, x + iconSize - shortcutSize, y + iconSize - shortcutSize, 0, shortcutSize / home_shortcutIcon:getWidth(), shortcutSize / home_shortcutIcon:getHeight())
            else
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(icon, x, y, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
            end
            
            -- Add Ellipsis for long names
            local displayName = getEllipsisText(name, iconSize + 20, font)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(displayName, x - 10, y + iconSize + 2, iconSize + 20, "center")
            
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

    home_folderIcon = love.graphics.newImage("assets/folder.png")
    home_fileIcon   = love.graphics.newImage("assets/file.png")
    home_shortcutIcon = love.graphics.newImage("assets/shortcut.png")
    emailIcon = love.graphics.newImage("assets/email.png")
    browserIcon = love.graphics.newImage("assets/browser.png")
    filesIcon = love.graphics.newImage("assets/files.png")
    terminalIcon = love.graphics.newImage("assets/terminal.png")
    texteditorIcon = love.graphics.newImage("assets/file.png")
    tessarectIcon = love.graphics.newImage("assets/box.png")
    objviewerIcon = love.graphics.newImage("assets/cube.png")
    dinoIcon = love.graphics.newImage("assets/dino.png")
    chatIcon = love.graphics.newImage("assets/chat.png")
    imageviewerIcon = love.graphics.newImage("assets/image.png")
    startIcon = love.graphics.newImage("assets/layers.png")
    ellipsisIcon = love.graphics.newImage("assets/option.png")
    settingsIcon = love.graphics.newImage("assets/settings.png")
    
    local sharedFS = filesystemModule.getFS()
    if not sharedFS.children["home"] then
        sharedFS.children["home"] = { 
            name = "home", 
            type = "directory", 
            parent = sharedFS, 
            children = {} 
        }
    end
    desktopHome = sharedFS.children["home"]
    
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
        { name = "TextEditor", module = TextEditor, instance = nil, icon = texteditorIcon },
        { name = "Tessarect", module = TessarectApp, instance = nil, icon = tessarectIcon },
        { name = "Dino", module = DinoApp, instance = nil, icon = dinoIcon },
        { name = "ImageViewer", module = ImageViewer, instance = nil, icon = imageviewerIcon },
        { name = "ObjViewer", module = ObjViewer, instance = nil, icon = objviewerIcon },
        { name = "ChatApp", module = ChatApp, instance = nil, icon = chatIcon },
        { name = "Settings", module = SettingsApp, instance = nil, icon = settingsIcon },
    }

    iconWidth = 40
    iconHeight = 40
    iconSpacing = 8
    local startX = 48 + iconSpacing
    for i, app in ipairs(apps) do
        app.x = startX
        app.y = love.graphics.getHeight() - bottomBarHeight + (bottomBarHeight - iconHeight) / 2
        app.width = iconWidth
        app.height = iconHeight
        startX = startX + iconWidth + iconSpacing
    end

    openApps = {}
    
    updateVisibleApps()
end

function updateVisibleApps()
    local availableWidth = love.graphics.getWidth() - 120 
    local currentX = 48 + 10  
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
    
    if contextMenuOpen then
        drawContextMenu()
    end

    if propertiesWindow then
        drawPropertiesWindow()
    end
end

function love.mousepressed(x, y, button)
    local titleBarHeight = 30
    local resizeHandleSize = 12
    
    -- 1. Check Context Menu (Topmost layer)
    if contextMenuOpen then
        local menuWidth, itemHeight = 220, 32
        for i, item in ipairs(contextMenuItems) do
            local itemY = contextMenuY + 4 + (i-1) * itemHeight
            if x >= contextMenuX and x <= contextMenuX + menuWidth and y >= itemY and y <= itemY + itemHeight then
                handleContextMenuAction(item.action)
                contextMenuOpen = false
                return -- Stop further processing
            end
        end
        contextMenuOpen = false -- Close if clicked outside the menu
    end
    
    if button == 2 then
        local onIcon = false
        for _, icon in ipairs(desktopHomeIcons) do
            if x >= icon.x and x <= icon.x + icon.width and y >= icon.y and y <= icon.y + icon.height then
                onIcon = true
                contextMenuOpen = true
                contextMenuX, contextMenuY = x, y
                contextMenuType = "file"
                contextMenuTarget = icon.node
                contextMenuParent = desktopHome
                contextMenuItems = {
                    {text = "Cut", action = "cut"},
                    {text = "Copy", action = "copy"},
                    {text = "Delete", action = "delete"},
                    {text = "Properties", action = "properties"}
                }
            end
        end
        
        if not onIcon then
            contextMenuOpen = true
            contextMenuX, contextMenuY = x, y
            contextMenuType = "desktop"
            contextMenuTarget = nil
            contextMenuParent = desktopHome
            contextMenuItems = {
                {text = "New Folder", action = "new_folder"},
                {text = "New Text File", action = "new_file"},
                {text = "New Shortcut", action = "new_shortcut"},
                {text = "Paste", action = "paste"},
                {text = "Change Wallpaper", action = "change_wallpaper"},
                {text = "Settings", action = "open_settings"},
                {text = "Refresh", action = "refresh"}
            }
            -- Disable paste if clipboard empty
            if not clipboard.node then
                for i, item in ipairs(contextMenuItems) do
                    if item.action == "paste" then table.remove(contextMenuItems, i); break end
                end
            end
        end
        
        -- Adjust menu position
        if contextMenuX + 220 > love.graphics.getWidth() then contextMenuX = x - 220 end
        if contextMenuY + (#contextMenuItems * 32) > love.graphics.getHeight() - bottomBarHeight then
            contextMenuY = y - (#contextMenuItems * 32)
        end
    end

    -- 2. Check UI Overlays & Taskbar (Left click only)
    if button == 1 then
        if x >= 0 and x <= 48 and y >= love.graphics.getHeight() - bottomBarHeight then
            startMenuOpen = not startMenuOpen
            ellipsisMenuOpen = false
            return
        end
        
        if #hiddenApps > 0 and x >= love.graphics.getWidth() - 40 and x <= love.graphics.getWidth() and y >= love.graphics.getHeight() - bottomBarHeight then
            ellipsisMenuOpen = not ellipsisMenuOpen
            startMenuOpen = false
            return
        end
        
        if y >= love.graphics.getHeight() - bottomBarHeight then
            for _, app in ipairs(visibleApps) do
                local iconMargin = 6
                local iconSize = bottomBarHeight - iconMargin * 2
                local btnWidth = iconSize + iconMargin * 2 + 10
                if x >= app.x and x <= app.x + btnWidth then
                    toggleApp(app)
                    return
                end
            end
            return -- Consume all empty taskbar clicks
        end
        
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
            ellipsisMenuOpen = false
        end
        
        if startMenuOpen then
            local menuWidth = 400
            local menuHeight = math.min(500, love.graphics.getHeight() - bottomBarHeight)
            local menuX = 0
            local menuY = love.graphics.getHeight() - bottomBarHeight - menuHeight
            local sidebarWidth = 48
            
            if startMenuMaxScroll > 0 then
                local scrollBarWidth = 4
                local scrollBarX = menuX + menuWidth - scrollBarWidth - 2
                local scrollTrackHeight = menuHeight
                local scrollThumbY = menuY + (startMenuScroll / startMenuMaxScroll) * (scrollTrackHeight - scrollBarHeight)
                
                if x >= scrollBarX - 4 and x <= scrollBarX + scrollBarWidth + 4 and 
                   y >= scrollThumbY and y <= scrollThumbY + scrollBarHeight then
                    scrollBarDragging = true
                    scrollBarDragOffset = y - scrollThumbY
                    return
                end
            end
            
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
                return
            end
            
            startMenuOpen = false
        end
        
        -- Resize handles (Left click only)
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
    end

    -- 3. Check Windows (Topmost to Bottommost) - intercepts both Left and Right clicks
    for i = #openApps, 1, -1 do
        local window = openApps[i]
        if not window.minimized then
            if x >= window.x and x <= window.x + window.width and
               y >= window.y and y <= window.y + window.height then
                
                setFocus(window)
                
                if button == 1 then
                    local btnSize = 40
                    local closeX = window.x + window.width - btnSize
                    local maxX = window.x + window.width - 2 * btnSize
                    local minX = window.x + window.width - 3 * btnSize
                    
                    if y >= window.y and y <= window.y + titleBarHeight then
                        if x >= closeX and x <= closeX + btnSize then
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
                        
                        if x >= maxX and x <= maxX + btnSize then
                            if not window.maximized then
                                window.prevX, window.prevY = window.x, window.y
                                window.prevWidth, window.prevHeight = window.width, window.height
                                window.x = 0
                                window.y = 0  -- Fixed fullscreen y-margin offset
                                window.width = love.graphics.getWidth()
                                window.height = love.graphics.getHeight() - bottomBarHeight
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
                        
                        if x >= minX and x <= minX + btnSize then
                            window.minimized = true
                            return
                        end
                        
                        if not window.maximized then
                            draggingWindow = window
                            dragOffsetX = x - window.x
                            dragOffsetY = y - window.y
                        end
                        return
                    end
                end
                
                -- Delegate standard and relative clicks to app content area
                if y > window.y + titleBarHeight then
                    if window.instance and window.instance.mousepressed then
                        window.instance:mousepressed(x - window.x, y - window.y - titleBarHeight, button, x, y)
                    end
                end
                return -- Stop processing clicks for anything underneath the window!
            end
        end
    end

    -- Check Properties Window
    if propertiesWindow then
        local pw = propertiesWindow
        -- Close button
        if x >= pw.x + pw.w - 30 and x <= pw.x + pw.w and y >= pw.y and y <= pw.y + 30 then
            propertiesWindow = nil
            return
        end
        -- Apply button
        if x >= pw.x + pw.w - 100 and x <= pw.x + pw.w - 20 and y >= pw.y + pw.h - 50 and y <= pw.y + pw.h - 20 then
            if pw.renameInput ~= "" and pw.renameInput ~= pw.node.name then
                filesystemModule.rename(pw.node, pw.renameInput)
                refreshDesktopLayout()
                -- Refresh any open file explorer apps
                for _, win in ipairs(openApps) do
                    if win.app.name == "Files" and win.instance then
                        win.instance:updateFileList()
                    end
                end
            end
            propertiesWindow = nil
            return
        end
        -- Consume clicks inside properties window
        if x >= pw.x and x <= pw.x + pw.w and y >= pw.y and y <= pw.y + pw.h then
            return
        end
    end

    -- 4. Check Desktop Icons (Behind everything)
    local onIcon = false
    for _, icon in ipairs(desktopHomeIcons) do
        if x >= icon.x and x <= icon.x + icon.width and y >= icon.y and y <= icon.y + icon.height then
            onIcon = true
            if button == 1 then
                if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
                    draggingIcon = icon
                    dragIconOffsetX = x - icon.x
                    dragIconOffsetY = y - icon.y
                else
                    local targetNode = icon.node
                    if icon.name:match("%.lnk$") then
                        local path = icon.node.content or icon.node.target
                        targetNode = path and filesystemModule.getNodeByPath(path) or icon.node
                    end
                    
                    if targetNode.type == "directory" then
                        local FilesApp = require("files")
                        local fileExplorer = FilesApp.new()
                        fileExplorer.cwd = targetNode
                        fileExplorer:updateFileList()
                        for i, app in ipairs(apps) do
                            if app.name == "Files" then
                                app.instance = fileExplorer
                                toggleApp(app)
                                break
                            end
                        end
                    else
                        -- Launch file
                        -- We need a global way to open files. 
                        -- For now, let's trigger the file opening logic by simulating a double click in a temporary FilesApp or similar.
                        -- Actually, let's just use the same logic as FilesApp:openSelectedEntry
                        openFileDirectly(targetNode)
                    end
                end
                return
            end
        end
    end

    -- 5. Desktop Background Right Click
    if button == 2 and not onIcon then
        contextMenuOpen = true
        contextMenuX = x
        contextMenuY = y
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
        
        -- Fixed dragging bounds (allow hitting top boundary)
        draggingWindow.y = math.max(0, draggingWindow.y)
        draggingWindow.y = math.min(love.graphics.getHeight() - bottomBarHeight - 30, draggingWindow.y)
        draggingWindow.x = math.max(-draggingWindow.width + 50, draggingWindow.x)
        draggingWindow.x = math.min(love.graphics.getWidth() - 50, draggingWindow.x)
    elseif draggingIcon then
        desktopLayout[draggingIcon.name].x = x - dragIconOffsetX
        desktopLayout[draggingIcon.name].y = y - dragIconOffsetY
    elseif scrollBarDragging then
        local menuHeight = math.min(500, love.graphics.getHeight() - bottomBarHeight)
        local menuY = love.graphics.getHeight() - bottomBarHeight - menuHeight
        local scrollTrackHeight = menuHeight
        local relativeY = y - menuY - scrollBarDragOffset
        startMenuScroll = (relativeY / (scrollTrackHeight - scrollBarHeight)) * startMenuMaxScroll
        startMenuScroll = math.max(0, math.min(startMenuScroll, startMenuMaxScroll))
    end
    
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.mousemoved then
        -- Send consistent relative coordinates matching mousepressed
        local relX = x - focusedWindow.x
        local relY = y - focusedWindow.y - 30
        focusedWindow.instance:mousemoved(relX, relY, dx, dy, x, y)
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and contextMenuOpen then
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
            local data = json.encode(desktopLayout)
            love.filesystem.write("desktop_layout.json", data)
        end
    end
    
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.mousereleased then
        -- Send consistent relative coordinates matching mousepressed
        local relX = x - focusedWindow.x
        local relY = y - focusedWindow.y - 30
        focusedWindow.instance:mousereleased(relX, relY, button, x, y)
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
    if propertiesWindow then
        propertiesWindow.renameInput = propertiesWindow.renameInput .. text
        return
    end
    if focusedWindow and (not focusedWindow.minimized) and focusedWindow.instance and focusedWindow.instance.textinput then
        focusedWindow.instance:textinput(text)
    end
end

function love.keypressed(key)
    if propertiesWindow then
        if key == "backspace" then
            local byteoffset = utf8.offset(propertiesWindow.renameInput, -1)
            if byteoffset then
                propertiesWindow.renameInput = string.sub(propertiesWindow.renameInput, 1, byteoffset - 1)
            end
        elseif key == "return" then
            -- Trigger the apply button logic manually or similar
            local pw = propertiesWindow
            if pw.renameInput ~= "" and pw.renameInput ~= pw.node.name then
                filesystemModule.rename(pw.node, pw.renameInput)
                refreshDesktopLayout()
                for _, win in ipairs(openApps) do
                    if win.app.name == "Files" and win.instance then win.instance:updateFileList() end
                end
            end
            propertiesWindow = nil
        elseif key == "escape" then
            propertiesWindow = nil
        end
        return
    end
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
    refreshDesktopLayout()
    
    -- Resize visual effects when screen resolution updates
    if effect and effect.resize then
        effect.resize(w, h)
    end
end

function _G.openFileDirectly(node)
    local ext = node.name:match("^.+(%..+)$") or ""
    ext = ext:lower()

    if ext == ".obj" then
        local viewer = ObjViewer.new(filesystemModule.getPath(node), node)
        for i, app in ipairs(apps) do
            if app.name == "ObjViewer" then
                app.instance = viewer
                toggleApp(app)
                break
            end
        end
    elseif ext == ".png" or ext == ".jpg" or ext == ".jpeg" then
        local viewer = ImageViewer.new(filesystemModule.getPath(node), node)
        for i, app in ipairs(apps) do
            if app.name == "ImageViewer" then
                app.instance = viewer
                toggleApp(app)
                break
            end
        end
    else
        local editor = TextEditor.new(filesystemModule.getPath(node), node)
        if node.content and node.content ~= "" then
            editor.lines = {}
            for line in node.content:gmatch("([^\n]*)\n?") do
                table.insert(editor.lines, line)
            end
        else
            editor.lines = {""}
        end
        editor.filename = node.name
        editor.fileNode = node
        for i, app in ipairs(apps) do
            if app.name == "TextEditor" then
                app.instance = editor
                toggleApp(app)
                break
            end
        end
    end
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
        if (app.name == "TextEditor" or app.name == "ImageViewer" or app.name == "ObjViewer" or app.name == "Files") and app.instance then
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