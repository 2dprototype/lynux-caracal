-- main.lua
pcall(function() io.stdout:setvbuf("no") end)

local GameManager = require("src.core.game_manager")
local Viewport = require("src.core.viewport")

function love.load(arg)
    -- Test runner mode
    for _, a in ipairs(arg or {}) do
        if a == "--test" then
            local testRunner = require("src.test_verify")
            testRunner()
            love.event.quit(0)
            return
        end
    end

    love.graphics.setDefaultFilter("nearest", "nearest")
    love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)
    
    GameManager.init()
end

function love.update(dt)
    GameManager.update(dt)
end

function love.draw()
    Viewport.push()
    GameManager.draw()
    Viewport.pop()
end

function love.mousepressed(x, y, button)
    local vx, vy = Viewport.toVirtual(x, y)
    if vx >= 0 and vx <= Viewport.baseW and vy >= 0 and vy <= Viewport.baseH then
        GameManager.mousepressed(vx, vy, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    local vx, vy = Viewport.toVirtual(x, y)
    GameManager.mousemoved(vx, vy, (dx or 0) / Viewport.scale, (dy or 0) / Viewport.scale)
end

function love.mousereleased(x, y, button)
    local vx, vy = Viewport.toVirtual(x, y)
    GameManager.mousereleased(vx, vy, button)
end

function love.wheelmoved(x, y)
    GameManager.wheelmoved(x, y)
end

function love.textinput(text)
    GameManager.textinput(text)
end

function love.keypressed(key)
    GameManager.keypressed(key)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local vx, vy = Viewport.toVirtual(x * screenW, y * screenH)
    if vx >= 0 and vx <= Viewport.baseW and vy >= 0 and vy <= Viewport.baseH then
        GameManager.mousepressed(vx, vy, 1)
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local vx, vy = Viewport.toVirtual(x * screenW, y * screenH)
    GameManager.mousemoved(vx, vy, (dx or 0) * screenW / Viewport.scale, (dy or 0) * screenH / Viewport.scale)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local vx, vy = Viewport.toVirtual(x * screenW, y * screenH)
    GameManager.mousereleased(vx, vy, 1)
end

function love.resize(w, h)
    Viewport.update()
    GameManager.resize(Viewport.baseW, Viewport.baseH)
end