local xml2lua = require("lib/xml2lua")
local handler = require("lib/xmlhandler.dom")

local Websites = {}

function Websites.load(url)
    local filename = url:gsub("http://", ""):gsub("https://", ""):gsub("/", "_")
    if filename == "" then filename = "home" end
    if not filename:match("%.html$") then filename = filename .. ".html" end
    
    local filepath = "websites/" .. filename
    if not love.filesystem.getInfo(filepath) then
        local mapping = {
            ["http://home.com"] = "home.html",
            ["http://example.com"] = "example.com.html",
            ["http://lynux.home"] = "home.html",
            ["http://links.lynux"] = "links.html",
            ["http://about.lynux"] = "about.html",
            ["http://news.net"] = "news.html",
            ["http://crash.com"] = "blue_screen.html",
            ["http://matrix.code"] = "matrix.html",
            ["http://secret.vault"] = "matrix.html", -- For now pointing to same
        }
        if mapping[url] then
            filepath = "websites/" .. mapping[url]
        end
    end

    if love.filesystem.getInfo(filepath) then
        local content = love.filesystem.read(filepath)
        local domHandler = handler:new()
        local parser = xml2lua.parser(domHandler)
        parser:parse(content)
        
        return domHandler.root
    end
    
    return nil
end

function Websites.findFirst(node, name)
    if node._name == name then return node end
    if node._children then
        for _, child in ipairs(node._children) do
            local found = Websites.findFirst(child, name)
            if found then return found end
        end
    end
    return nil
end

return Websites
