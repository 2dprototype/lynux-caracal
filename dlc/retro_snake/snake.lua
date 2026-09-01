-- dlc/retro_snake/snake.lua
-- Retro Arcade Snake Game with AI female snake, mating, and many power-ups

local AudioManager = require("src/core/audio_manager")

local SnakeGame = {}
SnakeGame.__index = SnakeGame

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function randomColor()
    return {math.random(), math.random(), math.random()}
end

local function lerpColor(c1, c2, t)
    return {
        c1[1] + (c2[1] - c1[1]) * t,
        c1[2] + (c2[2] - c1[2]) * t,
        c1[3] + (c2[3] - c1[3]) * t
    }
end

local function distance(p1, p2)
    return math.abs(p1.x - p2.x) + math.abs(p1.y - p2.y)
end

-- Convert HSV to RGB (for rainbow)
local function hsvToRgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    else r, g, b = v, p, q end
    return r, g, b
end

local function findFreeCells(snake, food, powerUp, greenFruit, forbiddenFoods, cols, rows)
    local free = {}
    for r = 1, rows do
        for c = 1, cols do
            local occ = false
            for _, seg in ipairs(snake) do
                if seg.x == c and seg.y == r then occ = true; break end
            end
            if not occ and food and food.x == c and food.y == r then occ = true end
            if not occ and powerUp and powerUp.x == c and powerUp.y == r then occ = true end
            if not occ and greenFruit and greenFruit.x == c and greenFruit.y == r then occ = true end
            if not occ and forbiddenFoods then
                for _, ff in ipairs(forbiddenFoods) do
                    if ff.x == c and ff.y == r then occ = true; break end
                end
            end
            if not occ then table.insert(free, {x = c, y = r}) end
        end
    end
    return free
end

-- ============================================================
-- SNAKE GAME
-- ============================================================
function SnakeGame.new()
    local self = setmetatable({}, SnakeGame)
    self.gridSize = 16
    self.cols = 20
    self.rows = 20
    self.score = 0
    self.highScore = 0
    self.gameOver = false
    self.paused = false
    self.timer = 0
    self.baseSpeed = 0.12
    self.speed = self.baseSpeed
    self.tempSpeedMultiplier = 1.0
    self.tempSpeedTimer = 0
    self.lives = 3
    self.maxLives = 5
    self.width = 420
    self.height = 440
    self.glowTimer = 0
    self.glowActive = false
    self.glowDuration = 5.0

    -- Invincibility after respawn
    self.invincible = false
    self.invincibleTimer = 0
    self.invincibleDuration = 2.0
    self.blinkTimer = 0
    self.blinkVisible = true

    -- Forbidden Realm
    self.inForbiddenRealm = false
    self.forbiddenTimer = 0
    self.forbiddenDuration = 8.0
    self.forbiddenFoods = {}
    self.forbiddenPowerUps = {}
    self.forbiddenCols = 30
    self.forbiddenRows = 30

    -- Color system
    self.snakeColors = {
        head = {0.6, 0.95, 0.3},
        body = {0.35, 0.85, 0.2}
    }
    self.targetHeadColor = {0.6, 0.95, 0.3}
    self.targetBodyColor = {0.35, 0.85, 0.2}
    self.colorChangeTimer = 0

    -- Rainbow mode
    self.rainbowActive = false
    self.rainbowTimer = 0
    self.rainbowDuration = 10.0

    -- Temporal no collision
    self.noCollision = false
    self.noCollisionTimer = 0
    self.noCollisionDuration = 3.0

    -- Lust food effect
    self.lustActive = false
    self.lustTimer = 0
    self.lustDuration = 5.0
    self.lustMultiplier = 3

    -- Whitehole / Blackhole effects
    self.whiteholeActive = false
    self.whiteholeTimer = 0
    self.blackholeActive = false
    self.blackholeTimer = 0
    self.effectDuration = 5.0

    -- Devil's fruit count
    self.devilFruitEaten = 0

    -- AI female snake
    self.femaleSnake = nil
    self.femaleActive = false
    self.femaleTimer = 0
    self.femaleDuration = 300 -- 5 minutes
    self.femaleLives = 3
    self.femaleMaxLives = 5
    self.femaleInvincible = false
    self.femaleInvincibleTimer = 0
    self.femaleNoCollision = false
    self.femaleNoCollisionTimer = 0
    self.femaleLustActive = false
    self.femaleLustTimer = 0
    self.femaleSpeedMultiplier = 1.0
    self.femaleTempSpeedTimer = 0
    self.femaleInForbidden = false
    self.femaleForbiddenTimer = 0
    self.femaleTarget = nil
    self.femaleDirection = {x = 1, y = 0}
    self.femaleNextDir = {x = 1, y = 0}
    self.femaleColor = {1.0, 0.4, 0.7}  -- pink
    self.femaleGlow = false
    self.femaleGlowTimer = 0
    self.femaleMoveTimer = 0
    self.femaleSpawnTimer = 30.0  -- auto spawn after 30s

    -- Mating
    self.matingCooldown = 0
    self.matingCooldownMax = 10.0
    self.mateCount = 0
    self.matingFreeze = false
    self.matingFreezeTimer = 0
    self.shakeAmount = 0

    -- Power-up types (extended)
    self.powerUpTypes = {
        "shorten", "reverse", "speedup", "slowdown", "extralife", "scoreboost",
        "colorchange", "devilfruit", "lustfood", "nocollision", "forbidden",
        "mate", "rainbow", "wormhole", "whitehole", "blackhole"
    }
    self.powerUp = nil
    self.powerUpTimer = 0
    self.powerUpSpawnInterval = 7.0
    self.powerUpSpawnTimer = 0

    -- Rare green fruit (spawns independently)
    self.greenFruit = nil
    self.greenFruitTimer = 0
    self.greenFruitDuration = 5.0
    self.greenFruitSpawnInterval = 8.0
    self.greenFruitSpawnTimer = 0

    -- Debug items (multiple power-ups, foods, etc.)
    self.debugItems = {}

    -- Fonts
    self.font = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 15) or love.graphics.newFont(15)
    self.largeFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 22) or love.graphics.newFont(22)
    self.smallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 12) or love.graphics.newFont(12)

    self:reset()
    return self
end

function SnakeGame:reset()
    self.snake = {
        { x = 10, y = 10 },
        { x = 9, y = 10 },
        { x = 8, y = 10 }
    }
    self.dir = { x = 1, y = 0 }
    self.nextDir = { x = 1, y = 0 }
    self.gameOver = false
    self.score = 0
    self.lives = 3
    self.speed = self.baseSpeed
    self.tempSpeedMultiplier = 1.0
    self.tempSpeedTimer = 0
    self.powerUp = nil
    self.powerUpTimer = 0
    self.powerUpSpawnTimer = 0
    self.invincible = false
    self.invincibleTimer = 0
    self.noCollision = false
    self.noCollisionTimer = 0
    self.lustActive = false
    self.lustTimer = 0
    self.devilFruitEaten = 0
    self.inForbiddenRealm = false
    self.forbiddenTimer = 0
    self.forbiddenFoods = {}
    self.forbiddenPowerUps = {}
    self.glowActive = false
    self.glowTimer = 0
    self.rainbowActive = false
    self.rainbowTimer = 0
    self.whiteholeActive = false
    self.whiteholeTimer = 0
    self.blackholeActive = false
    self.blackholeTimer = 0
    self.debugItems = {}

    -- Reset female
    self.femaleActive = false
    self.femaleSnake = nil
    self.femaleTimer = 0
    self.femaleLives = 3
    self.femaleInvincible = false
    self.femaleNoCollision = false
    self.femaleLustActive = false
    self.femaleSpeedMultiplier = 1.0
    self.femaleInForbidden = false
    self.femaleGlow = false
    self.femaleGlowTimer = 0
    self.matingCooldown = 0
    self.mateCount = 0
    self.femaleMoveTimer = 0
    self.femaleSpawnTimer = 30.0
    self.matingFreeze = false
    self.matingFreezeTimer = 0
    self.shakeAmount = 0

    -- Reset green fruit
    self.greenFruit = nil
    self.greenFruitTimer = 0
    self.greenFruitSpawnTimer = 0

    self.targetHeadColor = {0.6, 0.95, 0.3}
    self.targetBodyColor = {0.35, 0.85, 0.2}
    self.snakeColors.head = {0.6, 0.95, 0.3}
    self.snakeColors.body = {0.35, 0.85, 0.2}
    self:spawnFood()
end

-- ============================================================
-- FOOD & POWER-UP SPAWNING
-- ============================================================
function SnakeGame:spawnFood()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local free = findFreeCells(self.snake, nil, self.powerUp, self.greenFruit, self.forbiddenFoods, cols, rows)
    if #free > 0 then
        self.food = free[math.random(1, #free)]
    else
        self.food = { x = 1, y = 1 }
    end
end

function SnakeGame:spawnPowerUp()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local free = findFreeCells(self.snake, self.food, nil, self.greenFruit, self.forbiddenFoods, cols, rows)
    if #free > 0 then
        local pos = free[math.random(1, #free)]
        local typeIdx = math.random(1, #self.powerUpTypes)
        -- Devil's fruit and mate are rarer
        if self.powerUpTypes[typeIdx] == "devilfruit" and math.random() > 0.25 then
            typeIdx = math.random(1, #self.powerUpTypes - 2)
        end
        if self.powerUpTypes[typeIdx] == "mate" and (self.femaleActive or math.random() > 0.25) then
            typeIdx = math.random(1, #self.powerUpTypes - 2)
        end
        self.powerUp = {
            x = pos.x,
            y = pos.y,
            type = self.powerUpTypes[typeIdx],
            timer = 6.0,
            blink = 0
        }
        self.powerUpTimer = 6.0
    end
end

function SnakeGame:spawnGreenFruit()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local free = findFreeCells(self.snake, self.food, self.powerUp, nil, self.forbiddenFoods, cols, rows)
    if #free > 0 then
        local pos = free[math.random(1, #free)]
        self.greenFruit = {
            x = pos.x,
            y = pos.y,
            timer = self.greenFruitDuration
        }
        self.greenFruitTimer = self.greenFruitDuration
    end
end

-- Spawn a forbidden food (type 1-4)
function SnakeGame:spawnForbiddenFood()
    local cols = self.forbiddenCols
    local rows = self.forbiddenRows
    local free = findFreeCells(self.snake, self.food, self.powerUp, self.greenFruit, self.forbiddenFoods, cols, rows)
    if #free > 0 then
        local pos = free[math.random(1, #free)]
        local type = math.random(1, 4)  -- type 4 adds time
        table.insert(self.forbiddenFoods, {x = pos.x, y = pos.y, type = type})
    end
end

-- ============================================================
-- FEMALE AI SNAKE
-- ============================================================
function SnakeGame:spawnFemale()
    if self.femaleActive then return end
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local free = findFreeCells(self.snake, self.food, self.powerUp, self.greenFruit, self.forbiddenFoods, cols, rows)
    if #free < 5 then return end

    -- Place female snake away from player
    local head = self.snake[1]
    local sorted = {}
    for _, cell in ipairs(free) do
        table.insert(sorted, {cell = cell, dist = distance(cell, head)})
    end
    table.sort(sorted, function(a,b) return a.dist > b.dist end)
    local start = sorted[1].cell

    self.femaleSnake = {
        { x = start.x, y = start.y },
        { x = start.x - 1, y = start.y },
        { x = start.x - 2, y = start.y }
    }
    self.femaleDirection = { x = 1, y = 0 }
    self.femaleNextDir = { x = 1, y = 0 }
    self.femaleActive = true
    self.femaleTimer = self.femaleDuration
    self.femaleLives = 3
    self.femaleInvincible = false
    self.femaleInvincibleTimer = 0
    self.femaleNoCollision = false
    self.femaleNoCollisionTimer = 0
    self.femaleLustActive = false
    self.femaleLustTimer = 0
    self.femaleSpeedMultiplier = 1.0
    self.femaleTempSpeedTimer = 0
    self.femaleInForbidden = false
    self.femaleForbiddenTimer = 0
    self.femaleGlow = false
    self.femaleGlowTimer = 0
    self.femaleTarget = nil
    self.femaleColor = {1.0, 0.4, 0.7}
    self.femaleMoveTimer = 0
    AudioManager.playSFX("levelup", 1.2, 0.5)
    Notifications.add("Snake", "A pink female snake appeared!", nil, 3.0)
end

-- BFS pathfinding for female AI
function SnakeGame:findPath(start, targets, obstacles, cols, rows)
    local queue = {{x = start.x, y = start.y, path = {}}}
    local visited = {}
    visited[start.x .. "," .. start.y] = true

    while #queue > 0 do
        local current = table.remove(queue, 1)
        for _, dir in ipairs({{0, -1}, {0, 1}, {-1, 0}, {1, 0}}) do
            local nx, ny = current.x + dir[1], current.y + dir[2]
            if nx >= 1 and nx <= cols and ny >= 1 and ny <= rows then
                local key = nx .. "," .. ny
                if not visited[key] then
                    local blocked = false
                    for _, obs in ipairs(obstacles) do
                        if obs.x == nx and obs.y == ny then
                            blocked = true
                            break
                        end
                    end
                    if not blocked then
                        local newPath = {unpack(current.path)}
                        table.insert(newPath, {x = nx, y = ny})
                        for _, t in ipairs(targets) do
                            if t.x == nx and t.y == ny then
                                if #newPath > 0 then
                                    return newPath[1]
                                else
                                    return {x = nx, y = ny}
                                end
                            end
                        end
                        visited[key] = true
                        table.insert(queue, {x = nx, y = ny, path = newPath})
                    end
                end
            end
        end
    end
    return nil
end

function SnakeGame:getFemaleDirection()
    local head = self.femaleSnake[1]
    local cols, rows
    local obstacles = {}

    if self.femaleInForbidden then
        cols = self.forbiddenCols
        rows = self.forbiddenRows
        for i = 1, #self.femaleSnake - 1 do
            table.insert(obstacles, self.femaleSnake[i])
        end
    else
        cols = self.cols
        rows = self.rows
        for i = 1, #self.femaleSnake - 1 do
            table.insert(obstacles, self.femaleSnake[i])
        end
        for i = 2, #self.snake do
            table.insert(obstacles, self.snake[i])
        end
    end

    local targets = {}
    if not self.femaleInForbidden then
        if self.food then table.insert(targets, self.food) end
        if self.powerUp then table.insert(targets, self.powerUp) end
        if self.greenFruit then table.insert(targets, 1, self.greenFruit) end
    else
        for _, f in ipairs(self.forbiddenFoods) do
            table.insert(targets, f)
        end
        if self.food then table.insert(targets, self.food) end
        if self.powerUp then table.insert(targets, self.powerUp) end
        if self.greenFruit then table.insert(targets, 1, self.greenFruit) end
    end

    if #targets == 0 then
        return nil
    end

    for _, t in ipairs(targets) do
        local step = self:findPath(head, {t}, obstacles, cols, rows)
        if step then
            return {x = step.x - head.x, y = step.y - head.y}
        end
    end
    return nil
end

function SnakeGame:updateFemaleAI(dt)
    if not self.femaleActive then return end

    self.femaleTimer = self.femaleTimer - dt
    if self.femaleTimer <= 0 then
        self.femaleActive = false
        self.femaleSnake = nil
        return
    end

    if self.femaleInvincible then
        self.femaleInvincibleTimer = self.femaleInvincibleTimer - dt
        if self.femaleInvincibleTimer <= 0 then
            self.femaleInvincible = false
        end
    end
    if self.femaleNoCollision then
        self.femaleNoCollisionTimer = self.femaleNoCollisionTimer - dt
        if self.femaleNoCollisionTimer <= 0 then
            self.femaleNoCollision = false
        end
    end
    if self.femaleLustActive then
        self.femaleLustTimer = self.femaleLustTimer - dt
        if self.femaleLustTimer <= 0 then
            self.femaleLustActive = false
        end
    end
    if self.femaleTempSpeedTimer > 0 then
        self.femaleTempSpeedTimer = self.femaleTempSpeedTimer - dt
        if self.femaleTempSpeedTimer <= 0 then
            self.femaleSpeedMultiplier = 1.0
        end
    end
    if self.femaleGlow then
        self.femaleGlowTimer = self.femaleGlowTimer - dt
        if self.femaleGlowTimer <= 0 then
            self.femaleGlow = false
        end
    end
    if self.femaleInForbidden then
        self.femaleForbiddenTimer = self.femaleForbiddenTimer - dt
        if self.femaleForbiddenTimer <= 0 then
            self.femaleInForbidden = false
            local cols = self.cols
            local rows = self.rows
            local head = self.femaleSnake[1]
            head.x = math.min(head.x, cols)
            head.y = math.min(head.y, rows)
        end
    end

    local currentSpeed = self.baseSpeed * (1 / self.femaleSpeedMultiplier)
    self.femaleMoveTimer = self.femaleMoveTimer + dt
    if self.femaleMoveTimer >= currentSpeed then
        self.femaleMoveTimer = 0

        local cols = self.femaleInForbidden and self.forbiddenCols or self.cols
        local rows = self.femaleInForbidden and self.forbiddenRows or self.rows

        local dir = self:getFemaleDirection()
        if dir then
            self.femaleNextDir = dir
        else
            local possible = {}
            local reverse = {x = -self.femaleDirection.x, y = -self.femaleDirection.y}
            for _, d in ipairs({{0,-1},{0,1},{-1,0},{1,0}}) do
                if not (d[1] == reverse.x and d[2] == reverse.y) then
                    local nx = self.femaleSnake[1].x + d[1]
                    local ny = self.femaleSnake[1].y + d[2]
                    local blocked = false
                    if nx < 1 or nx > cols or ny < 1 or ny > rows then blocked = true end
                    if not blocked then
                        for i = 1, #self.femaleSnake - 1 do
                            if self.femaleSnake[i].x == nx and self.femaleSnake[i].y == ny then
                                blocked = true; break
                            end
                        end
                    end
                    if not blocked then
                        table.insert(possible, {x = d[1], y = d[2]})
                    end
                end
            end
            if #possible > 0 then
                local d = possible[math.random(1, #possible)]
                self.femaleNextDir = d
            else
                self.femaleNextDir = {x = -self.femaleDirection.x, y = -self.femaleDirection.y}
            end
        end

        self.femaleDirection = {x = self.femaleNextDir.x, y = self.femaleNextDir.y}
        local head = self.femaleSnake[1]
        local newHead = {x = head.x + self.femaleDirection.x, y = head.y + self.femaleDirection.y}

        if newHead.x < 1 then newHead.x = cols end
        if newHead.x > cols then newHead.x = 1 end
        if newHead.y < 1 then newHead.y = rows end
        if newHead.y > rows then newHead.y = 1 end

        if not self.femaleNoCollision and not self.femaleInvincible then
            for i = 1, #self.femaleSnake - 1 do
                if self.femaleSnake[i].x == newHead.x and self.femaleSnake[i].y == newHead.y then
                    self.femaleLives = self.femaleLives - 1
                    if self.femaleLives <= 0 then
                        self.femaleActive = false
                        self.femaleSnake = nil
                        Notifications.add("Snake", "Female snake died!", nil, 3.0)
                        return
                    else
                        self.femaleInvincible = true
                        self.femaleInvincibleTimer = 2.0
                        while #self.femaleSnake > 3 do table.remove(self.femaleSnake) end
                        self.femaleDirection = {x = 1, y = 0}
                        self.femaleNextDir = {x = 1, y = 0}
                    end
                    return
                end
            end
        end

        table.insert(self.femaleSnake, 1, newHead)

        -- Eat food (including forbidden realm)
        local ate = false
        if not self.femaleInForbidden then
            if self.food and newHead.x == self.food.x and newHead.y == self.food.y then
                local points = 10
                if self.femaleLustActive then points = points * 3 end
                self.score = self.score + points
                if self.score > self.highScore then self.highScore = self.score end
                self.baseSpeed = math.max(0.06, 0.12 - math.floor(self.score / 50) * 0.01)
                self.speed = self.baseSpeed
                AudioManager.playSFX("tick", 1.5, 0.5)
                self:spawnFood()
                ate = true
            end
            if self.powerUp and newHead.x == self.powerUp.x and newHead.y == self.powerUp.y then
                self:applyPowerUpToFemale(self.powerUp)
                self.powerUp = nil
                ate = true
            end
            if self.greenFruit and newHead.x == self.greenFruit.x and newHead.y == self.greenFruit.y then
                self.score = self.score + 200
                if self.score > self.highScore then self.highScore = self.score end
                -- Female glows pink
                self.femaleGlow = true
                self.femaleGlowTimer = self.glowDuration
                self.greenFruit = nil
                self.greenFruitTimer = 0
                AudioManager.playSFX("levelup", 1.8, 0.8)
                Notifications.add("Snake", "Female ate LIME GREEN FRUIT! +200 and pink glow!", nil, 2.0)
                ate = true
            end
        end

        -- Forbidden foods (including type 4)
        for i = #self.forbiddenFoods, 1, -1 do
            local f = self.forbiddenFoods[i]
            if newHead.x == f.x and newHead.y == f.y then
                if f.type == 4 then
                    -- Extend forbidden timer
                    self.forbiddenTimer = math.min(self.forbiddenTimer + 2.0, 12.0)
                    AudioManager.playSFX("levelup", 1.0, 0.6)
                    Notifications.add("Snake", "+2s in Forbidden Realm!", nil, 1.5)
                else
                    local points = f.type == 1 and 15 or (f.type == 2 and 30 or 50)
                    if self.femaleLustActive then points = points * 3 end
                    self.score = self.score + points
                    if self.score > self.highScore then self.highScore = self.score end
                    AudioManager.playSFX("tick", 1.5 + f.type * 0.2, 0.5)
                end
                table.remove(self.forbiddenFoods, i)
                ate = true
                break
            end
        end

        if not ate then
            table.remove(self.femaleSnake)
        end

        -- Mating
        if self.femaleActive and not self.gameOver then
            local playerHead = self.snake[1]
            local femaleHead = self.femaleSnake[1]
            if playerHead.x == femaleHead.x and playerHead.y == femaleHead.y then
                if self.matingCooldown <= 0 then
                    self:mate()
                end
            end
        end
    end
end

function SnakeGame:applyPowerUpToFemale(powerUp)
    local type = powerUp.type
    if type == "shorten" then
        for i = 1, 3 do if #self.femaleSnake > 3 then table.remove(self.femaleSnake) end end
    elseif type == "reverse" then
        local newDir = {x = -self.femaleDirection.x, y = -self.femaleDirection.y}
        local head = self.femaleSnake[1]
        local newHead = {x = head.x + newDir.x, y = head.y + newDir.y}
        local collides = false
        for i = 1, #self.femaleSnake - 1 do
            if self.femaleSnake[i].x == newHead.x and self.femaleSnake[i].y == newHead.y then
                collides = true; break
            end
        end
        if not collides then
            self.femaleDirection = newDir
            self.femaleNextDir = newDir
        end
    elseif type == "speedup" then
        self.femaleSpeedMultiplier = 1.8
        self.femaleTempSpeedTimer = 4.0
    elseif type == "slowdown" then
        self.femaleSpeedMultiplier = 0.5
        self.femaleTempSpeedTimer = 4.0
    elseif type == "extralife" then
        if self.femaleLives < self.femaleMaxLives then
            self.femaleLives = self.femaleLives + 1
        end
    elseif type == "scoreboost" then
        self.score = self.score + 50
        if self.score > self.highScore then self.highScore = self.score end
    elseif type == "colorchange" then
        self.femaleColor = randomColor()
    elseif type == "devilfruit" then
        self.score = self.score + 100
        self.devilFruitEaten = self.devilFruitEaten + 1
        self.femaleSpeedMultiplier = 1.5
        self.femaleTempSpeedTimer = 3.0
    elseif type == "lustfood" then
        self.femaleLustActive = true
        self.femaleLustTimer = 5.0
    elseif type == "nocollision" then
        self.femaleNoCollision = true
        self.femaleNoCollisionTimer = 3.0
    elseif type == "forbidden" then
        if not self.femaleInForbidden then
            self.femaleInForbidden = true
            self.femaleForbiddenTimer = 8.0
            local cols = self.forbiddenCols
            local rows = self.forbiddenRows
            self.femaleSnake = {
                {x = math.floor(cols/2), y = math.floor(rows/2)},
                {x = math.floor(cols/2)-1, y = math.floor(rows/2)},
                {x = math.floor(cols/2)-2, y = math.floor(rows/2)}
            }
            self.femaleDirection = {x = 1, y = 0}
            self.femaleNextDir = {x = 1, y = 0}
        end
    elseif type == "mate" then
        if not self.femaleActive then
            self:spawnFemale()
        end
    elseif type == "rainbow" then
        self.femaleColor = randomColor() -- just for fun
    end
    AudioManager.playSFX("tick", 1.0, 0.3)
end

function SnakeGame:mate()
    self.mateCount = self.mateCount + 1
    local bonus = 100 + self.mateCount * 50
    self.score = self.score + bonus
    if self.score > self.highScore then self.highScore = self.score end
    self.matingCooldown = self.matingCooldownMax
    AudioManager.playSFX("levelup", 1.5, 0.8)
    Notifications.add("Snake", "Mating success! +" .. bonus .. " points!", nil, 2.0)

    -- Freeze both snakes for a moment (jerk animation)
    self.matingFreeze = true
    self.matingFreezeTimer = 0.5  -- half second freeze
    self.shakeAmount = 4  -- shake intensity

    -- Boost after freeze (applied later)
    self.tempSpeedMultiplier = 0.7
    self.tempSpeedTimer = 3.0
    self.femaleSpeedMultiplier = 0.7
    self.femaleTempSpeedTimer = 3.0
end

-- ============================================================
-- PLAYER METHODS
-- ============================================================
function SnakeGame:applyPowerUp(powerUp)
    local type = powerUp.type
    if type == "shorten" then
        for i = 1, 3 do if #self.snake > 3 then table.remove(self.snake) end end
        AudioManager.playSFX("tick", 1.2, 0.3)
    elseif type == "reverse" then
        -- No safety check; just reverse
        self.dir = { x = -self.dir.x, y = -self.dir.y }
        self.nextDir = { x = self.dir.x, y = self.dir.y }
        AudioManager.playSFX("tick", 0.8, 0.3)
    elseif type == "speedup" then
        self.tempSpeedMultiplier = 1.8
        self.tempSpeedTimer = 4.0
        AudioManager.playSFX("tick", 1.8, 0.3)
    elseif type == "slowdown" then
        self.tempSpeedMultiplier = 0.5
        self.tempSpeedTimer = 4.0
        AudioManager.playSFX("tick", 0.6, 0.3)
    elseif type == "extralife" then
        if self.lives < self.maxLives then self.lives = self.lives + 1 end
        AudioManager.playSFX("levelup", 1.2, 0.5)
    elseif type == "scoreboost" then
        self.score = self.score + 50
        if self.score > self.highScore then self.highScore = self.score end
        AudioManager.playSFX("task_complete", 1.0, 0.5)
    elseif type == "colorchange" then
        self.targetHeadColor = randomColor()
        self.targetBodyColor = randomColor()
        self.colorChangeTimer = 1.0
        AudioManager.playSFX("tick", 1.5, 0.3)
    elseif type == "devilfruit" then
        self.score = self.score + 100
        self.devilFruitEaten = self.devilFruitEaten + 1
        self.tempSpeedMultiplier = 1.5
        self.tempSpeedTimer = 3.0
        AudioManager.playSFX("levelup", 1.5, 0.8)
    elseif type == "lustfood" then
        self.lustActive = true
        self.lustTimer = self.lustDuration
        AudioManager.playSFX("task_complete", 1.2, 0.5)
    elseif type == "nocollision" then
        self.noCollision = true
        self.noCollisionTimer = self.noCollisionDuration
        AudioManager.playSFX("tick", 1.8, 0.3)
    elseif type == "forbidden" then
        self:enterForbiddenRealm()
        AudioManager.playSFX("levelup", 1.0, 0.8)
    elseif type == "mate" then
        if not self.femaleActive then
            self:spawnFemale()
        else
            self.score = self.score + 50
            if self.score > self.highScore then self.highScore = self.score end
        end
        AudioManager.playSFX("levelup", 1.2, 0.5)
    elseif type == "rainbow" then
        self.rainbowActive = true
        self.rainbowTimer = self.rainbowDuration
        AudioManager.playSFX("levelup", 1.3, 0.6)
    elseif type == "wormhole" then
        self:teleportSnake()
        AudioManager.playSFX("levelup", 1.0, 0.7)
    elseif type == "whitehole" then
        self.whiteholeActive = true
        self.whiteholeTimer = self.effectDuration
        AudioManager.playSFX("levelup", 1.0, 0.5)
    elseif type == "blackhole" then
        self.blackholeActive = true
        self.blackholeTimer = self.effectDuration
        AudioManager.playSFX("levelup", 1.0, 0.5)
    end
end

function SnakeGame:teleportSnake()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local free = findFreeCells(self.snake, self.food, self.powerUp, self.greenFruit, self.forbiddenFoods, cols, rows)
    if #free < #self.snake then return end
    local idx = math.random(1, #free)
    local newHead = free[idx]
    local dir = self.dir
    local newSnake = {}
    for i = 1, #self.snake do
        local seg = {
            x = newHead.x - (i-1) * dir.x,
            y = newHead.y - (i-1) * dir.y
        }
        if seg.x < 1 then seg.x = cols + seg.x end
        if seg.x > cols then seg.x = seg.x - cols end
        if seg.y < 1 then seg.y = rows + seg.y end
        if seg.y > rows then seg.y = seg.y - rows end
        table.insert(newSnake, seg)
    end
    local ok = true
    for i = 1, #newSnake do
        for j = i+1, #newSnake do
            if newSnake[i].x == newSnake[j].x and newSnake[i].y == newSnake[j].y then
                ok = false; break
            end
        end
        if not ok then break end
    end
    if not ok then
        newSnake = {
            {x = newHead.x, y = newHead.y},
            {x = newHead.x - dir.x, y = newHead.y - dir.y},
            {x = newHead.x - 2*dir.x, y = newHead.y - 2*dir.y}
        }
        for i, seg in ipairs(newSnake) do
            if seg.x < 1 then seg.x = cols + seg.x end
            if seg.x > cols then seg.x = seg.x - cols end
            if seg.y < 1 then seg.y = rows + seg.y end
            if seg.y > rows then seg.y = seg.y - rows end
        end
    end
    self.snake = newSnake
end

function SnakeGame:enterForbiddenRealm()
    self.inForbiddenRealm = true
    self.forbiddenTimer = self.forbiddenDuration
    self.forbiddenFoods = {}
    local cols = self.forbiddenCols
    local rows = self.forbiddenRows
    for i = 1, 15 do
        self:spawnForbiddenFood()
    end
    self.snake = {
        { x = math.floor(cols/2), y = math.floor(rows/2) },
        { x = math.floor(cols/2) - 1, y = math.floor(rows/2) },
        { x = math.floor(cols/2) - 2, y = math.floor(rows/2) }
    }
    self.dir = { x = 1, y = 0 }
    self.nextDir = { x = 1, y = 0 }
    self:spawnFood()
    self:spawnPowerUp()
    self:spawnGreenFruit()
end

function SnakeGame:exitForbiddenRealm()
    self.inForbiddenRealm = false
    self.forbiddenTimer = 0
    self.forbiddenFoods = {}
    self.snake = {
        { x = 10, y = 10 },
        { x = 9, y = 10 },
        { x = 8, y = 10 }
    }
    self.dir = { x = 1, y = 0 }
    self.nextDir = { x = 1, y = 0 }
    self:spawnFood()
end

function SnakeGame:revive()
    self.lives = self.lives - 1
    if self.lives <= 0 then
        self.gameOver = true
        AudioManager.playSFX("glitch", 1.2, 0.4)
        return false
    end
    self.invincible = true
    self.invincibleTimer = self.invincibleDuration
    self.blinkTimer = 0
    self.blinkVisible = true
    while #self.snake > 3 do table.remove(self.snake) end
    if #self.snake > 1 then
        local head = self.snake[1]
        local next = self.snake[2]
        self.dir = { x = head.x - next.x, y = head.y - next.y }
        self.nextDir = { x = self.dir.x, y = self.dir.y }
    else
        self.dir = { x = 1, y = 0 }
        self.nextDir = { x = 1, y = 0 }
    end
    self:spawnFood()
    self.powerUp = nil
    AudioManager.playSFX("levelup", 0.8, 0.5)
    return true
end

-- ============================================================
-- UPDATE
-- ============================================================
function SnakeGame:update(dt)
    if self.gameOver or self.paused then return end

    -- Mating freeze update
    if self.matingFreeze then
        self.matingFreezeTimer = self.matingFreezeTimer - dt
        if self.matingFreezeTimer <= 0 then
            self.matingFreeze = false
            self.shakeAmount = 0
        else
            -- During freeze, still update timers but skip movement
            -- Also shake effect decays
            self.shakeAmount = self.shakeAmount * 0.95
            return  -- skip all other updates during freeze
        end
    end

    -- Auto spawn female after 30s
    if not self.femaleActive then
        self.femaleSpawnTimer = self.femaleSpawnTimer - dt
        if self.femaleSpawnTimer <= 0 then
            self:spawnFemale()
            self.femaleSpawnTimer = 9999
        end
    end

    -- Update mating cooldown
    if self.matingCooldown > 0 then
        self.matingCooldown = self.matingCooldown - dt
    end

    -- Update glow
    if self.glowActive then
        self.glowTimer = self.glowTimer - dt
        if self.glowTimer <= 0 then
            self.glowActive = false
        end
    end

    -- Update rainbow
    if self.rainbowActive then
        self.rainbowTimer = self.rainbowTimer - dt
        if self.rainbowTimer <= 0 then
            self.rainbowActive = false
        end
    end

    -- Update whitehole / blackhole
    if self.whiteholeActive then
        self.whiteholeTimer = self.whiteholeTimer - dt
        if self.whiteholeTimer <= 0 then
            self.whiteholeActive = false
        end
        if self.food and not self.inForbiddenRealm then
            local head = self.snake[1]
            local dx = self.food.x - head.x
            local dy = self.food.y - head.y
            if math.abs(dx) >= math.abs(dy) then
                self.food.x = self.food.x + (dx > 0 and 1 or -1)
            else
                self.food.y = self.food.y + (dy > 0 and 1 or -1)
            end
            local cols = self.cols
            local rows = self.rows
            self.food.x = math.max(1, math.min(cols, self.food.x))
            self.food.y = math.max(1, math.min(rows, self.food.y))
        end
        if self.inForbiddenRealm then
            local head = self.snake[1]
            for _, f in ipairs(self.forbiddenFoods) do
                local dx = f.x - head.x
                local dy = f.y - head.y
                if math.abs(dx) >= math.abs(dy) then
                    f.x = f.x + (dx > 0 and 1 or -1)
                else
                    f.y = f.y + (dy > 0 and 1 or -1)
                end
                f.x = math.max(1, math.min(self.forbiddenCols, f.x))
                f.y = math.max(1, math.min(self.forbiddenRows, f.y))
            end
        end
    end

    if self.blackholeActive then
        self.blackholeTimer = self.blackholeTimer - dt
        if self.blackholeTimer <= 0 then
            self.blackholeActive = false
        end
        if self.food and not self.inForbiddenRealm then
            local head = self.snake[1]
            local dx = head.x - self.food.x
            local dy = head.y - self.food.y
            if math.abs(dx) >= math.abs(dy) then
                self.food.x = self.food.x + (dx > 0 and 1 or -1)
            else
                self.food.y = self.food.y + (dy > 0 and 1 or -1)
            end
            self.food.x = math.max(1, math.min(self.cols, self.food.x))
            self.food.y = math.max(1, math.min(self.rows, self.food.y))
        end
        if self.inForbiddenRealm then
            local head = self.snake[1]
            for _, f in ipairs(self.forbiddenFoods) do
                local dx = head.x - f.x
                local dy = head.y - f.y
                if math.abs(dx) >= math.abs(dy) then
                    f.x = f.x + (dx > 0 and 1 or -1)
                else
                    f.y = f.y + (dy > 0 and 1 or -1)
                end
                f.x = math.max(1, math.min(self.forbiddenCols, f.x))
                f.y = math.max(1, math.min(self.forbiddenRows, f.y))
            end
        end
    end

    -- Update invincibility
    if self.invincible then
        self.invincibleTimer = self.invincibleTimer - dt
        self.blinkTimer = self.blinkTimer + dt
        if self.blinkTimer > 0.1 then
            self.blinkTimer = 0
            self.blinkVisible = not self.blinkVisible
        end
        if self.invincibleTimer <= 0 then
            self.invincible = false
            self.blinkVisible = true
        end
    end

    -- Update no collision
    if self.noCollision then
        self.noCollisionTimer = self.noCollisionTimer - dt
        if self.noCollisionTimer <= 0 then
            self.noCollision = false
        end
    end

    -- Update lust
    if self.lustActive then
        self.lustTimer = self.lustTimer - dt
        if self.lustTimer <= 0 then
            self.lustActive = false
        end
    end

    -- Update color change
    if self.colorChangeTimer > 0 then
        self.colorChangeTimer = self.colorChangeTimer - dt
        local t = 1 - self.colorChangeTimer
        self.snakeColors.head = lerpColor(self.snakeColors.head, self.targetHeadColor, t * 0.05)
        self.snakeColors.body = lerpColor(self.snakeColors.body, self.targetBodyColor, t * 0.05)
    end

    -- Update temp speed
    if self.tempSpeedTimer > 0 then
        self.tempSpeedTimer = self.tempSpeedTimer - dt
        if self.tempSpeedTimer <= 0 then
            self.tempSpeedMultiplier = 1.0
        end
    end

    -- Forbidden realm timer
    if self.inForbiddenRealm then
        self.forbiddenTimer = self.forbiddenTimer - dt
        if self.forbiddenTimer <= 0 then
            self:exitForbiddenRealm()
            if self.femaleActive and self.femaleInForbidden then
                self.femaleInForbidden = false
                self.femaleForbiddenTimer = 0
            end
        end
        while #self.forbiddenFoods < 15 do
            self:spawnForbiddenFood()
        end
        if not self.food then self:spawnFood() end
        if not self.powerUp and math.random() < 0.02 then self:spawnPowerUp() end
        if not self.greenFruit and math.random() < 0.01 then self:spawnGreenFruit() end
    end

    -- Power-up spawn (in both realms)
    if not self.powerUp then
        self.powerUpSpawnTimer = self.powerUpSpawnTimer + dt
        if self.powerUpSpawnTimer >= self.powerUpSpawnInterval then
            self.powerUpSpawnTimer = 0
            self:spawnPowerUp()
        end
    else
        self.powerUpTimer = self.powerUpTimer - dt
        self.powerUp.blink = (self.powerUp.blink or 0) + dt
        if self.powerUpTimer <= 0 then
            self.powerUp = nil
        end
    end

    -- Green fruit spawn (in both realms)
    if not self.greenFruit then
        self.greenFruitSpawnTimer = self.greenFruitSpawnTimer + dt
        if self.greenFruitSpawnTimer >= self.greenFruitSpawnInterval then
            self.greenFruitSpawnTimer = 0
            self:spawnGreenFruit()
        end
    else
        self.greenFruitTimer = self.greenFruitTimer - dt
        if self.greenFruitTimer <= 0 then
            self.greenFruit = nil
        end
    end

    -- Update female AI
    self:updateFemaleAI(dt)

    -- Player movement
    self.timer = self.timer + dt
    local currentSpeed = self.speed * (1 / self.tempSpeedMultiplier)
    if self.timer >= currentSpeed then
        self.timer = 0
        self.dir = { x = self.nextDir.x, y = self.nextDir.y }

        local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
        local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows

        local head = self.snake[1]
        local newHead = { x = head.x + self.dir.x, y = head.y + self.dir.y }

        if newHead.x < 1 then newHead.x = cols end
        if newHead.x > cols then newHead.x = 1 end
        if newHead.y < 1 then newHead.y = rows end
        if newHead.y > rows then newHead.y = 1 end

        -- Collision with self
        if not self.noCollision and not self.invincible then
            for i = 1, #self.snake - 1 do
                if self.snake[i].x == newHead.x and self.snake[i].y == newHead.y then
                    if not self:revive() then return end
                    return
                end
            end
        end

        table.insert(self.snake, 1, newHead)

        -- Eat food (normal realm)
        local ate = false
        if not self.inForbiddenRealm then
            if newHead.x == self.food.x and newHead.y == self.food.y then
                local points = 10
                if self.lustActive then points = points * self.lustMultiplier end
                self.score = self.score + points
                if self.score > self.highScore then self.highScore = self.score end
                self.baseSpeed = math.max(0.06, 0.12 - math.floor(self.score / 50) * 0.01)
                self.speed = self.baseSpeed
                AudioManager.playSFX("tick", 1.5, 0.5)
                self:spawnFood()
                ate = true
            end
            if self.powerUp and newHead.x == self.powerUp.x and newHead.y == self.powerUp.y then
                self:applyPowerUp(self.powerUp)
                self.powerUp = nil
                ate = true
            end
            if self.greenFruit and newHead.x == self.greenFruit.x and newHead.y == self.greenFruit.y then
                self.score = self.score + 200
                if self.score > self.highScore then self.highScore = self.score end
                self.glowActive = true
                self.glowTimer = self.glowDuration
                self.greenFruit = nil
                self.greenFruitTimer = 0
                AudioManager.playSFX("levelup", 1.8, 0.8)
                Notifications.add("Snake", "LIME GREEN FRUIT! +200 points and glow!", nil, 2.0)
                ate = true
            end
            -- Debug items collision
            for i = #self.debugItems, 1, -1 do
                local item = self.debugItems[i]
                if newHead.x == item.x and newHead.y == item.y then
                    if item.type == "food" then
                        self.score = self.score + 10
                        AudioManager.playSFX("tick", 1.5, 0.5)
                    elseif item.type == "greenfruit" then
                        self.score = self.score + 200
                        self.glowActive = true
                        self.glowTimer = self.glowDuration
                        AudioManager.playSFX("levelup", 1.8, 0.8)
                    else
                        -- power-up
                        self:applyPowerUp(item)
                    end
                    table.remove(self.debugItems, i)
                    ate = true
                end
            end
        else
            -- Forbidden realm: regular food, power-up, green fruit, and forbidden foods
            if newHead.x == self.food.x and newHead.y == self.food.y then
                local points = 10
                if self.lustActive then points = points * self.lustMultiplier end
                self.score = self.score + points
                if self.score > self.highScore then self.highScore = self.score end
                self.baseSpeed = math.max(0.06, 0.12 - math.floor(self.score / 50) * 0.01)
                self.speed = self.baseSpeed
                AudioManager.playSFX("tick", 1.5, 0.5)
                self:spawnFood()
                ate = true
            end
            if self.powerUp and newHead.x == self.powerUp.x and newHead.y == self.powerUp.y then
                self:applyPowerUp(self.powerUp)
                self.powerUp = nil
                ate = true
            end
            if self.greenFruit and newHead.x == self.greenFruit.x and newHead.y == self.greenFruit.y then
                self.score = self.score + 200
                if self.score > self.highScore then self.highScore = self.score end
                self.glowActive = true
                self.glowTimer = self.glowDuration
                self.greenFruit = nil
                self.greenFruitTimer = 0
                AudioManager.playSFX("levelup", 1.8, 0.8)
                Notifications.add("Snake", "LIME GREEN FRUIT! +200 points and glow!", nil, 2.0)
                ate = true
            end
            -- Forbidden foods
            for i = #self.forbiddenFoods, 1, -1 do
                local f = self.forbiddenFoods[i]
                if newHead.x == f.x and newHead.y == f.y then
                    if f.type == 4 then
                        self.forbiddenTimer = math.min(self.forbiddenTimer + 2.0, 12.0)
                        AudioManager.playSFX("levelup", 1.0, 0.6)
                        Notifications.add("Snake", "+2s in Forbidden Realm!", nil, 1.5)
                    else
                        local points = f.type == 1 and 15 or (f.type == 2 and 30 or 50)
                        if self.lustActive then points = points * self.lustMultiplier end
                        self.score = self.score + points
                        if self.score > self.highScore then self.highScore = self.score end
                        AudioManager.playSFX("tick", 1.5 + f.type * 0.2, 0.5)
                    end
                    table.remove(self.forbiddenFoods, i)
                    ate = true
                    break
                end
            end
        end

        if not ate then
            table.remove(self.snake)
        end

        -- Mating check
        if self.femaleActive then
            local fHead = self.femaleSnake[1]
            if newHead.x == fHead.x and newHead.y == fHead.y then
                if self.matingCooldown <= 0 then
                    self:mate()
                end
            end
        end
    end
end

-- ============================================================
-- DRAW
-- ============================================================
function SnakeGame:draw(x, y, width, height)
    self.width = width
    self.height = height

    love.graphics.push()
    love.graphics.translate(x, y)

    -- Shake effect during mating freeze
    if self.shakeAmount > 0 then
        local ox = math.random(-self.shakeAmount, self.shakeAmount)
        local oy = math.random(-self.shakeAmount, self.shakeAmount)
        love.graphics.translate(ox, oy)
    end

    -- Background
    if self.inForbiddenRealm then
        love.graphics.setColor(0.08, 0.02, 0.08)
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setColor(0.15, 0.02, 0.15, 0.3)
        for i = 1, 5 do
            local rx = math.random(0, width)
            local ry = math.random(0, height)
            love.graphics.rectangle("fill", rx, ry, math.random(10, 40), math.random(2, 6))
        end
    else
        love.graphics.setColor(0.06, 0.08, 0.12)
        love.graphics.rectangle("fill", 0, 0, width, height)
    end

    -- Header
    local barH = 34
    love.graphics.setColor(0.10, 0.14, 0.22)
    love.graphics.rectangle("fill", 0, 0, width, barH)

    love.graphics.setFont(self.font)
    love.graphics.setColor(0.35, 0.75, 1.0)
    love.graphics.print("SCORE: " .. tostring(self.score), 16, 8)

    love.graphics.setColor(0.85, 0.75, 0.3)
    love.graphics.printf("HIGH: " .. tostring(self.highScore), 0, 8, width - 16, "right")

    -- Lives (player)
    local livesX = 10
    love.graphics.setColor(0.9, 0.3, 0.3)
    for i = 1, self.lives do
        love.graphics.circle("fill", livesX + (i-1) * 14, 17, 5)
    end

    -- Female lives (if active)
    if self.femaleActive then
        local fx = livesX + self.lives * 14 + 10
        love.graphics.setColor(1.0, 0.4, 0.7)
        for i = 1, self.femaleLives do
            love.graphics.circle("fill", fx + (i-1) * 14, 17, 5)
        end
        love.graphics.setColor(1.0, 0.4, 0.7)
        love.graphics.print("F", fx - 14, 6)
    end

    -- Status indicators
    local statusY = 1
    local statuses = {}
    if self.noCollision then table.insert(statuses, "NO COLLISION") end
    if self.lustActive then table.insert(statuses, "LUST ACTIVE") end
    if self.invincible then table.insert(statuses, "INVINCIBLE") end
    if self.inForbiddenRealm then table.insert(statuses, "FORBIDDEN REALM") end
    if self.femaleActive then table.insert(statuses, "FEMALE PRESENT") end
    if self.glowActive then table.insert(statuses, "GLOWING") end
    if self.rainbowActive then table.insert(statuses, "RAINBOW") end
    if self.whiteholeActive then table.insert(statuses, "WHITEHOLE") end
    if self.blackholeActive then table.insert(statuses, "BLACKHOLE") end
    for _, s in ipairs(statuses) do
        love.graphics.setColor(0.9, 0.9, 0.2, 0.6)
        love.graphics.printf(s, width / 2 - 60, statusY, 120, "center")
        statusY = statusY + 14
    end

    -- Playing Grid Area
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local boardW = cols * self.gridSize
    local boardH = rows * self.gridSize

    local scale = 1
    if boardW > width - 20 or boardH > height - barH - 20 then
        scale = math.min((width - 20) / boardW, (height - barH - 20) / boardH)
        boardW = boardW * scale
        boardH = boardH * scale
    end

    local boardX = math.floor((width - boardW) / 2)
    local boardY = barH + math.floor((height - barH - boardH) / 2)

    love.graphics.setColor(self.inForbiddenRealm and {0.12, 0.02, 0.12} or {0.03, 0.05, 0.08})
    love.graphics.rectangle("fill", boardX, boardY, boardW, boardH)
    love.graphics.setColor(self.inForbiddenRealm and {0.4, 0.1, 0.1} or {0.18, 0.24, 0.35})
    love.graphics.rectangle("line", boardX, boardY, boardW, boardH)

    -- Grid
    love.graphics.setColor(self.inForbiddenRealm and {0.2, 0.05, 0.2} or {0.08, 0.12, 0.18})
    for r = 1, rows-1 do
        love.graphics.line(boardX, boardY + r * self.gridSize * scale, boardX + boardW, boardY + r * self.gridSize * scale)
    end
    for c = 1, cols-1 do
        love.graphics.line(boardX + c * self.gridSize * scale, boardY, boardX + c * self.gridSize * scale, boardY + boardH)
    end

    -- Food (regular)
    if self.food then
        local fx = boardX + (self.food.x - 1) * self.gridSize * scale
        local fy = boardY + (self.food.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        love.graphics.setColor(0.95, 0.2, 0.2)
        love.graphics.rectangle("fill", fx + 2, fy + 2, size - 4, size - 4, 3, 3)
        love.graphics.setColor(0.8, 0.1, 0.1)
        love.graphics.rectangle("fill", fx + 4, fy + 4, size - 8, size - 8, 2, 2)
    end

    -- Forbidden foods (including type 4)
    for _, f in ipairs(self.forbiddenFoods) do
        local fx = boardX + (f.x - 1) * self.gridSize * scale
        local fy = boardY + (f.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        if f.type == 1 then
            love.graphics.setColor(0.95, 0.2, 0.2)
        elseif f.type == 2 then
            love.graphics.setColor(0.95, 0.85, 0.1)
        elseif f.type == 3 then
            love.graphics.setColor(0.8, 0.2, 0.9)
        else -- type 4
            love.graphics.setColor(0.2, 0.9, 0.9)
        end
        love.graphics.rectangle("fill", fx + 1, fy + 1, size - 2, size - 2, 4, 4)
        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.rectangle("fill", fx - 2, fy - 2, size + 4, size + 4, 6, 6)
    end

    -- Power-up (standard)
    if self.powerUp then
        local px = boardX + (self.powerUp.x - 1) * self.gridSize * scale
        local py = boardY + (self.powerUp.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        local type = self.powerUp.type
        local color
        if type == "shorten" then color = {0.8, 0.4, 0.9}
        elseif type == "reverse" then color = {0.2, 0.9, 0.9}
        elseif type == "speedup" then color = {0.9, 0.9, 0.2}
        elseif type == "slowdown" then color = {0.2, 0.4, 0.9}
        elseif type == "extralife" then color = {0.9, 0.2, 0.6}
        elseif type == "scoreboost" then color = {0.9, 0.6, 0.2}
        elseif type == "colorchange" then color = {0.2, 0.9, 0.6}
        elseif type == "devilfruit" then color = {0.9, 0.1, 0.1}
        elseif type == "lustfood" then color = {0.9, 0.2, 0.5}
        elseif type == "nocollision" then color = {0.2, 0.8, 0.9}
        elseif type == "forbidden" then color = {0.5, 0.1, 0.5}
        elseif type == "mate" then color = {1.0, 0.4, 0.7}
        elseif type == "rainbow" then color = {0.9, 0.1, 0.8}
        elseif type == "wormhole" then color = {0.1, 0.3, 0.9}
        elseif type == "whitehole" then color = {1.0, 1.0, 1.0}
        elseif type == "blackhole" then color = {0.0, 0.0, 0.0}
        end
        local alpha = 1
        if self.powerUpTimer < 2 and math.floor(self.powerUp.blink * 4) % 2 == 0 then
            alpha = 0.4
        end
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.rectangle("fill", px + 1, py + 1, size - 2, size - 2, 4, 4)
        love.graphics.setColor(color[1], color[2], color[3], 0.3 * alpha)
        love.graphics.rectangle("fill", px - 2, py - 2, size + 4, size + 4, 6, 6)
    end

    -- Debug items (power-ups and foods)
    for _, item in ipairs(self.debugItems) do
        local ix = boardX + (item.x - 1) * self.gridSize * scale
        local iy = boardY + (item.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        if item.type == "food" then
            love.graphics.setColor(0.95, 0.2, 0.2)
            love.graphics.rectangle("fill", ix + 2, iy + 2, size - 4, size - 4, 3, 3)
        elseif item.type == "greenfruit" then
            love.graphics.setColor(0.5, 1.0, 0.3, 0.25)
            love.graphics.rectangle("fill", ix - 4, iy - 4, size + 8, size + 8, 6, 6)
            love.graphics.setColor(0.5, 1.0, 0.3)
            love.graphics.rectangle("fill", ix + 1, iy + 1, size - 2, size - 2, 4, 4)
            love.graphics.setColor(0.3, 0.8, 0.2)
            love.graphics.rectangle("fill", ix + 3, iy + 3, size - 8, size - 8, 2, 2)
        else
            -- power-up type
            local color
            if item.type == "shorten" then color = {0.8, 0.4, 0.9}
            elseif item.type == "reverse" then color = {0.2, 0.9, 0.9}
            elseif item.type == "speedup" then color = {0.9, 0.9, 0.2}
            elseif item.type == "slowdown" then color = {0.2, 0.4, 0.9}
            elseif item.type == "extralife" then color = {0.9, 0.2, 0.6}
            elseif item.type == "scoreboost" then color = {0.9, 0.6, 0.2}
            elseif item.type == "colorchange" then color = {0.2, 0.9, 0.6}
            elseif item.type == "devilfruit" then color = {0.9, 0.1, 0.1}
            elseif item.type == "lustfood" then color = {0.9, 0.2, 0.5}
            elseif item.type == "nocollision" then color = {0.2, 0.8, 0.9}
            elseif item.type == "forbidden" then color = {0.5, 0.1, 0.5}
            elseif item.type == "mate" then color = {1.0, 0.4, 0.7}
            elseif item.type == "rainbow" then color = {0.9, 0.1, 0.8}
            elseif item.type == "wormhole" then color = {0.1, 0.3, 0.9}
            elseif item.type == "whitehole" then color = {1.0, 1.0, 1.0}
            elseif item.type == "blackhole" then color = {0.0, 0.0, 0.0}
            end
            love.graphics.setColor(color[1], color[2], color[3], 1)
            love.graphics.rectangle("fill", ix + 1, iy + 1, size - 2, size - 2, 4, 4)
            love.graphics.setColor(color[1], color[2], color[3], 0.3)
            love.graphics.rectangle("fill", ix - 2, iy - 2, size + 4, size + 4, 6, 6)
        end
    end

    -- Green fruit (standard)
    if self.greenFruit then
        local gx = boardX + (self.greenFruit.x - 1) * self.gridSize * scale
        local gy = boardY + (self.greenFruit.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        love.graphics.setColor(0.5, 1.0, 0.3, 0.25)
        love.graphics.rectangle("fill", gx - 4, gy - 4, size + 8, size + 8, 6, 6)
        love.graphics.setColor(0.5, 1.0, 0.3)
        love.graphics.rectangle("fill", gx + 1, gy + 1, size - 2, size - 2, 4, 4)
        love.graphics.setColor(0.3, 0.8, 0.2)
        love.graphics.rectangle("fill", gx + 3, gy + 3, size - 8, size - 8, 2, 2)
    end

    -- Draw player snake
    for i, seg in ipairs(self.snake) do
        local sx = boardX + (seg.x - 1) * self.gridSize * scale
        local sy = boardY + (seg.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale

        if not (self.invincible and not self.blinkVisible) then
            if self.glowActive then
                love.graphics.setColor(0.5, 1.0, 0.3, 0.4)
                love.graphics.rectangle("fill", sx - 2, sy - 2, size + 4, size + 4, 6, 6)
            end
            if self.rainbowActive then
                local hue = (i - 1) / #self.snake
                local r, g, b = hsvToRgb(hue, 1.0, 1.0)
                love.graphics.setColor(r, g, b)
            else
                if i == 1 then
                    love.graphics.setColor(self.snakeColors.head)
                else
                    love.graphics.setColor(self.snakeColors.body)
                end
            end
            love.graphics.rectangle("fill", sx + 1, sy + 1, size - 2, size - 2, 3, 3)
            love.graphics.setColor(0.8, 1.0, 0.5, 0.2)
            love.graphics.rectangle("fill", sx + 3, sy + 3, size - 8, size - 8, 2, 2)
        end
    end

    -- Draw female snake
    if self.femaleActive and self.femaleSnake then
        for i, seg in ipairs(self.femaleSnake) do
            local sx = boardX + (seg.x - 1) * self.gridSize * scale
            local sy = boardY + (seg.y - 1) * self.gridSize * scale
            local size = self.gridSize * scale

            if not (self.femaleInvincible and not self.blinkVisible) then
                if self.femaleGlow then
                    love.graphics.setColor(1.0, 0.4, 0.7, 0.4)
                    love.graphics.rectangle("fill", sx - 2, sy - 2, size + 4, size + 4, 6, 6)
                end
                if i == 1 then
                    love.graphics.setColor(self.femaleColor)
                else
                    love.graphics.setColor(self.femaleColor[1] * 0.7, self.femaleColor[2] * 0.7, self.femaleColor[3] * 0.7)
                end
                love.graphics.rectangle("fill", sx + 1, sy + 1, size - 2, size - 2, 3, 3)
                love.graphics.setColor(1.0, 0.7, 0.9, 0.2)
                love.graphics.rectangle("fill", sx + 3, sy + 3, size - 8, size - 8, 2, 2)
            end
        end
    end

    -- Game Over
    if self.gameOver then
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", boardX, boardY, boardW, boardH)

        love.graphics.setFont(self.largeFont)
        love.graphics.setColor(0.95, 0.35, 0.35)
        love.graphics.printf("GAME OVER", boardX, boardY + boardH / 2 - 40, boardW, "center")

        love.graphics.setFont(self.font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press [SPACE] or [R] to Restart", boardX, boardY + boardH / 2 + 6, boardW, "center")
        love.graphics.printf("Final Score: " .. self.score, boardX, boardY + boardH / 2 + 30, boardW, "center")
        love.graphics.printf("Devil's Fruits: " .. self.devilFruitEaten, boardX, boardY + boardH / 2 + 54, boardW, "center")
        if self.femaleActive then
            love.graphics.printf("Mate Count: " .. self.mateCount, boardX, boardY + boardH / 2 + 78, boardW, "center")
        end
    end

    love.graphics.pop()
end

-- ============================================================
-- INPUT
-- ============================================================
function SnakeGame:keypressed(key)
    if self.gameOver then
        if key == "space" or key == "r" or key == "return" then
            self:reset()
            return true
        end
    end

    -- Debug: press 't' to spawn all types in top row (permanently)
    if key == "t" then
        self:spawnDebugItems()
        return true
    end

    if key == "up" or key == "w" then
        if self.dir.y == 0 then
            self.nextDir = { x = 0, y = -1 }
            return true
        end
    elseif key == "down" or key == "s" then
        if self.dir.y == 0 then
            self.nextDir = { x = 0, y = 1 }
            return true
        end
    elseif key == "left" or key == "a" then
        if self.dir.x == 0 then
            self.nextDir = { x = -1, y = 0 }
            return true
        end
    elseif key == "right" or key == "d" then
        if self.dir.x == 0 then
            self.nextDir = { x = 1, y = 0 }
            return true
        end
    elseif key == "p" then
        self.paused = not self.paused
        return true
    elseif key == "r" then
        self:reset()
        return true
    end
    return false
end

function SnakeGame:mousepressed(mx, my, button)
    if self.gameOver and button == 1 then
        self:reset()
        return true
    end
    return false
end

-- Debug: spawn one of each power-up type + green fruit + food + forbidden food in top row
function SnakeGame:spawnDebugItems()
    self.debugItems = {}  -- clear previous
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local y = 1  -- top row
    local x = 1
    -- Place regular food
    table.insert(self.debugItems, {x = x, y = y, type = "food"})
    x = x + 1
    -- Green fruit
    table.insert(self.debugItems, {x = x, y = y, type = "greenfruit"})
    x = x + 1
    -- One of each power-up type
    for _, ptype in ipairs(self.powerUpTypes) do
        if x <= cols then
            table.insert(self.debugItems, {x = x, y = y, type = ptype})
            x = x + 1
        end
    end
    -- Also place a forbidden food (type 4) if in normal realm
    if not self.inForbiddenRealm and x <= cols then
        table.insert(self.debugItems, {x = x, y = y, type = "forbidden"})  -- treat as power-up
        x = x + 1
    end
end

return SnakeGame