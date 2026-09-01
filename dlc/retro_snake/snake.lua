-- dlc/retro_snake/snake.lua
-- Retro Arcade Snake Game playable inside an OS window

local AudioManager = require("src.core.audio_manager")

local SnakeGame = {}
SnakeGame.__index = SnakeGame

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
    self.speed = 0.12
    self.width = 420
    self.height = 440

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
    self.speed = 0.12
    self:spawnFood()
end

function SnakeGame:spawnFood()
    local freeCells = {}
    for r = 1, self.rows do
        for c = 1, self.cols do
            local isOccupied = false
            for _, seg in ipairs(self.snake) do
                if seg.x == c and seg.y == r then
                    isOccupied = true
                    break
                end
            end
            if not isOccupied then
                table.insert(freeCells, { x = c, y = r })
            end
        end
    end

    if #freeCells > 0 then
        self.food = freeCells[math.random(1, #freeCells)]
    else
        self.food = { x = 1, y = 1 }
    end
end

function SnakeGame:update(dt)
    if self.gameOver or self.paused then return end

    self.timer = self.timer + dt
    if self.timer >= self.speed then
        self.timer = 0
        self.dir = { x = self.nextDir.x, y = self.nextDir.y }

        local head = self.snake[1]
        local newHead = { x = head.x + self.dir.x, y = head.y + self.dir.y }

        if newHead.x < 1 or newHead.x > self.cols or newHead.y < 1 or newHead.y > self.rows then
            self.gameOver = true
            AudioManager.playSFX("glitch", 1.2, 0.4)
            return
        end

        for i = 1, #self.snake - 1 do
            if self.snake[i].x == newHead.x and self.snake[i].y == newHead.y then
                self.gameOver = true
                AudioManager.playSFX("glitch", 1.2, 0.4)
                return
            end
        end

        table.insert(self.snake, 1, newHead)

        if newHead.x == self.food.x and newHead.y == self.food.y then
            self.score = self.score + 10
            if self.score > self.highScore then
                self.highScore = self.score
            end
            self.speed = math.max(0.06, 0.12 - math.floor(self.score / 50) * 0.01)
            AudioManager.playSFX("tick", 1.5, 0.5)
            self:spawnFood()
        else
            table.remove(self.snake)
        end
    end
end

function SnakeGame:draw(x, y, width, height)
    self.width = width
    self.height = height

    love.graphics.push()
    love.graphics.translate(x, y)

    -- Background
    love.graphics.setColor(0.06, 0.08, 0.12)
    love.graphics.rectangle("fill", 0, 0, width, height)

    -- Header stats bar
    local barH = 34
    love.graphics.setColor(0.10, 0.14, 0.22)
    love.graphics.rectangle("fill", 0, 0, width, barH)

    love.graphics.setFont(self.font)
    love.graphics.setColor(0.35, 0.75, 1.0)
    love.graphics.print("SCORE: " .. tostring(self.score), 16, 8)

    love.graphics.setColor(0.85, 0.75, 0.3)
    love.graphics.printf("HIGH: " .. tostring(self.highScore), 0, 8, width - 16, "right")

    -- Playing Grid Area
    local boardW = self.cols * self.gridSize
    local boardH = self.rows * self.gridSize
    local boardX = math.floor((width - boardW) / 2)
    local boardY = barH + math.floor((height - barH - boardH) / 2)

    love.graphics.setColor(0.03, 0.05, 0.08)
    love.graphics.rectangle("fill", boardX, boardY, boardW, boardH)
    love.graphics.setColor(0.18, 0.24, 0.35)
    love.graphics.rectangle("line", boardX, boardY, boardW, boardH)

    -- Food
    if self.food then
        local fx = boardX + (self.food.x - 1) * self.gridSize
        local fy = boardY + (self.food.y - 1) * self.gridSize
        love.graphics.setColor(0.95, 0.3, 0.3)
        love.graphics.rectangle("fill", fx + 2, fy + 2, self.gridSize - 4, self.gridSize - 4, 3, 3)
    end

    -- Snake Body
    for i, seg in ipairs(self.snake) do
        local sx = boardX + (seg.x - 1) * self.gridSize
        local sy = boardY + (seg.y - 1) * self.gridSize
        if i == 1 then
            love.graphics.setColor(0.25, 0.85, 0.45)
        else
            love.graphics.setColor(0.15, 0.65, 0.35)
        end
        love.graphics.rectangle("fill", sx + 1, sy + 1, self.gridSize - 2, self.gridSize - 2, 2, 2)
    end

    -- Game Over Overlay
    if self.gameOver then
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", boardX, boardY, boardW, boardH)

        love.graphics.setFont(self.largeFont)
        love.graphics.setColor(0.95, 0.35, 0.35)
        love.graphics.printf("GAME OVER", boardX, boardY + boardH / 2 - 30, boardW, "center")

        love.graphics.setFont(self.font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press [SPACE] or [R] to Restart", boardX, boardY + boardH / 2 + 6, boardW, "center")
    end

    love.graphics.pop()
end

function SnakeGame:keypressed(key)
    if self.gameOver then
        if key == "space" or key == "r" or key == "return" then
            self:reset()
            return true
        end
    end

    if (key == "up" or key == "w") and self.dir.y == 0 then
        self.nextDir = { x = 0, y = -1 }
        return true
    elseif (key == "down" or key == "s") and self.dir.y == 0 then
        self.nextDir = { x = 0, y = 1 }
        return true
    elseif (key == "left" or key == "a") and self.dir.x == 0 then
        self.nextDir = { x = -1, y = 0 }
        return true
    elseif (key == "right" or key == "d") and self.dir.x == 0 then
        self.nextDir = { x = 1, y = 0 }
        return true
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

return SnakeGame
