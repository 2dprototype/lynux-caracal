-- dlc/music_player/music_player.lua
-- Media Player App with playlist, play/pause, seek, volume, and audio visualizer bars

local AudioManager = require("src.core.audio_manager")

local MusicPlayer = {}
MusicPlayer.__index = MusicPlayer

function MusicPlayer.new()
    local self = setmetatable({}, MusicPlayer)
    self.playlist = {
        { id = "main_menu", title = "Daydream Title Theme", artist = "Kamiyama Sound", duration = "2:45" },
        { id = "desktop",   title = "Meow Latte & Intranet", artist = "Cat Cafe Jazz", duration = "3:12" },
        { id = "morning",   title = "Morning High School Walk", artist = "Aki & Hiko", duration = "2:18" }
    }
    self.currentIndex = 1
    self.isPlaying = true
    self.visualizerBars = {}
    for i = 1, 24 do
        self.visualizerBars[i] = 0.2 + math.random() * 0.5
    end

    self.font = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 15) or love.graphics.newFont(15)
    self.titleFont = love.graphics.newFont("font/IBMPlexSans-Bold.ttf", 17) or love.graphics.newFont(17)
    self.smallFont = love.graphics.newFont("font/Nunito-Regular.ttf", 12) or love.graphics.newFont(12)
    return self
end

function MusicPlayer:playTrack(idx)
    self.currentIndex = math.max(1, math.min(#self.playlist, idx))
    local track = self.playlist[self.currentIndex]
    if track then
        AudioManager.playBGM(track.id)
        self.isPlaying = true
    end
end

function MusicPlayer:togglePlay()
    if self.isPlaying then
        if AudioManager.bgm then
            AudioManager.bgm:pause()
        end
        self.isPlaying = false
    else
        if AudioManager.bgm then
            AudioManager.bgm:play()
        else
            self:playTrack(self.currentIndex)
        end
        self.isPlaying = true
    end
end

function MusicPlayer:nextTrack()
    local nextIdx = self.currentIndex % #self.playlist + 1
    self:playTrack(nextIdx)
end

function MusicPlayer:prevTrack()
    local prevIdx = (self.currentIndex - 2 + #self.playlist) % #self.playlist + 1
    self:playTrack(prevIdx)
end

function MusicPlayer:update(dt)
    -- Animate visualizer bars
    if self.isPlaying then
        for i = 1, #self.visualizerBars do
            local target = 0.15 + 0.85 * math.abs(math.sin(love.timer.getTime() * 4 + i * 0.6)) * (0.5 + math.random() * 0.5)
            self.visualizerBars[i] = self.visualizerBars[i] + (target - self.visualizerBars[i]) * dt * 10
        end
    else
        for i = 1, #self.visualizerBars do
            self.visualizerBars[i] = math.max(0.05, self.visualizerBars[i] - dt * 0.8)
        end
    end
end

function MusicPlayer:draw(x, y, width, height)
    -- Background
    love.graphics.setColor(0.08, 0.10, 0.16)
    love.graphics.rectangle("fill", x, y, width, height)

    local curTrack = self.playlist[self.currentIndex] or { title = "Unknown", artist = "Unknown" }

    -- Header Album Art & Info Banner
    local headerH = 120
    love.graphics.setColor(0.12, 0.15, 0.24)
    love.graphics.rectangle("fill", x + 10, y + 10, width - 20, headerH, 6, 6)

    -- Album Art Thumbnail
    local artSize = 80
    local artX = x + 24
    local artY = y + 24
    love.graphics.setColor(0.18, 0.45, 0.85)
    love.graphics.rectangle("fill", artX, artY, artSize, artSize, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("♫", artX, artY + 24, artSize, "center")

    -- Track Title & Artist
    local infoX = artX + artSize + 16
    local infoW = width - infoX - 24
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.print(curTrack.title, infoX, y + 26)

    love.graphics.setColor(0.55, 0.65, 0.80)
    love.graphics.setFont(self.smallFont)
    love.graphics.print("Artist: " .. curTrack.artist, infoX, y + 54)
    love.graphics.print("Now Playing  •  " .. (self.isPlaying and "PLAYING" or "PAUSED"), infoX, y + 74)

    -- Visualizer Waveform Display
    local vizY = y + 140
    local vizH = 46
    local vizW = width - 24
    local barW = math.floor(vizW / #self.visualizerBars) - 2

    for i, val in ipairs(self.visualizerBars) do
        local bx = x + 12 + (i - 1) * (barW + 2)
        local bh = math.floor(vizH * val)
        local by = vizY + vizH - bh

        love.graphics.setColor(0.20 + val * 0.3, 0.55 + val * 0.4, 0.95, 0.9)
        love.graphics.rectangle("fill", bx, by, barW, bh, 2, 2)
    end

    -- Control Buttons Bar
    local ctrlY = vizY + vizH + 14
    local btns = {
        { id = "prev", label = "|<<", w = 48 },
        { id = "play", label = self.isPlaying and "PAUSE" or "PLAY", w = 76 },
        { id = "next", label = ">>|", w = 48 }
    }
    local totalW = 48 + 76 + 48 + 16
    local curX = x + math.floor((width - totalW) / 2)

    love.graphics.setFont(self.font)
    for _, btn in ipairs(btns) do
        btn.x = curX
        btn.y = ctrlY
        btn.h = 32

        if btn.id == "play" then
            love.graphics.setColor(0.15, 0.52, 0.92)
        else
            love.graphics.setColor(0.18, 0.22, 0.32)
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 4, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(btn.label, btn.x, btn.y + 7, btn.w, "center")

        curX = curX + btn.w + 8
    end

    -- Playlist View
    local listY = ctrlY + 44
    love.graphics.setColor(0.12, 0.15, 0.22)
    love.graphics.rectangle("fill", x + 10, listY, width - 20, height - (listY - y) - 10, 4, 4)

    love.graphics.setFont(self.smallFont)
    for i, track in ipairs(self.playlist) do
        local ty = listY + 6 + (i - 1) * 22
        if ty + 20 < y + height - 8 then
            if i == self.currentIndex then
                love.graphics.setColor(0.20, 0.50, 0.88, 0.35)
                love.graphics.rectangle("fill", x + 12, ty - 2, width - 24, 20, 3, 3)
                love.graphics.setColor(0.35, 0.75, 1.0)
                love.graphics.print("► " .. track.title, x + 16, ty)
            else
                love.graphics.setColor(0.7, 0.75, 0.85)
                love.graphics.print("  " .. track.title, x + 16, ty)
            end
            love.graphics.setColor(0.5, 0.55, 0.65)
            love.graphics.printf(track.duration, x + width - 64, ty, 44, "right")
        end
    end
end

function MusicPlayer:mousepressed(mx, my, button)
    if button ~= 1 then return false end
    local width = 460
    local height = 360
    local vizY = 140
    local ctrlY = vizY + 46 + 14
    local btns = {
        { id = "prev", w = 48 },
        { id = "play", w = 76 },
        { id = "next", w = 48 }
    }
    local totalW = 48 + 76 + 48 + 16
    local curX = math.floor((width - totalW) / 2)

    for _, btn in ipairs(btns) do
        if mx >= curX and mx <= curX + btn.w and my >= ctrlY and my <= ctrlY + 32 then
            if btn.id == "prev" then self:prevTrack()
            elseif btn.id == "play" then self:togglePlay()
            elseif btn.id == "next" then self:nextTrack()
            end
            AudioManager.playSFX("click")
            return true
        end
        curX = curX + btn.w + 8
    end

    -- Playlist click
    local listY = ctrlY + 44
    for i, _ in ipairs(self.playlist) do
        local ty = listY + 6 + (i - 1) * 22
        if mx >= 10 and mx <= width - 10 and my >= ty - 2 and my <= ty + 18 then
            self:playTrack(i)
            AudioManager.playSFX("click")
            return true
        end
    end

    return false
end

return MusicPlayer
