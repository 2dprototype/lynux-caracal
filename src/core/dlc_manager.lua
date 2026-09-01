-- src/core/dlc_manager.lua
-- Dynamic DLC & Addon Management Engine for Lynux Caracal

local json = require("lib/json")

local DLCManager = {
    installedDLCs = {},
    loadedApps = {},
    dlcDir = "dlc",
    onDLCsChanged = nil
}

function DLCManager.init()
    DLCManager.installedDLCs = {}
    DLCManager.loadedApps = {}
    DLCManager.scanAndLoad()
end

function DLCManager.scanAndLoad()
    DLCManager.installedDLCs = {}
    DLCManager.loadedApps = {}

    -- Ensure DLC folder exists
    if not love.filesystem.getInfo(DLCManager.dlcDir) then
        pcall(function() love.filesystem.createDirectory(DLCManager.dlcDir) end)
    end

    local items = love.filesystem.getDirectoryItems(DLCManager.dlcDir) or {}
    table.sort(items)

    for _, item in ipairs(items) do
        local itemPath = DLCManager.dlcDir .. "/" .. item
        local info = love.filesystem.getInfo(itemPath)
        if info then
            if info.type == "directory" then
                DLCManager.loadPackage(item, itemPath)
            elseif info.type == "file" and item:match("%.lua$") then
                DLCManager.loadSingleFileDLC(item, itemPath)
            end
        end
    end

    print(string.format("[DLCManager] Loaded %d DLC package(s) and %d DLC app(s)", #DLCManager.installedDLCs, #DLCManager.loadedApps))
end

-- Load a full folder-based DLC package (with dlc.json/manifest.json and init.lua or apps/)
function DLCManager.loadPackage(id, folderPath)
    local manifestPath = folderPath .. "/dlc.json"
    if not love.filesystem.getInfo(manifestPath) then
        manifestPath = folderPath .. "/manifest.json"
    end

    local meta = {
        id = id,
        name = id:gsub("_", " "):gsub("^%l", string.upper),
        version = "1.0.0",
        author = "Community",
        description = "DLC Addon for Lynux Caracal",
        enabled = true,
        apps = {}
    }

    if love.filesystem.getInfo(manifestPath) then
        local raw = love.filesystem.read(manifestPath)
        if raw then
            local ok, parsed = pcall(json.decode, raw)
            if ok and type(parsed) == "table" then
                for k, v in pairs(parsed) do
                    meta[k] = v
                end
            end
        end
    end

    if meta.enabled == false then
        table.insert(DLCManager.installedDLCs, meta)
        return
    end

    local dlcRecord = {
        id = meta.id or id,
        name = meta.name or id,
        version = meta.version or "1.0",
        author = meta.author or "Unknown",
        description = meta.description or "",
        path = folderPath,
        enabled = true,
        loadedApps = {}
    }

    -- 1. Try executing init.lua if present
    local initPath = folderPath .. "/init.lua"
    if love.filesystem.getInfo(initPath) then
        local chunk, err = love.filesystem.load(initPath)
        if chunk then
            local ok, result = pcall(chunk, folderPath, dlcRecord)
            if ok and type(result) == "table" then
                if result.new or result.draw then
                    -- Single app module returned directly
                    local appDef = {
                        name = meta.name or id,
                        module = result,
                        width = meta.defaultWidth or 520,
                        height = meta.defaultHeight or 360,
                        description = meta.description,
                        category = meta.category or "Utilities",
                        isDLC = true,
                        dlcId = dlcRecord.id
                    }
                    DLCManager.registerApp(appDef, dlcRecord)
                elseif #result > 0 then
                    -- List of app definitions returned
                    for _, appDef in ipairs(result) do
                        appDef.isDLC = true
                        appDef.dlcId = dlcRecord.id
                        DLCManager.registerApp(appDef, dlcRecord)
                    end
                end
            end
        else
            print("[DLCManager Error] Failed to load " .. initPath .. ": " .. tostring(err))
        end
    end

    -- 2. Scan apps/ subfolder if present
    local appsDir = folderPath .. "/apps"
    if love.filesystem.getInfo(appsDir) and love.filesystem.getInfo(appsDir).type == "directory" then
        local appFiles = love.filesystem.getDirectoryItems(appsDir) or {}
        for _, appFile in ipairs(appFiles) do
            if appFile:match("%.lua$") then
                local appPath = appsDir .. "/" .. appFile
                local chunk, err = love.filesystem.load(appPath)
                if chunk then
                    local ok, appModule = pcall(chunk)
                    if ok and type(appModule) == "table" then
                        local appBaseName = appFile:gsub("%.lua$", "")
                        local appDef = {
                            name = appModule.name or appBaseName,
                            module = appModule,
                            width = appModule.defaultWidth or 520,
                            height = appModule.defaultHeight or 360,
                            icon = appModule.icon,
                            description = appModule.description or meta.description,
                            category = appModule.category or "Utilities",
                            isDLC = true,
                            dlcId = dlcRecord.id
                        }
                        DLCManager.registerApp(appDef, dlcRecord)
                    end
                end
            end
        end
    end

    table.insert(DLCManager.installedDLCs, dlcRecord)
end

-- Load a single standalone .lua file placed directly inside dlc/
function DLCManager.loadSingleFileDLC(fileName, filePath)
    local appName = fileName:gsub("%.lua$", "")
    local chunk, err = love.filesystem.load(filePath)
    if chunk then
        local ok, appModule = pcall(chunk)
        if ok and type(appModule) == "table" then
            local dlcRecord = {
                id = appName:lower(),
                name = appModule.name or appName,
                version = appModule.version or "1.0",
                author = appModule.author or "Community",
                description = appModule.description or "Standalone DLC App",
                path = filePath,
                enabled = true,
                loadedApps = {}
            }
            local appDef = {
                name = appModule.name or appName,
                module = appModule,
                width = appModule.defaultWidth or 520,
                height = appModule.defaultHeight or 360,
                icon = appModule.icon,
                description = appModule.description or dlcRecord.description,
                category = appModule.category or "Utilities",
                isDLC = true,
                dlcId = dlcRecord.id
            }
            DLCManager.registerApp(appDef, dlcRecord)
            table.insert(DLCManager.installedDLCs, dlcRecord)
        end
    end
end

-- Register an app definition into DesktopManager
function DLCManager.registerApp(appDef, dlcRecord)
    if not appDef or not appDef.name or not appDef.module then return end

    -- Generate icon if not provided
    if not appDef.icon then
        -- Default icon lookup based on category
        local iconCandidates = {
            "assets/box.png",
            "assets/file.png",
            "assets/layers.png"
        }
        for _, path in ipairs(iconCandidates) do
            if love.filesystem.getInfo(path) then
                local ok, img = pcall(love.graphics.newImage, path)
                if ok and img then
                    appDef.icon = img
                    break
                end
            end
        end
    end

    table.insert(DLCManager.loadedApps, appDef)
    if dlcRecord then
        table.insert(dlcRecord.loadedApps, appDef)
    end
end

function DLCManager.getLoadedApps()
    return DLCManager.loadedApps
end

function DLCManager.getInstalledDLCs()
    return DLCManager.installedDLCs
end

-- Hot-reload DLCs and refresh desktop
function DLCManager.reload()
    DLCManager.scanAndLoad()
    local DesktopManager = require("src.desktop.desktop_mgr")
    if DesktopManager and DesktopManager.reloadApps then
        DesktopManager.reloadApps()
    end
end

return DLCManager
