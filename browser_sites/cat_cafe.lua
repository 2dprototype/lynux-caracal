-- browser_sites/cat_cafe.lua
-- The Cute "Meow Latte" Cat Cafe Website

local CatCafe = {}
CatCafe.__index = CatCafe

function CatCafe.new(browser)
    local self = setmetatable({}, CatCafe)
    self.browser = browser
    self.font = love.graphics.newFont("font/Nunito-Regular.ttf", 13) or love.graphics.newFont(13)
    self.smallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 11) or love.graphics.newFont(11)
    self.titleFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 16) or love.graphics.newFont(16)
    self.headerFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 24) or love.graphics.newFont(24)
    
    self.scroll = 0
    self.maxScroll = 0
    self.title = "Meow Latte (ニャン・ラテ) - Cat Cafe"
    
    self.cats = {
        {
            name = "Mochi",
            breed = "Scottish Fold (White)",
            age = "2 Years",
            trait = "Loves curling up on guest notebooks & gentle chin scratches.",
            color = {0.95, 0.95, 0.98},
            tagColor = {0.92, 0.45, 0.55}
        },
        {
            name = "Chobi",
            breed = "Calico Shorthair",
            age = "1 Year",
            trait = "Super energetic! Chases newspaper camera straps & pens.",
            color = {0.98, 0.88, 0.78},
            tagColor = {0.95, 0.65, 0.22}
        },
        {
            name = "Luna",
            breed = "Bombay Black Cat",
            age = "3 Years",
            trait = "Quiet, dignified guardian. Sits peacefully next to quiet study tables.",
            color = {0.25, 0.25, 0.3},
            tagColor = {0.55, 0.4, 0.85}
        },
        {
            name = "Matcha",
            breed = "Classic Brown Tabby",
            age = "4 Years",
            trait = "The cafe boss. Naps exclusively in warm sunlight near the window.",
            color = {0.85, 0.8, 0.72},
            tagColor = {0.35, 0.75, 0.45}
        }
    }
    
    self.menu = {
        { name = "Strawberry Cat-Paw Parfait", price = "¥680", desc = "Handmade strawberry mousse topped with cat-paw marshmallows." },
        { name = "Meow Foam Caramel Latte", price = "¥520", desc = "Artisan espresso with 3D cat latte art foam and sweet caramel." },
        { name = "Fluffy Souffle Honey Pancake", price = "¥750", desc = "Triple-stacked Japanese souffle pancakes with organic clover honey." }
    }
    
    pcall(function()
        local PlayerStats = require("src.core.player_stats")
        PlayerStats.setFlag("browsed_cat_cafe", true)
    end)
    
    return self
end

function CatCafe:draw(x, y, w, h)
    self.x, self.y, self.w, self.h = x, y, w, h
    
    -- Warm pastel cream background
    love.graphics.setColor(0.99, 0.97, 0.95)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- Top Banner
    love.graphics.setColor(0.95, 0.55, 0.62)
    love.graphics.rectangle("fill", x, y, w, 70)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.headerFont)
    love.graphics.printf("Meow Latte (ニャン・ラテ)", x, y + 10, w, "center")
    
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("Fresh Artisan Coffee & 8 Adorable Rescue Cats • 3 min from Kamiyama Station", x, y + 44, w, "center")
    
    -- Content scrolling
    love.graphics.setScissor(x, y + 71, w, h - 71)
    local cy = y + 85 - self.scroll
    local totalH = 85
    
    local colW = math.min(720, w - 40)
    local cx = x + (w - colW) / 2
    
    -- 1. Intro Card
    local introH = 95
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", cx, cy, colW, introH, 8)
    love.graphics.setColor(0.9, 0.85, 0.82)
    love.graphics.rectangle("line", cx, cy, colW, introH, 8)
    
    love.graphics.setColor(0.85, 0.35, 0.45)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("Welcome to Our Relaxing Cat Oasis!", cx + 16, cy + 12)
    
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.setFont(self.font)
    love.graphics.printf(
        "Take a peaceful study break after classes. Enjoy our signature hand-drip coffees, freshly baked dessert treats, and cuddle with our friendly rescue cats in a bright, sunlit salon.",
        cx + 16, cy + 38, colW - 32, "left"
    )
    
    cy = cy + introH + 16
    totalH = totalH + introH + 16
    
    -- 2. Student Council & Newspaper Club Special Notice
    local noticeH = 46
    love.graphics.setColor(1.0, 0.94, 0.9)
    love.graphics.rectangle("fill", cx, cy, colW, noticeH, 6)
    love.graphics.setColor(0.95, 0.65, 0.25)
    love.graphics.rectangle("line", cx, cy, colW, noticeH, 6)
    
    love.graphics.setColor(0.85, 0.45, 0.1)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("Kamiyama High School Special: 10% OFF with Student ID!", cx + 14, cy + 12)
    
    cy = cy + noticeH + 20
    totalH = totalH + noticeH + 20
    
    -- 3. Resident Cats Header
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("Our Resident Cat Stars (キャスト紹介)", cx, cy)
    cy = cy + 28
    totalH = totalH + 28
    
    -- Cat Cards Grid (2 columns if wide, 1 if narrow)
    local cardW = (colW - 16) / 2
    local cardH = 110
    
    for i, cat in ipairs(self.cats) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local cardX = cx + col * (cardW + 16)
        local cardY = cy + row * (cardH + 14)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 8)
        love.graphics.setColor(0.9, 0.88, 0.86)
        love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 8)
        
        -- Cat Avatar Circle
        love.graphics.setColor(cat.color)
        love.graphics.circle("fill", cardX + 36, cardY + 38, 24)
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.circle("line", cardX + 36, cardY + 38, 24)
        
        -- Cat Ears Icon
        love.graphics.setColor(cat.tagColor)
        love.graphics.polygon("fill", cardX + 22, cardY + 22, cardX + 28, cardY + 12, cardX + 34, cardY + 22)
        love.graphics.polygon("fill", cardX + 38, cardY + 22, cardX + 44, cardY + 12, cardX + 50, cardY + 22)
        
        -- Cat Info
        love.graphics.setColor(0.15, 0.15, 0.15)
        love.graphics.setFont(self.titleFont)
        love.graphics.print(cat.name, cardX + 70, cardY + 12)
        
        love.graphics.setColor(cat.tagColor)
        love.graphics.setFont(self.smallFont)
        love.graphics.print(cat.breed .. " • " .. cat.age, cardX + 70, cardY + 34)
        
        love.graphics.setColor(0.35, 0.35, 0.35)
        love.graphics.setFont(self.font)
        love.graphics.printf(cat.trait, cardX + 14, cardY + 68, cardW - 28, "left")
    end
    
    local catRows = math.ceil(#self.cats / 2)
    local catsBlockH = catRows * (cardH + 14)
    cy = cy + catsBlockH + 10
    totalH = totalH + catsBlockH + 10
    
    -- 4. Cafe Menu Header
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("Featured Cafe Menu & Desserts (おすすめメニュー)", cx, cy)
    cy = cy + 28
    totalH = totalH + 28
    
    for _, item in ipairs(self.menu) do
        local mH = 68
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", cx, cy, colW, mH, 6)
        love.graphics.setColor(0.9, 0.88, 0.86)
        love.graphics.rectangle("line", cx, cy, colW, mH, 6)
        
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.setFont(self.titleFont)
        love.graphics.print(item.name, cx + 16, cy + 10)
        
        love.graphics.setColor(0.85, 0.35, 0.45)
        love.graphics.printf(item.price, cx + colW - 100, cy + 10, 84, "right")
        
        love.graphics.setColor(0.45, 0.45, 0.45)
        love.graphics.setFont(self.font)
        love.graphics.print(item.desc, cx + 16, cy + 36)
        
        cy = cy + mH + 10
        totalH = totalH + mH + 10
    end
    
    self.maxScroll = math.max(0, totalH - (h - 71))
    love.graphics.setScissor()
end

function CatCafe:mousepressed(mx, my, button, relX, relY)
    if button ~= 1 and button ~= "l" then return end
    pcall(function()
        local AudioManager = require("src.core.audio_manager")
        AudioManager.playSFX("click")
    end)
end

function CatCafe:wheelmoved(wx, wy)
    if self.maxScroll > 0 then
        self.scroll = math.max(0, math.min(self.maxScroll, self.scroll - wy * 35))
    end
end

return CatCafe
