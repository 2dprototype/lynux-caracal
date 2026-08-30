-- src/core/audio_manager.lua
local AudioManager = {
    sounds = {},
    bgm = nil,
    currentTrack = nil,
    sfxVolume = 0.8,
    bgmVolume = 0.6,
    soundDataCache = {}
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
    -- Load pre-existing sound files if available
    if love.filesystem.getInfo("audio/tick.wav") then
        AudioManager.sounds["tick"] = love.audio.newSource("audio/tick.wav", "static")
    end
    if love.filesystem.getInfo("audio/wooh.wav") then
        AudioManager.sounds["wooh"] = love.audio.newSource("audio/wooh.wav", "static")
    end

    -- Procedural SFX generators
    pcall(function()
        -- Typewriter / Monologue blip
        AudioManager.sounds["typewriter"] = createTone(620, 580, 0.035, "sine", 12)
        -- Dialogue speaker blip (deeper)
        AudioManager.sounds["blip_low"] = createTone(340, 300, 0.04, "triangle", 10)
        -- UI Click
        AudioManager.sounds["click"] = createTone(880, 440, 0.05, "sine", 15)
        -- Task completed chime
        AudioManager.sounds["task_complete"] = createTone(523, 1046, 0.35, "sine", 3)
        -- Level Up fanfare
        AudioManager.sounds["levelup"] = createTone(440, 880, 0.5, "square", 2)
        -- Error buzz
        AudioManager.sounds["error"] = createTone(180, 120, 0.25, "sawtooth", 4)
        -- Glitch / Static
        AudioManager.sounds["glitch"] = createTone(400, 100, 0.12, "noise", 8)
        -- CRT power on/switch mode
        AudioManager.sounds["switch"] = createTone(200, 900, 0.2, "sine", 4)
        -- Notification toast ping
        AudioManager.sounds["notification"] = createTone(784, 1174, 0.25, "sine", 5)
    end)
end

function AudioManager.playSFX(name, pitch, volumeScale)
    if not AudioManager.sounds[name] then
        -- Fallback to tick or generic click
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
    if AudioManager.currentTrack == pathOrName and AudioManager.bgm and AudioManager.bgm:isPlaying() then
        return
    end

    if AudioManager.bgm then
        AudioManager.bgm:stop()
        AudioManager.bgm = nil
    end

    if pathOrName and love.filesystem.getInfo(pathOrName) then
        local ok, src = pcall(love.audio.newSource, pathOrName, "stream")
        if ok and src then
            AudioManager.bgm = src
            AudioManager.bgm:setLooping(loop)
            AudioManager.bgm:setVolume(AudioManager.bgmVolume)
            AudioManager.bgm:play()
            AudioManager.currentTrack = pathOrName
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
