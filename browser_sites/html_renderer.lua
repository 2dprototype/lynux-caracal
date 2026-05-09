local HTMLRenderer = {}
HTMLRenderer.__index = HTMLRenderer

function HTMLRenderer.new(browser, dom)
    local self = setmetatable({}, HTMLRenderer)
    self.browser = browser
    self.dom = dom
    self.scroll = 0
    self.maxScroll = 0
    self.title = "HTML Page"
    self.links = {}
    
    -- Fonts
    self.fonts = {
        h1 = love.graphics.newFont(32),
        h2 = love.graphics.newFont(28),
        h3 = love.graphics.newFont(24),
        h4 = love.graphics.newFont(20),
        h5 = love.graphics.newFont(18),
        h6 = love.graphics.newFont(16),
        p = love.graphics.newFont(14),
        a = love.graphics.newFont(14),
        button = love.graphics.newFont(14),
        default = love.graphics.newFont(14)
    }
    
    -- Find title
    local Websites = require("websites")
    local titleNode = Websites.findFirst(dom, "title")
    if titleNode and titleNode._children and titleNode._children[1] then
        self.title = titleNode._children[1]._text or "HTML Page"
    end
    
    return self
end

function HTMLRenderer:draw(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    
    love.graphics.push()
    love.graphics.setScissor(x, y, w, h)
    
    self.links = {}
    local cy = y + 20 - self.scroll
    
    local function renderNode(node, nx, ny, nw)
        if node._type == "TEXT" then
            local text = node._text:gsub("[\n\r]", " "):gsub("%s+", " ")
            if text == "" or text == " " then return ny end
            
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.setFont(self.fonts.default)
            local _, lines = self.fonts.default:getWrap(text, nw)
            love.graphics.printf(text, nx, ny, nw)
            return ny + #lines * self.fonts.default:getHeight() + 5
        elseif node._type == "ELEMENT" then
            local tag = node._name:lower()
            local attr = node._attr or {}
            
            if tag == "head" or tag == "title" or tag == "style" or tag == "script" then
                return ny
            end

            local font = self.fonts[tag] or self.fonts.default
            love.graphics.setFont(font)
            
            local color = {0.2, 0.2, 0.2}
            if attr.color then
                local hex = attr.color:gsub("#", "")
                if #hex == 6 then
                    local r = tonumber(hex:sub(1,2), 16) / 255
                    local g = tonumber(hex:sub(3,4), 16) / 255
                    local b = tonumber(hex:sub(5,6), 16) / 255
                    color = {r, g, b}
                end
            end
            
            local align = attr.align or "left"
            
            if tag == "br" then
                return ny + font:getHeight()
            elseif tag == "hr" then
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.line(nx, ny + 10, nx + nw, ny + 10)
                return ny + 20
            elseif tag == "a" or tag == "button" then
                color = tag == "a" and {0.1, 0.4, 0.9} or {0.2, 0.2, 0.2}
            end
            
            love.graphics.setColor(color)
            
            local startY = ny
            if node._children then
                for _, child in ipairs(node._children) do
                    if child._type == "TEXT" then
                        local text = child._text:gsub("[\n\r]", " "):gsub("%s+", " ")
                        if text ~= "" and text ~= " " then
                            local _, lines = font:getWrap(text, nw)
                            local textW = font:getWidth(text)
                            local textH = #lines * font:getHeight()
                            
                            if tag == "button" then
                                -- Draw button background
                                love.graphics.setColor(0.9, 0.9, 0.9)
                                love.graphics.rectangle("fill", nx, ny, textW + 20, textH + 10, 4)
                                love.graphics.setColor(0.7, 0.7, 0.7)
                                love.graphics.rectangle("line", nx, ny, textW + 20, textH + 10, 4)
                                love.graphics.setColor(color)
                                love.graphics.printf(text, nx + 10, ny + 5, nw, align)
                                
                                table.insert(self.links, {
                                    x = nx, y = ny, w = textW + 20, h = textH + 10,
                                    url = attr.href
                                })
                                ny = ny + textH + 20
                            else
                                if tag == "a" then
                                    table.insert(self.links, {
                                        x = nx, y = ny, w = textW, h = textH,
                                        url = attr.href
                                    })
                                    love.graphics.line(nx, ny + textH - 2, nx + textW, ny + textH - 2)
                                end
                                love.graphics.printf(text, nx, ny, nw, align)
                                ny = ny + textH
                            end
                        end
                    else
                        ny = renderNode(child, nx, ny, nw)
                    end
                end
            end
            
            if tag:match("^h[1-6]$") or tag == "p" or tag == "div" then
                ny = ny + 10
            end
            
            return ny
        end
        return ny
    end

    local Websites = require("websites")
    local body = Websites.findFirst(self.dom, "body") or self.dom
    local totalHeight = renderNode(body, x + 20, cy, w - 40)
    
    self.maxScroll = math.max(0, (totalHeight - cy) - h + 40)
    
    love.graphics.setScissor()
    love.graphics.pop()
end

function HTMLRenderer:mousepressed(mx, my, button)
    if button == 1 or button == "l" then
        for _, link in ipairs(self.links) do
            if mx >= link.x and mx <= link.x + link.w and my >= link.y and my <= link.y + link.h then
                if link.url then
                    self.browser:loadURL(link.url)
                end
                return
            end
        end
    end
end

function HTMLRenderer:update(dt)
end

return HTMLRenderer
