-- filesystem.lua
local json = require "lib/json"  -- make sure you have a JSON module available

local filesystem = {}

-- The shared file system instance (lazy loaded)
local sharedFS = nil

-- Recursively "sanitize" a node so it can be saved (remove parent pointers, etc.)
function filesystem.sanitize(node)
    local t = { 
        name = node.name, 
        type = node.type,
        created = node.created,
        modified = node.modified
    }
    if node.type == "directory" then
        t.children = {}
        for k, child in pairs(node.children or {}) do
            t.children[k] = filesystem.sanitize(child)
        end
    elseif node.type == "file" then
        t.content = node.content
    end
    return t
end


-- Recursively restore parent pointers (after loading from file)
function filesystem.restore(node, parent)
    node.parent = parent
    if node.type == "directory" and node.children then
        -- Handle both array-style and object-style children
        local newChildren = {}
        
        if type(node.children) == "table" then
            -- Check if it's an array (sequential indices) or object (named keys)
            local isArray = true
            local maxIdx = 0
            for k, v in pairs(node.children) do
                if type(k) == "number" then
                    maxIdx = math.max(maxIdx, k)
                else
                    isArray = false
                    break
                end
            end
            
            if isArray and maxIdx > 0 then
                -- Convert array to object structure
                for i, child in ipairs(node.children) do
                    if type(child) == "table" and child.name then
                        newChildren[child.name] = child
                        filesystem.restore(child, node)
                    end
                end
                node.children = newChildren
            else
                -- Object-style children (regular case)
                for k, child in pairs(node.children) do
                    if type(child) == "table" then
                        filesystem.restore(child, node)
                    end
                end
            end
        end
    end
end
-- Recursively restore parent pointers (after loading from file)
-- function filesystem.restore(node, parent)
    -- node.parent = parent
    -- if node.type == "directory" and node.children then
        -- for k, child in pairs(node.children) do
            -- filesystem.restore(child, node)
        -- end
    -- end
-- end

-- Save the file system to disk.
function filesystem.save(fs)
    local fsSanitized = filesystem.sanitize(fs)
    local data = json.encode(fsSanitized, { indent = true })
    love.filesystem.write("filesystem.json", data)
end

-- Load the file system from disk (or load default from "data/filesystem.json" if it does not exist).
function filesystem.load()
    local fs = { name = "/", type = "directory", parent = nil, children = {} }
    local data, fsLoaded

    if love.filesystem.getInfo("filesystem.json") then
        data = love.filesystem.read("filesystem.json")
        fsLoaded = json.decode(data)
        if fsLoaded then
            fs = fsLoaded
            filesystem.restore(fs, nil)
        end
    elseif love.filesystem.getInfo("data/filesystem.json") then
        -- Load default file system data if no saved filesystem exists.
        data = love.filesystem.read("data/filesystem.json")
        fsLoaded = json.decode(data)
        if fsLoaded then
            fs = fsLoaded
            filesystem.restore(fs, nil)
        end
    end

    return fs
end

-- Returns the shared file system; load it only once.
function filesystem.getFS()
    if not sharedFS then
        sharedFS = filesystem.load()
    end
    return sharedFS
end

function filesystem.getPath(node)
    local parts = {}
    while node do
        parts[#parts + 1] = node.name
        node = node.parent
    end
    -- Reverse the parts table.
    for i = 1, math.floor(#parts / 2) do
        parts[i], parts[#parts - i + 1] = parts[#parts - i + 1], parts[i]
    end
    -- If the first element is "/" or empty, remove it and prepend a single slash.
    if parts[1] == "/" or parts[1] == "" then
        table.remove(parts, 1)
        return "/" .. table.concat(parts, "/")
    else
        return table.concat(parts, "/")
    end
end

function filesystem.updateModified(node)
    if node then
        node.modified = os.time()
        filesystem.save(filesystem.getFS())
    end
end

-- Create a new directory
function filesystem.createDirectory(parent, name)
    if not parent.children then
        parent.children = {}
    end
    
    local baseName = name
    local counter = 1
    while parent.children[name] do
        name = baseName .. " (" .. counter .. ")"
        counter = counter + 1
    end
    
    local currentTime = os.time()
    parent.children[name] = {
        name = name,
        type = "directory",
        parent = parent,
        children = {},
        created = currentTime,
        modified = currentTime
    }
    
    -- Also update parent's modified time
    filesystem.updateModified(parent)
    filesystem.save(filesystem.getFS())
    return parent.children[name]
end

-- Create a new file
function filesystem.createFile(parent, name, content)
    if not parent.children then
        parent.children = {}
    end
    
    content = content or ""
    
    local baseName = name:gsub("%..+$", "")
    local ext = name:match("(%..+)$") or ""
    local counter = 1
    while parent.children[name] do
        name = baseName .. " (" .. counter .. ")" .. ext
        counter = counter + 1
    end
    
    local currentTime = os.time()
    parent.children[name] = {
        name = name,
        type = "file",
        parent = parent,
        content = content,
        created = currentTime,
        modified = currentTime
    }
    
    -- Update parent's modified time
    filesystem.updateModified(parent)
    filesystem.save(filesystem.getFS())
    return parent.children[name]
end

-- Delete a node
function filesystem.delete(node)
    if not node.parent then return false end
    local parent = node.parent
    node.parent.children[node.name] = nil
    filesystem.updateModified(parent)
    filesystem.save(filesystem.getFS())
    return true
end

-- Rename a node
function filesystem.rename(node, newName)
    if not node.parent then return false end
    if node.parent.children[newName] then return false end
    
    local oldName = node.name
    node.parent.children[oldName] = nil
    node.name = newName
    node.parent.children[newName] = node
    
    -- Update modification time
    filesystem.updateModified(node)
    filesystem.updateModified(node.parent)
    filesystem.save(filesystem.getFS())
    return true
end

-- Move a node to a new parent (Cut/Paste)
function filesystem.move(node, newParent)
    if not node.parent or not newParent.children then return false end
    
    local name = node.name
    local baseName = name:match("(.+)%..+") or name
    local ext = name:match("(%..+)$") or ""
    if node.type == "directory" then baseName = name; ext = "" end
    local counter = 1
    while newParent.children[name] do
        name = baseName .. " (" .. counter .. ")" .. ext
        counter = counter + 1
    end
    
    local oldParent = node.parent
    node.parent.children[node.name] = nil
    node.parent = newParent
    node.name = name
    newParent.children[name] = node
    
    -- Update modification times
    filesystem.updateModified(node)
    filesystem.updateModified(oldParent)
    filesystem.updateModified(newParent)
    filesystem.save(filesystem.getFS())
    return true
end

-- Copy a node to a new parent
function filesystem.copy(node, newParent)
    if not newParent.children then return false end
    
    local currentTime = os.time()
    local newNode = {
        name = node.name,
        type = node.type,
        parent = newParent,
        created = currentTime,
        modified = currentTime
    }
    
    if node.type == "directory" then
        newNode.children = {}
        for k, v in pairs(node.children) do
            filesystem.copy(v, newNode)
        end
    else
        newNode.content = node.content
    end
    
    local name = newNode.name
    local baseName = name:match("(.+)%..+") or name
    local ext = name:match("(%..+)$") or ""
    if node.type == "directory" then baseName = name; ext = "" end
    local counter = 1
    while newParent.children[name] do
        name = baseName .. " (" .. counter .. ")" .. ext
        counter = counter + 1
    end
    newNode.name = name
    newParent.children[name] = newNode
    
    filesystem.updateModified(newParent)
    filesystem.save(filesystem.getFS())
    return true
end

function filesystem.updateFileContent(node, newContent)
    if node.type == "file" then
        node.content = newContent
        node.modified = os.time()
        filesystem.save(filesystem.getFS())
    end
end

-- Generate a tree view (array of strings) for a directory.
function filesystem.generateTree(node, prefix)
    prefix = prefix or ""
    local lines = {}
    local keys = {}
    for name, _ in pairs(node.children or {}) do
        table.insert(keys, name)
    end
    table.sort(keys)
    for _, name in ipairs(keys) do
        local child = node.children[name]
        if child.type == "directory" then
            table.insert(lines, prefix .. name .. "/")
            local subLines = filesystem.generateTree(child, prefix .. "  ")
            for _, subline in ipairs(subLines) do
                table.insert(lines, subline)
            end
        else
            table.insert(lines, prefix .. name)
        end
    end
    return lines
end

-- Find a node by its absolute path
function filesystem.getNodeByPath(path)
    if not path or path == "" then return nil end
    if path == "/" then return filesystem.getFS() end
    
    local parts = {}
    for part in path:gmatch("[^/]+") do
        table.insert(parts, part)
    end
    
    local current = filesystem.getFS()
    for _, part in ipairs(parts) do
        if current.children and current.children[part] then
            current = current.children[part]
        else
            return nil
        end
    end
    return current
end

return filesystem