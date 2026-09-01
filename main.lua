-- main.lua
pcall(function() io.stdout:setvbuf("no") end)

local GameManager = require("src.core.game_manager")

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
    GameManager.draw()
end

function love.mousepressed(x, y, button)
    GameManager.mousepressed(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    GameManager.mousemoved(x, y, dx, dy)
end

function love.mousereleased(x, y, button)
    GameManager.mousereleased(x, y, button)
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
    GameManager.mousepressed(x * screenW, y * screenH, 1)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    GameManager.mousemoved(x * screenW, y * screenH, (dx or 0) * screenW, (dy or 0) * screenH)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    GameManager.mousereleased(x * screenW, y * screenH, 1)
end

function love.resize(w, h)
    GameManager.resize(w, h)
end