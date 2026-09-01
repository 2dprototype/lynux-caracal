-- dlc/minesweeper/minesweeper.lua
-- Classic Windows 95/10 Style Minesweeper Game

local AudioManager = require("src.core.audio_manager")

local Minesweeper = {}
Minesweeper.__index = Minesweeper

function Minesweeper.new()
    local self = setmetatable({}, Minesweeper)
    self.width = 380
    self.height = 440
    self.cols = 9
    self.rows = 9
    self.totalMines = 10
    self.cellSize = 32
    self.grid = {}
    self.gameOver = false
    self.gameWon = false
    self.firstClick = true
    self.timer = 0
    self.flagsPlaced = 0

    self.font = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 15) or love.graphics.newFont(15)
    self.titleFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 18) or love.graphics.newFont(18)
    self.smallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 12) or love.graphics.newFont(12)

    self:reset()
    return self
end

function Minesweeper:reset()
    self.grid = {}
    for r = 1, self.rows do
        self.grid[r] = {}
        for c = 1, self.cols do
            self.grid[r][c] = {
                isMine = false,
                isRevealed = false,
                isFlagged = false,
                neighborMines = 0
            }
        end
    end
    self.gameOver = false
    self.gameWon = false
    self.firstClick = true
    self.timer = 0
    self.flagsPlaced = 0
end

function Minesweeper:placeMines(safeR, safeC)
    local placed = 0
    while placed < self.totalMines do
        local r = math.random(1, self.rows)
        local c = math.random(1, self.cols)
        if not (r == safeR and c == safeC) and not self.grid[r][c].isMine then
            self.grid[r][c].isMine = true
            placed = placed + 1
        end
    end

    for r = 1, self.rows do
        for c = 1, self.cols do
            if not self.grid[r][c].isMine then
                local count = 0
                for dr = -1, 1 do
                    for dc = -1, 1 do
                        local nr = r + dr
                        local nc = c + dc
                        if nr >= 1 and nr <= self.rows and nc >= 1 and nc <= self.cols then
                            if self.grid[nr][nc].isMine then count = count + 1 end
                        end
                    end
                end
                self.grid[r][c].neighborMines = count
            end
        end
    end
end

function Minesweeper:reveal(r, c)
    if r < 1 or r > self.rows or c < 1 or c > self.cols then return end
    local cell = self.grid[r][c]
    if cell.isRevealed or cell.isFlagged then return end

    cell.isRevealed = true

    if cell.isMine then
        self.gameOver = true
        AudioManager.playSFX("glitch", 1.2, 0.4)
        for row = 1, self.rows do
            for col = 1, self.cols do
                if self.grid[row][col].isMine then
                    self.grid[row][col].isRevealed = true
                end
            end
        end
        return
    end

    AudioManager.playSFX("tick", 1.4, 0.3)

    if cell.neighborMines == 0 then
        for dr = -1, 1 do
            for dc = -1, 1 do
                if not (dr == 0 and dc == 0) then
                    self:reveal(r + dr, c + dc)
                end
            end
        end
    end

    self:checkWin()
end

function Minesweeper:toggleFlag(r, c)
    if r < 1 or r > self.rows or c < 1 or c > self.cols then return end
    local cell = self.grid[r][c]
    if cell.isRevealed then return end

    cell.isFlagged = not cell.isFlagged
    self.flagsPlaced = self.flagsPlaced + (cell.isFlagged and 1 or -1)
    AudioManager.playSFX("click")
    self:checkWin()
end

function Minesweeper:checkWin()
    if self.gameOver then return end
    local unrevealedCount = 0
    for r = 1, self.rows do
        for c = 1, self.cols do
            if not self.grid[r][c].isRevealed then
                unrevealedCount = unrevealedCount + 1
            end
        end
    end
    if unrevealedCount == self.totalMines then
        self.gameWon = true
        AudioManager.playSFX("task_complete", 1.0, 0.6)
    end
end

function Minesweeper:update(dt)
    if not self.firstClick and not self.gameOver and not self.gameWon then
        self.timer = self.timer + dt
    end
end

function Minesweeper:draw(x, y, width, height)
    self.width = width
    self.height = height

    love.graphics.push()
    love.graphics.translate(x, y)

    -- Background
    love.graphics.setColor(0.92, 0.93, 0.95)
    love.graphics.rectangle("fill", 0, 0, width, height)

    -- Header Status Bar
    local headerH = 50
    love.graphics.setColor(0.98, 0.98, 0.99)
    love.graphics.rectangle("fill", 10, 10, width - 20, headerH, 4, 4)
    love.graphics.setColor(0.82, 0.85, 0.90)
    love.graphics.rectangle("line", 10, 10, width - 20, headerH, 4, 4)

    -- Remaining Mines Counter
    love.graphics.setFont(self.font)
    love.graphics.setColor(0.85, 0.25, 0.25)
    love.graphics.print("MINES: " .. string.format("%02d", math.max(0, self.totalMines - self.flagsPlaced)), 24, 25)

    -- Center Smiley Face Button
    local faceX = math.floor((width - 36) / 2)
    local faceY = 17
    love.graphics.setColor(0.90, 0.92, 0.95)
    love.graphics.rectangle("fill", faceX, faceY, 36, 36, 4, 4)
    love.graphics.setColor(0.7, 0.75, 0.82)
    love.graphics.rectangle("line", faceX, faceY, 36, 36, 4, 4)

    love.graphics.setFont(self.titleFont)
    if self.gameWon then
        love.graphics.setColor(0.15, 0.65, 0.35)
        love.graphics.printf("B)", faceX, faceY + 6, 36, "center")
    elseif self.gameOver then
        love.graphics.setColor(0.85, 0.2, 0.2)
        love.graphics.printf("X(", faceX, faceY + 6, 36, "center")
    else
        love.graphics.setColor(0.15, 0.45, 0.85)
        love.graphics.printf(":)", faceX, faceY + 6, 36, "center")
    end

    -- Timer
    love.graphics.setFont(self.font)
    love.graphics.setColor(0.2, 0.25, 0.35)
    love.graphics.printf("TIME: " .. string.format("%03d", math.floor(self.timer)), 0, 25, width - 24, "right")

    -- Grid Area
    local gridPixelW = self.cols * self.cellSize
    local gridPixelH = self.rows * self.cellSize
    local gridX = math.floor((width - gridPixelW) / 2)
    local gridY = 70 + math.floor((height - 70 - gridPixelH) / 2)

    love.graphics.setColor(0.75, 0.78, 0.84)
    love.graphics.rectangle("line", gridX - 2, gridY - 2, gridPixelW + 4, gridPixelH + 4)

    for r = 1, self.rows do
        for c = 1, self.cols do
            local cell = self.grid[r][c]
            local cx = gridX + (c - 1) * self.cellSize
            local cy = gridY + (r - 1) * self.cellSize

            if cell.isRevealed then
                love.graphics.setColor(0.96, 0.97, 0.98)
                love.graphics.rectangle("fill", cx, cy, self.cellSize, self.cellSize)
                love.graphics.setColor(0.84, 0.87, 0.90)
                love.graphics.rectangle("line", cx, cy, self.cellSize, self.cellSize)

                if cell.isMine then
                    love.graphics.setColor(0.85, 0.25, 0.25)
                    love.graphics.circle("fill", cx + self.cellSize / 2, cy + self.cellSize / 2, self.cellSize * 0.3)
                elseif cell.neighborMines > 0 then
                    local numColors = {
                        {0.15, 0.45, 0.85}, -- 1 Blue
                        {0.20, 0.65, 0.30}, -- 2 Green
                        {0.85, 0.25, 0.25}, -- 3 Red
                        {0.10, 0.20, 0.60}, -- 4 Navy
                        {0.60, 0.15, 0.15}, -- 5 Maroon
                        {0.15, 0.60, 0.60}  -- 6 Teal
                    }
                    local col = numColors[cell.neighborMines] or {0.1, 0.1, 0.1}
                    love.graphics.setFont(self.font)
                    love.graphics.setColor(col[1], col[2], col[3])
                    love.graphics.printf(tostring(cell.neighborMines), cx, cy + 6, self.cellSize, "center")
                end
            else
                love.graphics.setColor(0.84, 0.87, 0.92)
                love.graphics.rectangle("fill", cx + 1, cy + 1, self.cellSize - 2, self.cellSize - 2, 2, 2)
                love.graphics.setColor(0.70, 0.74, 0.80)
                love.graphics.rectangle("line", cx + 1, cy + 1, self.cellSize - 2, self.cellSize - 2, 2, 2)

                if cell.isFlagged then
                    love.graphics.setFont(self.font)
                    love.graphics.setColor(0.90, 0.25, 0.25)
                    love.graphics.printf("[F]", cx, cy + 6, self.cellSize, "center")
                end
            end
        end
    end

    love.graphics.pop()
end

function Minesweeper:mousepressed(mx, my, button)
    -- Check smiley reset button
    local faceX = math.floor((self.width - 36) / 2)
    if mx >= faceX and mx <= faceX + 36 and my >= 17 and my <= 53 then
        self:reset()
        AudioManager.playSFX("click")
        return true
    end

    if self.gameOver or self.gameWon then return false end

    local gridPixelW = self.cols * self.cellSize
    local gridPixelH = self.rows * self.cellSize
    local gridX = math.floor((self.width - gridPixelW) / 2)
    local gridY = 70 + math.floor((self.height - 70 - gridPixelH) / 2)

    if mx >= gridX and mx <= gridX + gridPixelW and my >= gridY and my <= gridY + gridPixelH then
        local c = math.floor((mx - gridX) / self.cellSize) + 1
        local r = math.floor((my - gridY) / self.cellSize) + 1

        if r >= 1 and r <= self.rows and c >= 1 and c <= self.cols then
            if button == 1 then
                if self.firstClick then
                    self:placeMines(r, c)
                    self.firstClick = false
                end
                self:reveal(r, c)
                return true
            elseif button == 2 then
                self:toggleFlag(r, c)
                return true
            end
        end
    end
    return false
end

return Minesweeper
