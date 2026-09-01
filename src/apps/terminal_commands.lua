-- src/apps/terminal_commands.lua
local filesystem = require("src.core.filesystem")
local TerminalCommands = {}

-- Custom argument parser that supports quoted strings.
local function parseArgs(input)
    local args = {}
    local current = ""
    local inQuotes = false
    local i = 1
    while i <= #input do
        local c = input:sub(i, i)
        if c == '"' then
            inQuotes = not inQuotes
        elseif c:match("%s") and not inQuotes then
            if #current > 0 then
                table.insert(args, current)
                current = ""
            end
        else
            current = current .. c
        end
        i = i + 1
    end
    if #current > 0 then
        table.insert(args, current)
    end
    return args
end

-- Color parsing function
local function parseColor(colorStr)
    local colorMap = {
        black = {0, 0, 0},
        white = {1, 1, 1},
        red = {1, 0, 0},
        green = {0, 1, 0},
        blue = {0, 0, 1},
        yellow = {1, 1, 0},
        cyan = {0, 1, 1},
        magenta = {1, 0, 1},
        gray = {0.5, 0.5, 0.5},
        orange = {1, 0.5, 0},
        purple = {0.5, 0, 0.5},
        pink = {1, 0.5, 0.5},
        brown = {0.6, 0.3, 0}
    }
    
    if colorMap[colorStr:lower()] then
        return colorMap[colorStr:lower()]
    end
    
    if colorStr:match("^#%x%x%x%x%x%x$") then
        local r = tonumber(colorStr:sub(2, 3), 16) / 255
        local g = tonumber(colorStr:sub(4, 5), 16) / 255
        local b = tonumber(colorStr:sub(6, 7), 16) / 255
        return {r, g, b}
    end   
    
    if colorStr:match("^#%x%x%x%x%x%x%x%x$") then
        local r = tonumber(colorStr:sub(2, 3), 16) / 255
        local g = tonumber(colorStr:sub(4, 5), 16) / 255
        local b = tonumber(colorStr:sub(6, 7), 16) / 255
        local a = tonumber(colorStr:sub(8, 9), 16) / 255
        return {r, g, b, a}
    end
    
    local r, g, b = colorStr:match("^(%d+%.?%d*),(%d+%.?%d*),(%d+%.?%d*)$")
    if r and g and b then
        return {tonumber(r), tonumber(g), tonumber(b)}
    end
    
    return nil
end

-- Helper: print output to the terminal.
function TerminalCommands.print(self, text)
    table.insert(self.rawLines, text)
end

-- Helper: resolve a path into its parts.
local function resolvePathParts(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Given a cwd and a path, return the node at that path.
local function navigatePath(cwd, path)
    local node
    if path:sub(1,1) == "/" then
        node = filesystem.getFS()
        path = path:sub(2)
    else
        node = cwd
    end
    local parts = resolvePathParts(path)
    for _, part in ipairs(parts) do
        if part == ".." then
            if node.parent then
                node = node.parent
            else
                return nil, "Already at root"
            end
        else
            if node.children and node.children[part] then
                node = node.children[part]
            else
                return nil, "Not found: " .. part
            end
        end
    end
    return node
end

-- For commands like touch/mv, resolve the parent directory and file name.
local function resolveParentAndName(cwd, path)
    local node
    if path:sub(1,1) == "/" then
        node = filesystem.getFS()
        path = path:sub(2)
    else
        node = cwd
    end
    local parts = resolvePathParts(path)
    if #parts == 0 then return nil, "Invalid path" end
    local name = table.remove(parts)
    for _, part in ipairs(parts) do
        if part == ".." then
            if node.parent then
                node = node.parent
            else
                return nil, "Invalid path (above root)"
            end
        else
            if node.children and node.children[part] then
                node = node.children[part]
            else
                return nil, "Directory not found: " .. part
            end
        end
    end
    return node, name
end

-- Recursive file search function
local function searchFiles(node, pattern, results, currentPath)
    currentPath = currentPath or ""
    if not node or not node.children then return end
    
    for name, child in pairs(node.children) do
        local fullPath = currentPath .. "/" .. name
        if child.type == "file" then
            -- Check if filename matches pattern
            if name:lower():find(pattern:lower(), 1, true) or
               (child.content and child.content:lower():find(pattern:lower(), 1, true)) then
                table.insert(results, {
                    path = fullPath,
                    name = name,
                    type = "file",
                    size = child.content and #child.content or 0
                })
            end
        elseif child.type == "directory" then
            searchFiles(child, pattern, results, fullPath)
        end
    end
end

-- Inline substitutions table: all built-in command functions.
local inlineSubstitutions = {
    -- ============================================================
    -- BASIC COMMANDS
    -- ============================================================
    help = function(self, ...)
        self:print("+ Lynux Terminal v2.0 - Command Reference -----------------------+")
        self:print("|                                                                 |")
        self:print("| BASIC:        help, clear, echo, set, vars                      |")
        self:print("| NAVIGATION:   ls, pwd, cd, tree                                 |")
        self:print("| FILE OPS:     touch, rm, rmall, mv, cat, mkdir                  |")
        self:print("| SEARCH:       find, grep, locate, which                         |")
        self:print("| SYSTEM:       date, time, version, uname, whoami, uptime        |")
        self:print("| TERMINAL:     color, title, history, clearh, theme              |")
        self:print("| DESKTOP:      open, apps, notify, wallpaper                     |")
        self:print("| GAME:         stats, flags, task, chapter, save, load           |")
        self:print("| UTILITY:      calc, repeat, alias, sleep, yes                   |")
        self:print("+-----------------------------------------------------------------+")
    end,
    
    clear = function(self, ...)
        self.rawLines = {}
        self.scrollOffset = 0
    end,
    
    echo = function(self, ...)
        return table.concat({...}, " ")
    end,
    
    set = function(self, varName, ...)
        local data = table.concat({...}, " ")
        self.variables = self.variables or {}
        self.variables[varName] = data
        return "Set " .. varName .. " = " .. data
    end,
    
    vars = function(self, ...)
        local result = {}
        for k, v in pairs(self.variables or {}) do
            table.insert(result, "  " .. k .. " = " .. v)
        end
        if #result == 0 then
            return "No variables set."
        end
        return table.concat(result, "\n")
    end,
    
    -- ============================================================
    -- NAVIGATION COMMANDS
    -- ============================================================
    ls = function(self, path)
        local target = self.cwd
        if path then
            local node, err = navigatePath(self.cwd, path)
            if not node then return err end
            if node.type ~= "directory" then return "Not a directory: " .. path end
            target = node
        end
        
        local list = {}
        local dirs = {}
        local files = {}
        
        for name, node in pairs(target.children or {}) do
            if node.type == "directory" then
                table.insert(dirs, name .. "/")
            else
                local size = node.content and #node.content or 0
                table.insert(files, name .. " (" .. size .. " bytes)")
            end
        end
        
        table.sort(dirs)
        table.sort(files)
        
        for _, d in ipairs(dirs) do table.insert(list, d) end
        for _, f in ipairs(files) do table.insert(list, f) end
        
        if #list == 0 then return "Directory is empty." end
        return table.concat(list, "  ")
    end,
    
    pwd = function(self, ...)
        return filesystem.getPath(self.cwd)
    end,
    
    cd = function(self, target)
        if not target then 
            self.cwd = self.filesystem
            return "Changed to root directory"
        end
        local node, err = navigatePath(self.cwd, target)
        if node then
            if node.type == "directory" then
                self.cwd = node
                return "Changed to: " .. filesystem.getPath(node)
            else
                return "Not a directory: " .. target
            end
        else
            return err
        end
    end,
    
    tree = function(self, path)
        local target = self.cwd
        if path then
            local node, err = navigatePath(self.cwd, path)
            if not node then return err end
            if node.type ~= "directory" then return "Not a directory: " .. path end
            target = node
        end
        
        local treeLines = filesystem.generateTree(target, "")
        if #treeLines == 0 then return "Directory is empty." end
        return table.concat(treeLines, "\n")
    end,
    
    -- ============================================================
    -- FILE OPERATIONS
    -- ============================================================
    mkdir = function(self, dirname)
        if not dirname then return "Usage: mkdir <directory>" end
        local parent, name = resolveParentAndName(self.cwd, dirname)
        if not parent then return name end
        if parent.children[name] then
            return "Already exists: " .. dirname
        else
            local newdir = { name = name, type = "directory", parent = parent, children = {} }
            parent.children[name] = newdir
            filesystem.save(self.filesystem)
            return "Directory created: " .. dirname
        end
    end,
    
    touch = function(self, filename, ...)
        if not filename then return "Usage: touch <file> [data]" end
        local parent, name = resolveParentAndName(self.cwd, filename)
        if not parent then return name end
        if parent.children[name] then
            return "Already exists: " .. filename
        else
            local content = table.concat({...}, " ")
            local newfile = { name = name, type = "file", content = content, parent = parent }
            parent.children[name] = newfile
            filesystem.save(self.filesystem)
            return "File created: " .. filename
        end
    end,
    
    rm = function(self, path)
        if not path then return "Usage: rm <file|directory>" end
        local parent, name = resolveParentAndName(self.cwd, path)
        if not parent then return name end
        local node = parent.children[name]
        if not node then return "Not found: " .. path end
        if node.type == "directory" then
            if next(node.children or {}) ~= nil then
                return "Directory not empty: " .. path
            else
                parent.children[name] = nil
                filesystem.save(self.filesystem)
                return "Removed directory: " .. path
            end
        else
            parent.children[name] = nil
            filesystem.save(self.filesystem)
            return "Removed file: " .. path
        end
    end,
    
    rmall = function(self, path)
        if not path then return "Usage: rmall <directory>" end
        local parent, name = resolveParentAndName(self.cwd, path)
        if not parent then return name end
        local node = parent.children[name]
        if not node then return "Not found: " .. path end
        parent.children[name] = nil
        filesystem.save(self.filesystem)
        return "Removed " .. path
    end,
    
    mv = function(self, src, dst)
        if not src or not dst then return "Usage: mv <source> <destination>" end
        local srcParent, srcName = resolveParentAndName(self.cwd, src)
        if not srcParent then return srcName end
        local node = srcParent.children[srcName]
        if not node then return "Source not found: " .. src end
        local dstParent, dstName = resolveParentAndName(self.cwd, dst)
        if not dstParent then return dstName end
        if dstParent.children[dstName] then return "Destination already exists: " .. dst end
        srcParent.children[srcName] = nil
        node.name = dstName
        node.parent = dstParent
        dstParent.children[dstName] = node
        filesystem.save(self.filesystem)
        return "Moved/Renamed " .. src .. " to " .. dst
    end,
    
    cat = function(self, filename)
        if not filename then return "Usage: cat <file>" end
        local parent, name = resolveParentAndName(self.cwd, filename)
        if not parent then return name end
        local node = parent.children[name]
        if not node then return "No such file: " .. filename end
        if node.type ~= "file" then return filename .. " is not a file." end
        if node.content == "" then return "File is empty." end
        return node.content
    end,
    
    -- ============================================================
    -- SEARCH COMMANDS
    -- ============================================================
    find = function(self, pattern)
        if not pattern then return "Usage: find <pattern>" end
        local fs = filesystem.getFS()
        local results = {}
        searchFiles(fs, pattern, results, "")
        
        if #results == 0 then
            return "No files found matching: " .. pattern
        end
        
        local output = {"Found " .. #results .. " file(s) matching '" .. pattern .. "':"}
        for _, r in ipairs(results) do
            output[#output + 1] = "  " .. r.path .. " (" .. r.size .. " bytes)"
        end
        return table.concat(output, "\n")
    end,
    
    grep = function(self, pattern, filePath)
        if not pattern then return "Usage: grep <pattern> [file]" end
        
        -- If filePath is provided, search that specific file
        if filePath then
            local parent, name = resolveParentAndName(self.cwd, filePath)
            if not parent then return name end
            local node = parent.children[name]
            if not node then return "No such file: " .. filePath end
            if node.type ~= "file" then return filePath .. " is not a file." end
            
            local lines = {}
            for line in (node.content or ""):gmatch("([^\n]*)\n?") do
                if line:lower():find(pattern:lower(), 1, true) then
                    table.insert(lines, line)
                end
            end
            if #lines == 0 then
                return "No matches found in " .. filePath
            end
            return "Matches in " .. filePath .. ":\n" .. table.concat(lines, "\n")
        end
        
        -- Otherwise search all files
        local fs = filesystem.getFS()
        local results = {}
        searchFiles(fs, pattern, results, "")
        
        if #results == 0 then
            return "No files contain: " .. pattern
        end
        
        local output = {"Files containing '" .. pattern .. "':"}
        for _, r in ipairs(results) do
            output[#output + 1] = "  " .. r.path
        end
        return table.concat(output, "\n")
    end,
    
    locate = function(self, filename)
        if not filename then return "Usage: locate <filename>" end
        local fs = filesystem.getFS()
        local results = {}
        
        local function searchByName(node, path)
            if not node or not node.children then return end
            for name, child in pairs(node.children) do
                local fullPath = path .. "/" .. name
                if name:lower():find(filename:lower(), 1, true) then
                    table.insert(results, {
                        path = fullPath,
                        type = child.type or "unknown"
                    })
                end
                if child.type == "directory" then
                    searchByName(child, fullPath)
                end
            end
        end
        
        searchByName(fs, "")
        
        if #results == 0 then
            return "No files found with name containing: " .. filename
        end
        
        local output = {"Files matching '" .. filename .. "':"}
        for _, r in ipairs(results) do
            output[#output + 1] = "  " .. r.path .. " (" .. r.type .. ")"
        end
        return table.concat(output, "\n")
    end,
    
    which = function(self, command)
        if not command then return "Usage: which <command>" end
        
        -- Check if command exists in our built-in commands
        if inlineSubstitutions[command] then
            return command .. " is a built-in Lynux Terminal command"
        end
        
        -- Check for .sh scripts in current directory
        local parent, name = resolveParentAndName(self.cwd, command .. ".sh")
        if parent and parent.children[name] then
            return command .. " is a script at " .. filesystem.getPath(self.cwd) .. "/" .. command .. ".sh"
        end
        
        -- Check in standard paths
        local standardPaths = {
            "/home/user/scripts/",
            "/usr/bin/",
            "/usr/local/bin/"
        }
        
        for _, stdPath in ipairs(standardPaths) do
            local node, err = navigatePath(self.filesystem, stdPath .. command)
            if node and node.type == "file" then
                return command .. " found at " .. stdPath .. command
            end
            -- Check with .sh extension
            local nodeSh, _ = navigatePath(self.filesystem, stdPath .. command .. ".sh")
            if nodeSh and nodeSh.type == "file" then
                return command .. " found at " .. stdPath .. command .. ".sh"
            end
        end
        
        return "Command not found: " .. command
    end,
    
    -- ============================================================
    -- SYSTEM COMMANDS
    -- ============================================================
    date = function(self, ...)
        return os.date("%Y-%m-%d")
    end,
    
    time = function(self, ...)
        return os.date("%H:%M:%S")
    end,
    
    version = function(self, ...)
        return "Lynux Terminal v2.0"
    end,
    
    uname = function(self, ...)
        return "user@lynux"
    end,
    
    whoami = function(self, ...)
        return "user"
    end,
    
    uptime = function(self, ...)
        local time = love.timer.getTime()
        local days = math.floor(time / 86400)
        local hours = math.floor((time % 86400) / 3600)
        local minutes = math.floor((time % 3600) / 60)
        local seconds = math.floor(time % 60)
        return string.format("System uptime: %02d:%02d:%02d:%02d", days, hours, minutes, seconds)
    end,
    
    -- ============================================================
    -- TERMINAL COMMANDS
    -- ============================================================
    color = function(self, ...)
        local args = {...}
        if #args == 0 then
            return "Usage: color <element> <color> OR color preset <preset_name>"
        end
        
        if args[1] == "preset" then
            local presets = {
                classic = {
                    background = {0.05, 0.05, 0.1, 0.8},
                    text = {0.8, 1, 0.8},
                    prompt = {0.2, 0.8, 1}
                },
                dark = {
                    background = {0.1, 0.1, 0.1, 0.8},
                    text = {0.9, 0.9, 0.9},
                    prompt = {0, 0.8, 0}
                },
                blue = {
                    background = {0, 0.1, 0.2, 0.8},
                    text = {0.7, 0.9, 1},
                    prompt = {0.2, 0.6, 1}
                },
                green = {
                    background = {0, 0.1, 0, 0.8},
                    text = {0.6, 1, 0.6},
                    prompt = {0.2, 1, 0.2}
                },
                amber = {
                    background = {0.1, 0.08, 0, 0.6},
                    text = {1, 0.8, 0.3},
                    prompt = {1, 0.6, 0}
                },
                windows = {
                    background = {0.05, 0.05, 0.05, 0.95},
                    text = {1, 1, 1},
                    prompt = {0, 0.47, 0.84},
                    error = {0.9, 0.1, 0.1},
                    success = {0.1, 0.8, 0.1},
                    directory = {0, 0.6, 0.9},
                    file = {0.9, 0.9, 0.9}
                },
                powershell = {
                    background = {0.01, 0.14, 0.33, 0.95},
                    text = {1, 1, 1},
                    prompt = {1, 1, 1},
                    directory = {1, 1, 0}
                }
            }
            
            local presetName = args[2] or "classic"
            if presets[presetName] then
                self:setColors(presets[presetName])
                return "Theme set to: " .. presetName
            else
                return "Available presets: classic, dark, blue, green, amber, windows, powershell"
            end
        end
        
        local element = args[1]
        local colorStr = args[2]
        
        if not colorStr then
            return "Usage: color <"..table.concat({"background", "text", "prompt", "error", "success", "directory", "file"}, "|").."> <color>"
        end
        
        local color = parseColor(colorStr)
        if not color then
            return "Invalid color. Use: color name, #RRGGBB, #RRGGBBAA, or r,g,b values"
        end
        
        local elements = {
            background = true, text = true, prompt = true,
            error = true, success = true, directory = true, file = true
        }
        
        if elements[element] then
            local newColors = {[element] = color}
            self:setColors(newColors)
            return "Set " .. element .. " color to " .. colorStr
        else
            return "Invalid element. Use: background, text, prompt, error, success, directory, file"
        end
    end,
    
    title = function(self, ...)
        local newTitle = table.concat({...}, " ")
        if #newTitle == 0 then
            return "Current title: " .. self.title
        end
        self:setTitle(newTitle)
        return "Terminal title set to: " .. newTitle
    end,
    
    history = function(self, ...)
        local history = self:getCommandHistory()
        if #history == 0 then
            return "No command history"
        end
        
        local result = {"Command History:"}
        for i, cmd in ipairs(history) do
            table.insert(result, string.format("  %3d: %s", i, cmd))
        end
        return table.concat(result, "\n")
    end,
    
    clearh = function(self, ...)
        self:clearHistory()
        return "Command history cleared"
    end,
    
    theme = function(self, name)
        if not name then
            return "Usage: theme <default|unix|monokai|one_dark>"
        end
        
        if self:applyTheme(name:lower()) then
            return "Theme changed to " .. name
        else
            return "Unknown theme: " .. name .. ". Try: default, unix, monokai, one_dark"
        end
    end,
    
    -- ============================================================
    -- DESKTOP COMMANDS
    -- ============================================================
    open = function(self, appName)
        if not appName then return "Usage: open <app_name>" end
        
        local DesktopManager = require("src.desktop.desktop_mgr")
        local app = DesktopManager.openAppByName(appName)
        
        if app then
            return "Opened " .. appName
        else
            return "App not found: " .. appName .. ". Try: Email, Chat, Browser, Terminal, Files, TextEditor, Settings"
        end
    end,
    
    apps = function(self, ...)
        local DesktopManager = require("src.desktop.desktop_mgr")
        local apps = {}
        for _, app in ipairs(DesktopManager.apps) do
            table.insert(apps, app.name)
        end
        return "Available apps: " .. table.concat(apps, ", ")
    end,
    
    notify = function(self, title, message)
        if not title then return "Usage: notify <title> <message>" end
        local Notifications = require("src.desktop.notifications")
        Notifications.add(title, message or "", nil, 4.0)
        return "Notification sent"
    end,
    
    wallpaper = function(self, name)
        if not name then return "Usage: wallpaper <name>" end
        
        local DesktopManager = require("src.desktop.desktop_mgr")
        -- Find wallpaper by name
        local found = false
        for _, wp in ipairs(DesktopManager.availableWallpapers or {}) do
            if wp.name:lower():find(name:lower(), 1, true) then
                DesktopManager.currentWallpaper = wp
                found = true
                break
            end
        end
        
        if found then
            return "Wallpaper changed to: " .. name
        else
            return "Wallpaper not found: " .. name
        end
    end,
    
    -- ============================================================
    -- GAME COMMANDS
    -- ============================================================
    stats = function(self, ...)
        local PlayerStats = require("src.core.player_stats")
        return string.format(
            "Level: %d | Title: %s | XP: %d/%d (%.1f%%)",
            PlayerStats.level,
            PlayerStats.title,
            PlayerStats.xp,
            PlayerStats.xpForNextLevel,
            (PlayerStats.xp / PlayerStats.xpForNextLevel) * 100
        )
    end,
    
    flags = function(self, pattern)
        local PlayerStats = require("src.core.player_stats")
        local flags = {}
        for k, v in pairs(PlayerStats.flags) do
            if not pattern or k:find(pattern, 1, true) then
                table.insert(flags, k .. " = " .. tostring(v))
            end
        end
        table.sort(flags)
        if #flags == 0 then
            return pattern and "No flags match: " .. pattern or "No flags set."
        end
        return "Flags:\n" .. table.concat(flags, "\n")
    end,
    
    task = function(self, ...)
        local TaskManager = require("src.tasks.task_manager")
        local task = TaskManager.getCurrentTask()
        if not task then
            return "No active task."
        end
        
        local status = task.completed and "[DONE]" or "[ACTIVE]"
        local output = {
            string.format("Task: %s %s", status, task.title),
            "Description: " .. task.desc,
            "XP Reward: " .. task.xp,
            "Objectives:"
        }
        
        for i, obj in ipairs(task.objectives or {}) do
            local icon = obj.done and "[✓]" or "[ ]"
            table.insert(output, string.format("  %s %s", icon, obj.text))
        end
        
        return table.concat(output, "\n")
    end,
    
    chapter = function(self, ...)
        local ChapterManager = require("src.chapters.chapter_manager")
        local meta = ChapterManager.getChapterMeta()
        return string.format(
            "Current: Chapter %d - %s\nSubtitle: %s\nDescription: %s",
            meta.id, meta.title, meta.subtitle or "", meta.desc or ""
        )
    end,
    
    save = function(self, ...)
        local SaveManager = require("src.core.save_manager")
        local success = SaveManager.saveGame()
        return success and "Game saved successfully!" or "Failed to save game."
    end,
    
    load = function(self, ...)
        local SaveManager = require("src.core.save_manager")
        local success = SaveManager.loadGame()
        if success then
            return "Game loaded successfully!"
        else
            return "Failed to load game. No save file found."
        end
    end,
    
    -- ============================================================
    -- UTILITY COMMANDS
    -- ============================================================
    calc = function(self, ...)
        local expr = table.concat({...}, " ")
        if #expr == 0 then
            return "Usage: calc <expression>"
        end
        
        local safeExpr = expr:gsub("[^%d%+%-%*%/%.%(%))%s]", "")
        local func, err = load("return " .. safeExpr)
        if func then
            local success, result = pcall(func)
            if success then
                return expr .. " = " .. tostring(result)
            end
        end
        return "Invalid expression: " .. expr
    end,
    
    repeat_cmd = function(self, count, ...)
        if not count or not ... then return "Usage: repeat <count> <command>" end
        local cmd = table.concat({...}, " ")
        local results = {}
        for i = 1, tonumber(count) or 1 do
            table.insert(results, "[" .. i .. "] " .. cmd)
            -- Execute the command
            local args = parseArgs(cmd)
            if #args > 0 then
                local cmdName = args[1]
                if inlineSubstitutions[cmdName] then
                    local result = inlineSubstitutions[cmdName](self, unpack(args, 2))
                    if result then table.insert(results, "  -> " .. result) end
                end
            end
        end
        return table.concat(results, "\n")
    end,
    
    alias = function(self, name, cmd)
        if not name then return "Usage: alias <name> <command>" end
        if not cmd then
            -- Show alias
            local aliases = self.aliases or {}
            if aliases[name] then
                return name .. " = " .. aliases[name]
            else
                return "Alias not found: " .. name
            end
        end
        
        self.aliases = self.aliases or {}
        self.aliases[name] = cmd
        return "Alias set: " .. name .. " = " .. cmd
    end,
    
    sleep = function(self, seconds)
        if not seconds then return "Usage: sleep <seconds>" end
        local secs = tonumber(seconds)
        if not secs then return "Invalid number: " .. seconds end
        -- Simulate sleep by waiting (using love.timer)
        local start = love.timer.getTime()
        while love.timer.getTime() - start < secs do
            -- Small yield
        end
        return "Slept for " .. secs .. " seconds"
    end,
    
    yes = function(self, ...)
        local text = table.concat({...}, " ")
        if text == "" then text = "y" end
        return "yes " .. text .. " (press Ctrl+C to stop)"
        -- In a real terminal this would loop, but we'll just print once
    end
}

-- Process a command string. 'self' is the Terminal instance.
function TerminalCommands.process(self, command)
    local args = parseArgs(command)
    if #args == 0 then return end

    self.variables = self.variables or {}
    self.aliases = self.aliases or {}

    -- Check for aliases first
    if self.aliases[args[1]] then
        command = self.aliases[args[1]]
        args = parseArgs(command)
    end

    -- First, substitute inline function calls and variable references.
    for i, arg in ipairs(args) do
        local funcName, funcArgs = arg:match("^%$(%w+)%((.*)%)$")
        if funcName then
            if inlineSubstitutions[funcName] then
                local parsedArgs = {}
                for token in funcArgs:gmatch("[^,]+") do
                    token = token:gsub("^%s*(.-)%s*$", "%1")
                    token = token:gsub('^"(.*)"$', "%1")
                    table.insert(parsedArgs, token)
                end
                args[i] = inlineSubstitutions[funcName](self, unpack(parsedArgs)) or ""
            else
                args[i] = ""
            end
        elseif arg:sub(1,1) == "$" then
            local varName = arg:sub(2)
            if self.variables[varName] then
                args[i] = self.variables[varName]
            elseif inlineSubstitutions[varName] then
                args[i] = inlineSubstitutions[varName](self) or ""
            else
                args[i] = ""
            end
        end
    end

    local cmd = args[1]
    if inlineSubstitutions[cmd] then
        local result = inlineSubstitutions[cmd](self, unpack(args, 2))
        if result then 
            self:print(result) 
        end
    else
        if command:sub(-3) == ".sh" then
            local parent, name = resolveParentAndName(self.cwd, command)
            if parent and parent.children[name] and parent.children[name].type == "file" then
                local content = parent.children[name].content
                for line in content:gmatch("([^\n]+)") do
                    TerminalCommands.process(self, line)
                end
            else
                self:print("Script file not found: " .. command)
            end
        else 
            self:print("Unknown command: " .. command)
        end
    end

    if self.autoScroll then
        self.scrollOffset = 0
    end
end

return TerminalCommands