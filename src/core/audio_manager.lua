-- src/core/audio_manager.lua
local AudioManager = {
    sounds = {},
    bgm = nil,
    currentTrack = nil,
    sfxVolume = 0.8,
    bgmVolume = 0.6,
    soundDataCache = {},

    -- Map aliases to actual audio files in audio/bgm/
    bgmAliases = {
        ["main_menu"] = "audio/bgm/main_menu.mp3",
        ["menu"] = "audio/bgm/main_menu.mp3",
        ["main_theme"] = "audio/bgm/main_menu.mp3",
        ["morning_theme"] = "audio/bgm/main_menu.mp3",
        ["desktop"] = "audio/bgm/desktop.mp3",
        ["desktop_theme"] = "audio/bgm/desktop.mp3",
        ["cat_cafe_theme"] = "audio/bgm/desktop.mp3",
        ["cat_cafe"] = "audio/bgm/desktop.mp3"
    }
}

-- Generate procedural SFX using Love2D SoundData
local function createTone(freqStart, freqEnd, duration, waveType, decay)
    local sampleRate = 44100
    local totalSamples = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(totalSamples, sampleRate, 16, 1)
    
    decay = decay or 3
    for i = 0, totalSamples - 1 do
        local t = i / sampleRate
        local progress = i / totalSamples
        local freq = freqStart + (freqEnd - freqStart) * progress
        local envelope = math.exp(-decay * progress)
        local sample = 0
        
        if waveType == "square" then
            sample = (math.sin(2 * math.pi * freq * t) > 0 and 0.5 or -0.5) * envelope
        elseif waveType == "sawtooth" then
            sample = (2 * ((freq * t) % 1) - 1) * envelope * 0.5
        elseif waveType == "noise" then
            sample = (math.random() * 2 - 1) * envelope * 0.4
        else -- sine
            sample = math.sin(2 * math.pi * freq * t) * envelope * 0.6
        end
        
        soundData:setSample(i, sample)
    end
    return love.audio.newSource(soundData, "static")
end

function AudioManager.init()
    if love.filesystem.getInfo("audio/sfx/tick.wav") then
        AudioManager.sounds["tick"] = love.audio.newSource("audio/sfx/tick.wav", "static")
    end
    if love.filesystem.getInfo("audio/sfx/wooh.wav") then
        AudioManager.sounds["wooh"] = love.audio.newSource("audio/sfx/wooh.wav", "static")
    end

    pcall(function()
        AudioManager.sounds["typewriter"] = createTone(620, 580, 0.035, "sine", 12)
        AudioManager.sounds["blip_low"] = createTone(340, 300, 0.04, "triangle", 10)
        AudioManager.sounds["click"] = createTone(880, 440, 0.05, "sine", 15)
        AudioManager.sounds["task_complete"] = createTone(523, 1046, 0.35, "sine", 3)
        AudioManager.sounds["levelup"] = createTone(440, 880, 0.5, "square", 2)
        AudioManager.sounds["error"] = createTone(180, 120, 0.25, "sawtooth", 4)
        AudioManager.sounds["glitch"] = createTone(400, 100, 0.12, "noise", 8)
        AudioManager.sounds["switch"] = createTone(200, 900, 0.2, "sine", 4)
        AudioManager.sounds["notification"] = createTone(784, 1174, 0.25, "sine", 5)
    end)
end

function AudioManager.playSFX(name, pitch, volumeScale)
    if not AudioManager.sounds[name] then
        name = "tick"
    end
    local src = AudioManager.sounds[name]
    if src then
        local clone = src:clone()
        clone:setVolume(AudioManager.sfxVolume * (volumeScale or 1.0))
        if pitch then
            clone:setPitch(pitch)
        end
        clone:play()
    end
end

function AudioManager.playBGM(pathOrName, loop)
    if loop == nil then loop = true end
    
    local resolvedPath = AudioManager.bgmAliases[pathOrName] or pathOrName
    if not resolvedPath then return end

    if AudioManager.currentTrack == resolvedPath and AudioManager.bgm and AudioManager.bgm:isPlaying() then
        return
    end

    if AudioManager.bgm then
        AudioManager.bgm:stop()
        AudioManager.bgm = nil
    end

    if resolvedPath and love.filesystem.getInfo(resolvedPath) then
        local ok, src = pcall(love.audio.newSource, resolvedPath, "stream")
        if ok and src then
            AudioManager.bgm = src
            AudioManager.bgm:setLooping(loop)
            AudioManager.bgm:setVolume(AudioManager.bgmVolume)
            AudioManager.bgm:play()
            AudioManager.currentTrack = resolvedPath
        end
    end
end

function AudioManager.stopBGM()
    if AudioManager.bgm then
        AudioManager.bgm:stop()
        AudioManager.bgm = nil
        AudioManager.currentTrack = nil
    end
end

function AudioManager.setSFXVolume(v)
    AudioManager.sfxVolume = math.max(0, math.min(1, v))
end

function AudioManager.setBGMVolume(v)
    AudioManager.bgmVolume = math.max(0, math.min(1, v))
    if AudioManager.bgm then
        AudioManager.bgm:setVolume(AudioManager.bgmVolume)
    end
end

return AudioManager
