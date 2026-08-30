-- dinoApp.lua
-- Complete Chrome Dino Runner port to LÖVE2D
local dinoApp = {}
dinoApp.__index = dinoApp

-- Configuration matching original Chrome Dino game
local CONFIG = {
  FPS = 60,
  WIDTH = 600,
  HEIGHT = 150,
  GROUND_Y = 127,
  BOTTOM_PAD = 10,
  GRAVITY = 0.6,
  INITIAL_JUMP_VELOCITY = 12,
  SPEED = 6,
  ACCELERATION = 0.001,
  MAX_SPEED = 13,
  INVERT_DISTANCE = 700,
  INVERT_FADE_DURATION = 12000,
  CLEAR_TIME = 3000,
  GAP_COEFFICIENT = 0.6,
  CLOUD_FREQUENCY = 0.5,
  MAX_CLOUDS = 6,
  MAX_OBSTACLE_LENGTH = 3,
  MAX_OBSTACLE_DUPLICATION = 2,
  BG_CLOUD_SPEED = 0.2,
  GAMEOVER_CLEAR_TIME = 750,
  MAX_BLINK_COUNT = 3,
  MIN_JUMP_HEIGHT = 35,
  MOBILE_SPEED_COEFFICIENT = 1.2,
  SPEED_DROP_COEFFICIENT = 3,
  RESOURCE_TEMPLATE_ID = 'audio-resources',
}

-- Sprite definitions (Low DPI - matching Chrome Dino)
local SPRITES = {
  CACTUS_SMALL = { x = 228, y = 2, w = 17, h = 35 },
  CACTUS_LARGE = { x = 332, y = 2, w = 25, h = 50 },
  CLOUD = { x = 86, y = 2, w = 46, h = 14 },
  HORIZON = { x = 2, y = 54, w = 600, h = 12 },
  MOON = { x = 484, y = 2, w = 40, h = 40 },
  PTERODACTYL = { x = 134, y = 2, w = 46, h = 40 },
  RESTART = { x = 2, y = 2, w = 36, h = 32 },
  TEXT_SPRITE = { x = 655, y = 2, w = 191, h = 11 },
  TREX = { x = 848, y = 2, w = 44, h = 47 },
  STAR = { x = 645, y = 2, w = 9, h = 9 },
}

-- Trex animation frames (pixel offsets in sprite sheet)
local TrexAnim = {
  WAITING = { frames = {44, 0}, msPerFrame = 1000/3 },
  RUNNING = { frames = {88, 132}, msPerFrame = 1000/12 },
  CRASHED = { frames = {220}, msPerFrame = 1000/60 },
  JUMPING = { frames = {0}, msPerFrame = 1000/60 },
  DUCKING = { frames = {264, 323}, msPerFrame = 1000/8 },
}

-- Trex collision boxes
local TrexCollisionBoxes = {
  DUCKING = {
    {x = 1, y = 18, w = 55, h = 25}
  },
  RUNNING = {
    {x = 22, y = 0, w = 17, h = 16},
    {x = 1, y = 18, w = 30, h = 9},
    {x = 10, y = 35, w = 14, h = 8},
    {x = 1, y = 24, w = 29, h = 5},
    {x = 5, y = 30, w = 21, h = 4},
    {x = 9, y = 34, w = 15, h = 4}
  }
}

-- NightMode phases
local NightModePhases = {140, 120, 100, 60, 40, 20, 0}

-- Distance meter y positions for digits
local DistanceMeterYPos = {0, 13, 27, 40, 53, 67, 80, 93, 107, 120}

-- Game state
local GameState = {
  playing = false,
  crashed = false,
  paused = false,
  activated = false,
  playingIntro = false,
  inverted = false,
  invertTimer = 0,
  invertTrigger = false,
  highScore = 0,
  speed = CONFIG.SPEED,
  distanceRan = 0,
  time = 0,
  runningTime = 0,
  playCount = 0,
}

local spritesheet = nil
local sounds = {}

------------------------------------------------------------
-- Utility Functions
------------------------------------------------------------
function math.round(n)
  return math.floor(n + 0.5)
end

local function getRandomNum(min, max)
  return math.floor(love.math.random() * (max - min + 1)) + min
end

local function getTimeStamp()
  return love.timer.getTime() * 1000
end

-- Collision Box class
local CollisionBox = {}
CollisionBox.__index = CollisionBox

function CollisionBox:new(x, y, w, h)
  local self = setmetatable({}, CollisionBox)
  self.x = x
  self.y = y
  self.width = w
  self.height = h
  return self
end

-- Box comparison for collision detection
local function boxCompare(tRexBox, obstacleBox)
  if (tRexBox.x < obstacleBox.x + obstacleBox.width and
      tRexBox.x + tRexBox.width > obstacleBox.x and
      tRexBox.y < obstacleBox.y + obstacleBox.height and
      tRexBox.height + tRexBox.y > obstacleBox.y) then
    return true
  end
  return false
end

-- Create adjusted collision box
local function createAdjustedCollisionBox(box, adjustment)
  return CollisionBox:new(
    box.x + adjustment.x,
    box.y + adjustment.y,
    box.width,
    box.height
  )
end

-- Check for collision between obstacle and trex
local function checkForCollision(obstacle, tRex)
  local tRexBox = CollisionBox:new(
    tRex.xPos + 1,
    tRex.yPos + 1,
    tRex.config.WIDTH - 2,
    tRex.config.HEIGHT - 2
  )
  
  local obstacleBox = CollisionBox:new(
    obstacle.xPos + 1,
    obstacle.yPos + 1,
    obstacle.typeConfig.width * obstacle.size - 2,
    obstacle.typeConfig.height - 2
  )
  
  -- Simple outer bounds check
  if boxCompare(tRexBox, obstacleBox) then
    local collisionBoxes = obstacle.collisionBoxes
    local tRexCollisionBoxes = tRex.ducking and 
      TrexCollisionBoxes.DUCKING or TrexCollisionBoxes.RUNNING
    
    -- Detailed axis aligned box check
    for t = 1, #tRexCollisionBoxes do
      for i = 1, #collisionBoxes do
        local adjTrexBox = createAdjustedCollisionBox(tRexCollisionBoxes[t], tRexBox)
        local adjObstacleBox = createAdjustedCollisionBox(collisionBoxes[i], obstacleBox)
        local crashed = boxCompare(adjTrexBox, adjObstacleBox)
        
        if crashed then
          return {adjTrexBox, adjObstacleBox}
        end
      end
    end
  end
  
  return false
end

------------------------------------------------------------
-- Sounds
------------------------------------------------------------
local SoundManager = {}
SoundManager.__index = SoundManager

function SoundManager:new()
  local self = setmetatable({}, SoundManager)
  self.sounds = {}
  self.loaded = false
  return self
end

function SoundManager:loadSounds()
  -- In LÖVE2D, we'd typically load .ogg or .wav files
  -- Since we can't decode base64 MP3 easily, we'll use simple sound synthesis
  -- or skip sounds if files aren't available
  self.loaded = true
end

function SoundManager:playSound(name)
  if not self.loaded then return end
  if self.sounds[name] then
    self.sounds[name]:stop()
    self.sounds[name]:play()
  end
end

------------------------------------------------------------
-- Cloud Object
------------------------------------------------------------
local Cloud = {}
Cloud.__index = Cloud

Cloud.config = {
  HEIGHT = 14,
  MAX_CLOUD_GAP = 400,
  MAX_SKY_LEVEL = 30,
  MIN_CLOUD_GAP = 100,
  MIN_SKY_LEVEL = 71,
  WIDTH = 46
}

function Cloud:new(canvas, spritePos, containerWidth)
  local self = setmetatable({}, Cloud)
  self.canvasCtx = canvas
  self.spritePos = spritePos
  self.containerWidth = containerWidth
  self.xPos = containerWidth
  self.yPos = getRandomNum(Cloud.config.MAX_SKY_LEVEL, Cloud.config.MIN_SKY_LEVEL)
  self.remove = false
  self.cloudGap = getRandomNum(Cloud.config.MIN_CLOUD_GAP, Cloud.config.MAX_CLOUD_GAP)
  return self
end

function Cloud:draw()
  love.graphics.draw(spritesheet, 
    love.graphics.newQuad(self.spritePos.x, self.spritePos.y, 
      Cloud.config.WIDTH, Cloud.config.HEIGHT, 
      spritesheet:getDimensions()),
    self.xPos, self.yPos)
end

function Cloud:update(speed)
  if not self.remove then
    self.xPos = self.xPos - speed
    if not self:isVisible() then
      self.remove = true
    end
  end
end

function Cloud:isVisible()
  return self.xPos + Cloud.config.WIDTH > 0
end

------------------------------------------------------------
-- NightMode
------------------------------------------------------------
local NightMode = {}
NightMode.__index = NightMode

NightMode.config = {
  FADE_SPEED = 0.035,
  HEIGHT = 40,
  MOON_SPEED = 0.25,
  NUM_STARS = 2,
  STAR_SIZE = 9,
  STAR_SPEED = 0.3,
  STAR_MAX_Y = 70,
  WIDTH = 20
}

function NightMode:new(canvas, spritePos, containerWidth)
  local self = setmetatable({}, NightMode)
  self.spritePos = spritePos
  self.canvas = canvas
  self.xPos = containerWidth - 50
  self.yPos = 30
  self.currentPhase = 1
  self.opacity = 0
  self.containerWidth = containerWidth
  self.stars = {}
  self.drawStars = false
  self:placeStars()
  return self
end

function NightMode:placeStars()
  local segmentSize = math.round(self.containerWidth / NightMode.config.NUM_STARS)
  
  for i = 1, NightMode.config.NUM_STARS do
    self.stars[i] = {
      x = getRandomNum(segmentSize * (i - 1), segmentSize * i),
      y = getRandomNum(0, NightMode.config.STAR_MAX_Y),
      sourceY = SPRITES.STAR.y + NightMode.config.STAR_SIZE * (i - 1)
    }
  end
end

function NightMode:updateXPos(currentPos, speed)
  if currentPos < -NightMode.config.WIDTH then
    currentPos = self.containerWidth
  else
    currentPos = currentPos - speed
  end
  return currentPos
end

function NightMode:update(activated, delta)
  -- Moon phase
  if activated and self.opacity == 0 then
    self.currentPhase = self.currentPhase + 1
    if self.currentPhase > #NightModePhases then
      self.currentPhase = 1
    end
  end
  
  -- Fade in / out
  if activated and (self.opacity < 1 or self.opacity == 0) then
    self.opacity = self.opacity + NightMode.config.FADE_SPEED
  elseif self.opacity > 0 then
    self.opacity = self.opacity - NightMode.config.FADE_SPEED
  end
  
  -- Set moon positioning
  if self.opacity > 0 then
    self.xPos = self:updateXPos(self.xPos, NightMode.config.MOON_SPEED)
    
    -- Update stars
    if self.drawStars then
      for i = 1, NightMode.config.NUM_STARS do
        self.stars[i].x = self:updateXPos(self.stars[i].x, NightMode.config.STAR_SPEED)
      end
    end
  else
    self.opacity = 0
    self:placeStars()
  end
  self.drawStars = true
end

function NightMode:draw()
  local moonSourceWidth = self.currentPhase == 4 and NightMode.config.WIDTH * 2 or NightMode.config.WIDTH
  local moonSourceHeight = NightMode.config.HEIGHT
  local moonSourceX = self.spritePos.x + NightModePhases[self.currentPhase]
  local moonOutputWidth = moonSourceWidth
  local starSize = NightMode.config.STAR_SIZE
  local starSourceX = SPRITES.STAR.x
  
  local r, g, b, a = love.graphics.getColor()
  
  -- Stars
  if self.drawStars then
    for i = 1, NightMode.config.NUM_STARS do
      love.graphics.setColor(1, 1, 1, self.opacity)
      love.graphics.draw(spritesheet,
        love.graphics.newQuad(starSourceX, self.stars[i].sourceY, 
          starSize, starSize, spritesheet:getDimensions()),
        math.round(self.stars[i].x), self.stars[i].y)
    end
  end
  
  -- Moon
  love.graphics.setColor(1, 1, 1, self.opacity)
  love.graphics.draw(spritesheet,
    love.graphics.newQuad(moonSourceX, self.spritePos.y, 
      moonSourceWidth, moonSourceHeight, spritesheet:getDimensions()),
    math.round(self.xPos), self.yPos)
  
  love.graphics.setColor(r, g, b, a)
end

function NightMode:reset()
  self.currentPhase = 1
  self.opacity = 0
  self:update(false, 0)
end

------------------------------------------------------------
-- HorizonLine
------------------------------------------------------------
local HorizonLine = {}
HorizonLine.__index = HorizonLine

HorizonLine.dimensions = {
  WIDTH = 600,
  HEIGHT = 12,
  YPOS = 127
}

function HorizonLine:new(canvas, spritePos)
  local self = setmetatable({}, HorizonLine)
  self.spritePos = spritePos
  self.canvas = canvas
  self.sourceDimensions = {}
  self.dimensions = {
    WIDTH = HorizonLine.dimensions.WIDTH,
    HEIGHT = HorizonLine.dimensions.HEIGHT,
    YPOS = HorizonLine.dimensions.YPOS
  }
  self.sourceXPos = {self.spritePos.x, self.spritePos.x + self.dimensions.WIDTH}
  self.xPos = {0, HorizonLine.dimensions.WIDTH}
  self.yPos = HorizonLine.dimensions.YPOS
  self.bumpThreshold = 0.5
  self:setSourceDimensions()
  return self
end

function HorizonLine:setSourceDimensions()
  for dimension, value in pairs(HorizonLine.dimensions) do
    if dimension ~= 'YPOS' then
      self.sourceDimensions[dimension] = value
    else
      self.sourceDimensions[dimension] = value
    end
    self.dimensions[dimension] = value
  end
end

function HorizonLine:getRandomType()
  return love.math.random() > self.bumpThreshold and self.dimensions.WIDTH or 0
end

function HorizonLine:draw()
  love.graphics.draw(spritesheet,
    love.graphics.newQuad(self.sourceXPos[1], self.spritePos.y,
      self.sourceDimensions.WIDTH, self.sourceDimensions.HEIGHT,
      spritesheet:getDimensions()),
    math.floor(self.xPos[1]), self.yPos)
  
  love.graphics.draw(spritesheet,
    love.graphics.newQuad(self.sourceXPos[2], self.spritePos.y,
      self.sourceDimensions.WIDTH, self.sourceDimensions.HEIGHT,
      spritesheet:getDimensions()),
    math.floor(self.xPos[2]), self.yPos)
end

function HorizonLine:updateXPos(pos, increment)
  local line1 = pos
  local line2 = line1 == 1 and 2 or 1
  
  self.xPos[line1] = self.xPos[line1] - increment
  self.xPos[line2] = self.xPos[line1] + self.dimensions.WIDTH
  
  if self.xPos[line1] <= -self.dimensions.WIDTH then
    self.xPos[line1] = self.xPos[line1] + self.dimensions.WIDTH * 2
    self.xPos[line2] = self.xPos[line1] - self.dimensions.WIDTH
    self.sourceXPos[line1] = self:getRandomType() + self.spritePos.x
  end
end

function HorizonLine:update(deltaTime, speed)
  local increment = speed * (CONFIG.FPS / 1000) * deltaTime
  
  if self.xPos[1] <= 0 then
    self:updateXPos(1, increment)
  else
    self:updateXPos(2, increment)
  end
end

function HorizonLine:reset()
  self.xPos[1] = 0
  self.xPos[2] = HorizonLine.dimensions.WIDTH
end

------------------------------------------------------------
-- Obstacle Types
------------------------------------------------------------
local ObstacleTypes = {
  {
    type = 'CACTUS_SMALL',
    width = 17,
    height = 35,
    yPos = 105,
    multipleSpeed = 4,
    minGap = 120,
    minSpeed = 0,
    collisionBoxes = {
      CollisionBox:new(0, 7, 5, 27),
      CollisionBox:new(4, 0, 6, 34),
      CollisionBox:new(10, 4, 7, 14)
    }
  },
  {
    type = 'CACTUS_LARGE',
    width = 25,
    height = 50,
    yPos = 90,
    multipleSpeed = 7,
    minGap = 120,
    minSpeed = 0,
    collisionBoxes = {
      CollisionBox:new(0, 12, 7, 38),
      CollisionBox:new(8, 0, 7, 49),
      CollisionBox:new(13, 10, 10, 38)
    }
  },
  {
    type = 'PTERODACTYL',
    width = 46,
    height = 40,
    yPos = {100, 75, 50},
    yPosMobile = {100, 50},
    multipleSpeed = 999,
    minSpeed = 8.5,
    minGap = 150,
    collisionBoxes = {
      CollisionBox:new(15, 15, 16, 5),
      CollisionBox:new(18, 21, 24, 6),
      CollisionBox:new(2, 14, 4, 3),
      CollisionBox:new(6, 10, 4, 7),
      CollisionBox:new(10, 8, 6, 9)
    },
    numFrames = 2,
    frameRate = 1000 / 6,
    speedOffset = 0.8
  }
}

------------------------------------------------------------
-- Obstacle Object
------------------------------------------------------------
local Obstacle = {}
Obstacle.__index = Obstacle

Obstacle.MAX_GAP_COEFFICIENT = 1.5
Obstacle.MAX_OBSTACLE_LENGTH = 3

function Obstacle:new(canvasCtx, typeConfig, spriteImgPos, dimensions, gapCoefficient, speed, opt_xOffset)
  local self = setmetatable({}, Obstacle)
  self.canvasCtx = canvasCtx
  self.spritePos = spriteImgPos
  self.typeConfig = typeConfig
  self.gapCoefficient = gapCoefficient
  self.size = getRandomNum(1, Obstacle.MAX_OBSTACLE_LENGTH)
  self.dimensions = {WIDTH = dimensions.WIDTH, HEIGHT = dimensions.HEIGHT}
  self.remove = false
  self.xPos = dimensions.WIDTH + (opt_xOffset or 0)
  self.yPos = 0
  self.width = 0
  self.collisionBoxes = {}
  self.gap = 0
  self.speedOffset = 0
  self.currentFrame = 1
  self.timer = 0
  
  self:init(speed)
  return self
end

function Obstacle:init(speed)
  self:cloneCollisionBoxes()
  
  -- Only allow sizing if we're at the right speed
  if self.size > 1 and self.typeConfig.multipleSpeed > speed then
    self.size = 1
  end
  
  self.width = self.typeConfig.width * self.size
  
  -- Check if obstacle can be positioned at various heights
  if type(self.typeConfig.yPos) == "table" then
    local yPosConfig = self.typeConfig.yPos
    self.yPos = yPosConfig[getRandomNum(1, #yPosConfig)]
  else
    self.yPos = self.typeConfig.yPos
  end
  
  -- Make collision box adjustments
  if self.size > 1 then
    self.collisionBoxes[2].width = self.width - self.collisionBoxes[1].width -
      self.collisionBoxes[3].width
    self.collisionBoxes[3].x = self.width - self.collisionBoxes[3].width
  end
  
  -- For obstacles that go at a different speed from the horizon
  if self.typeConfig.speedOffset then
    self.speedOffset = love.math.random() > 0.5 and self.typeConfig.speedOffset or
      -self.typeConfig.speedOffset
  end
  
  self.gap = self:getGap(self.gapCoefficient, speed)
end

function Obstacle:draw()
  local sourceWidth = self.typeConfig.width
  local sourceHeight = self.typeConfig.height
  
  -- X position in sprite
  local sourceX = (sourceWidth * self.size) * (0.5 * (self.size - 1)) + self.spritePos.x
  
  -- Animation frames
  if self.currentFrame > 1 then
    sourceX = sourceX + sourceWidth * (self.currentFrame - 1)
  end
  
  love.graphics.draw(spritesheet,
    love.graphics.newQuad(sourceX, self.spritePos.y,
      sourceWidth * self.size, sourceHeight,
      spritesheet:getDimensions()),
    math.floor(self.xPos), self.yPos)
end

function Obstacle:update(deltaTime, speed)
  if not self.remove then
    if self.typeConfig.speedOffset then
      speed = speed + self.speedOffset
    end
    self.xPos = self.xPos - (speed * CONFIG.FPS / 1000) * deltaTime
    
    -- Update frame
    if self.typeConfig.numFrames then
      self.timer = self.timer + deltaTime
      if self.timer >= self.typeConfig.frameRate then
        self.currentFrame = self.currentFrame == self.typeConfig.numFrames and 1 or self.currentFrame + 1
        self.timer = 0
      end
    end
    
    if not self:isVisible() then
      self.remove = true
    end
  end
end

function Obstacle:getGap(gapCoefficient, speed)
  local minGap = math.round(self.width * speed + self.typeConfig.minGap * gapCoefficient)
  local maxGap = math.round(minGap * Obstacle.MAX_GAP_COEFFICIENT)
  return getRandomNum(minGap, maxGap)
end

function Obstacle:isVisible()
  return self.xPos + self.width > 0
end

function Obstacle:cloneCollisionBoxes()
  local collisionBoxes = self.typeConfig.collisionBoxes
  for i = #collisionBoxes, 1, -1 do
    self.collisionBoxes[i] = CollisionBox:new(
      collisionBoxes[i].x,
      collisionBoxes[i].y,
      collisionBoxes[i].width,
      collisionBoxes[i].height
    )
  end
end

------------------------------------------------------------
-- Trex Object
------------------------------------------------------------
local Trex = {}
Trex.__index = Trex

Trex.config = {
  DROP_VELOCITY= -5,
  GRAVITY = 0.6,
  HEIGHT = 47,
  HEIGHT_DUCK = 25,
  INIITAL_JUMP_VELOCITY = -10,
  INTRO_DURATION = 1500,
  MAX_JUMP_HEIGHT = 30,
  MIN_JUMP_HEIGHT = 30,
  SPEED_DROP_COEFFICIENT = 3,
  SPRITE_WIDTH = 262,
  START_X_POS = 50,
  WIDTH = 44,
  WIDTH_DUCK = 59
}

Trex.status = {
  CRASHED = 'CRASHED',
  DUCKING = 'DUCKING',
  JUMPING = 'JUMPING',
  RUNNING = 'RUNNING',
  WAITING = 'WAITING'
}

Trex.BLINK_TIMING = 7000

function Trex:new(canvas, spritePos)
  local self = setmetatable({}, Trex)
  self.canvas = canvas
  self.spritePos = spritePos
  self.xPos = 0
  self.yPos = 0
  self.groundYPos = 0
  self.currentFrame = 1
  self.currentAnimFrames = {}
  self.blinkDelay = 0
  self.blinkCount = 0
  self.animStartTime = 0
  self.timer = 0
  self.msPerFrame = 1000 / CONFIG.FPS
  self.config = {
    DROP_VELOCITY = Trex.config.DROP_VELOCITY,
    GRAVITY = Trex.config.GRAVITY,
    HEIGHT = Trex.config.HEIGHT,
    HEIGHT_DUCK = Trex.config.HEIGHT_DUCK,
    INIITAL_JUMP_VELOCITY = Trex.config.INIITAL_JUMP_VELOCITY,
    INTRO_DURATION = Trex.config.INTRO_DURATION,
    MAX_JUMP_HEIGHT = Trex.config.MAX_JUMP_HEIGHT,
    MIN_JUMP_HEIGHT = Trex.config.MIN_JUMP_HEIGHT,
    SPEED_DROP_COEFFICIENT = Trex.config.SPEED_DROP_COEFFICIENT,
    SPRITE_WIDTH = Trex.config.SPRITE_WIDTH,
    START_X_POS = Trex.config.START_X_POS,
    WIDTH = Trex.config.WIDTH,
    WIDTH_DUCK = Trex.config.WIDTH_DUCK
  }
  self.status = Trex.status.WAITING
  self.jumping = false
  self.ducking = false
  self.jumpVelocity = 0
  self.reachedMinHeight = false
  self.speedDrop = false
  self.jumpCount = 0
  self.jumpspotX = 0
  self.playingIntro = false
  
  self:init()
  return self
end

function Trex:init()
  self.groundYPos = CONFIG.HEIGHT - self.config.HEIGHT - CONFIG.BOTTOM_PAD
  self.yPos = self.groundYPos
  self.minJumpHeight = self.groundYPos - self.config.MIN_JUMP_HEIGHT
  self:update(0, Trex.status.WAITING)
end

function Trex:update(deltaTime, opt_status)
  self.timer = self.timer + deltaTime
  
  -- Update the status
  if opt_status then
    self.status = opt_status
    self.currentFrame = 1
    self.msPerFrame = TrexAnim[opt_status].msPerFrame
    self.currentAnimFrames = TrexAnim[opt_status].frames
    
    if opt_status == Trex.status.WAITING then
      self.animStartTime = getTimeStamp()
      self:setBlinkDelay()
    end
  end
  
  -- Game intro animation, T-rex moves in from the left
  if self.playingIntro and self.xPos < self.config.START_X_POS then
    self.xPos = self.xPos + math.round((self.config.START_X_POS / 
      self.config.INTRO_DURATION) * deltaTime)
  end
  
  if self.status == Trex.status.WAITING then
    self:blink(getTimeStamp())
  end
  
  -- Update the frame position
  if self.timer >= self.msPerFrame then
    self.currentFrame = self.currentFrame == #self.currentAnimFrames and 1 or self.currentFrame + 1
    self.timer = 0
  end
  
  -- Speed drop becomes duck if the down key is still being pressed
  if self.speedDrop and self.yPos == self.groundYPos then
    self.speedDrop = false
    self:setDuck(true)
  end
end

function Trex:draw()
  local sourceX = self.currentAnimFrames[self.currentFrame] or 0
  local sourceY = 0
  local sourceWidth = (self.ducking and self.status ~= Trex.status.CRASHED) and 
    self.config.WIDTH_DUCK or self.config.WIDTH
  local sourceHeight = self.config.HEIGHT
  
  -- Adjustments for sprite sheet position
  sourceX = sourceX + self.spritePos.x
  sourceY = sourceY + self.spritePos.y
  
  -- Ducking
  if self.ducking and self.status ~= Trex.status.CRASHED then
    love.graphics.draw(spritesheet,
      love.graphics.newQuad(sourceX, sourceY, sourceWidth, sourceHeight,
        spritesheet:getDimensions()),
      math.floor(self.xPos), math.floor(self.yPos))
  else
    -- Crashed whilst ducking. Trex is standing up so needs adjustment
    if self.ducking and self.status == Trex.status.CRASHED then
      self.xPos = self.xPos + 1
    end
    -- Standing / running
    love.graphics.draw(spritesheet,
      love.graphics.newQuad(sourceX, sourceY, sourceWidth, sourceHeight,
        spritesheet:getDimensions()),
      math.floor(self.xPos), math.floor(self.yPos))
  end
end

function Trex:setBlinkDelay()
  self.blinkDelay = math.ceil(love.math.random() * Trex.BLINK_TIMING)
end

function Trex:blink(time)
  local deltaTime = time - self.animStartTime
  
  if deltaTime >= self.blinkDelay then
    if self.currentFrame == 2 then
      -- Set new random delay to blink
      self:setBlinkDelay()
      self.animStartTime = time
      self.blinkCount = self.blinkCount + 1
    end
  end
end

function Trex:startJump(speed)
  if not self.jumping then
    self:update(0, Trex.status.JUMPING)
    -- Tweak the jump velocity based on the speed
    self.jumpVelocity = self.config.INIITAL_JUMP_VELOCITY - (speed / 10)
    self.jumping = true
    self.reachedMinHeight = false
    self.speedDrop = false
  end
end

function Trex:endJump()
  if self.reachedMinHeight and self.jumpVelocity < self.config.DROP_VELOCITY then
    self.jumpVelocity = self.config.DROP_VELOCITY
  end
end

function Trex:updateJump(deltaTime, speed)
  local msPerFrame = TrexAnim[self.status].msPerFrame
  local framesElapsed = deltaTime / msPerFrame
  
  -- Speed drop makes Trex fall faster
  if self.speedDrop then
    self.yPos = self.yPos + (self.jumpVelocity * 
      self.config.SPEED_DROP_COEFFICIENT * framesElapsed)
  else
    self.yPos = self.yPos + (self.jumpVelocity * framesElapsed)
  end
  
  self.jumpVelocity = self.jumpVelocity + self.config.GRAVITY * framesElapsed
  
  -- Minimum height has been reached
  if self.yPos < self.minJumpHeight or self.speedDrop then
    self.reachedMinHeight = true
  end
  
  -- Reached max height
  if self.yPos < self.config.MAX_JUMP_HEIGHT or self.speedDrop then
    self:endJump()
  end
  
  -- Back down at ground level. Jump completed
  if self.yPos > self.groundYPos then
    self:reset()
    self.jumpCount = self.jumpCount + 1
  end
  
  self:update(deltaTime)
end

function Trex:setSpeedDrop()
  self.speedDrop = true
  self.jumpVelocity = 1
end

function Trex:setDuck(isDucking)
  if isDucking and self.status ~= Trex.status.DUCKING then
    self:update(0, Trex.status.DUCKING)
    self.ducking = true
  elseif self.status == Trex.status.DUCKING then
    self:update(0, Trex.status.RUNNING)
    self.ducking = false
  end
end

function Trex:reset()
  self.yPos = self.groundYPos
  self.jumpVelocity = 0
  self.jumping = false
  self.ducking = false
  self:update(0, Trex.status.RUNNING)
  self.speedDrop = false
  self.jumpCount = 0
end

------------------------------------------------------------
-- Distance Meter
------------------------------------------------------------
local DistanceMeter = {}
DistanceMeter.__index = DistanceMeter

DistanceMeter.dimensions = {
  WIDTH = 10,
  HEIGHT = 13,
  DEST_WIDTH = 11
}

DistanceMeter.config = {
  MAX_DISTANCE_UNITS = 5,
  ACHIEVEMENT_DISTANCE = 100,
  COEFFICIENT = 0.025,
  FLASH_DURATION = 1000 / 4,
  FLASH_ITERATIONS = 3
}

function DistanceMeter:new(canvas, spritePos, canvasWidth)
  local self = setmetatable({}, DistanceMeter)
  self.canvas = canvas
  self.spritePos = spritePos
  self.x = 0
  self.y = 5
  self.currentDistance = 0
  self.maxScore = 0
  self.highScore = {}
  self.digits = {}
  self.acheivement = false
  self.defaultString = ''
  self.flashTimer = 0
  self.flashIterations = 0
  self.invertTrigger = false
  self.config = {
    MAX_DISTANCE_UNITS = DistanceMeter.config.MAX_DISTANCE_UNITS,
    ACHIEVEMENT_DISTANCE = DistanceMeter.config.ACHIEVEMENT_DISTANCE,
    COEFFICIENT = DistanceMeter.config.COEFFICIENT,
    FLASH_DURATION = DistanceMeter.config.FLASH_DURATION,
    FLASH_ITERATIONS = DistanceMeter.config.FLASH_ITERATIONS
  }
  self.maxScoreUnits = self.config.MAX_DISTANCE_UNITS
  self:init(canvasWidth)
  return self
end

function DistanceMeter:init(width)
  local maxDistanceStr = ''
  
  self:calcXPos(width)
  self.maxScore = self.maxScoreUnits
  
  for i = 0, self.maxScoreUnits - 1 do
    self.defaultString = self.defaultString .. '0'
    maxDistanceStr = maxDistanceStr .. '9'
  end
  
  self.maxScore = tonumber(maxDistanceStr)
end

function DistanceMeter:calcXPos(canvasWidth)
  self.x = canvasWidth - (DistanceMeter.dimensions.DEST_WIDTH * (self.maxScoreUnits + 1))
end

function DistanceMeter:drawDigit(digitPos, value, opt_highScore)
  local sourceWidth = DistanceMeter.dimensions.WIDTH
  local sourceHeight = DistanceMeter.dimensions.HEIGHT
  local sourceX = DistanceMeter.dimensions.WIDTH * value
  local sourceY = 0
  
  local targetX = digitPos * DistanceMeter.dimensions.DEST_WIDTH
  local targetY = self.y
  local targetWidth = DistanceMeter.dimensions.WIDTH
  local targetHeight = DistanceMeter.dimensions.HEIGHT
  
  sourceX = sourceX + self.spritePos.x
  sourceY = sourceY + self.spritePos.y
  
  if opt_highScore then
    -- Left of the current score
    local highScoreX = self.x - (self.maxScoreUnits * 2) * DistanceMeter.dimensions.WIDTH
    love.graphics.draw(spritesheet,
      love.graphics.newQuad(sourceX, sourceY, sourceWidth, sourceHeight,
        spritesheet:getDimensions()),
      highScoreX + targetX, targetY)
  else
    love.graphics.draw(spritesheet,
      love.graphics.newQuad(sourceX, sourceY, sourceWidth, sourceHeight,
        spritesheet:getDimensions()),
      self.x + targetX, targetY)
  end
end

function DistanceMeter:getActualDistance(distance)
  return distance and math.round(distance * self.config.COEFFICIENT) or 0
end

function DistanceMeter:update(deltaTime, distance)
  local playSound = false
  
  if not self.acheivement then
    distance = self:getActualDistance(distance)
    
    -- Score has gone beyond the initial digit count
    if distance > self.maxScore and self.maxScoreUnits == self.config.MAX_DISTANCE_UNITS then
      self.maxScoreUnits = self.maxScoreUnits + 1
      self.maxScore = tonumber(tostring(self.maxScore) .. '9')
    end
    
    if distance > 0 then
      -- Acheivement unlocked
      if distance % self.config.ACHIEVEMENT_DISTANCE == 0 then
        self.acheivement = true
        self.flashTimer = 0
        playSound = true
      end
      
      -- Create a string representation of the distance with leading 0
      local distanceStr = string.sub(self.defaultString .. distance, -self.maxScoreUnits)
      self.digits = {}
      for i = 1, #distanceStr do
        table.insert(self.digits, tonumber(string.sub(distanceStr, i, i)))
      end
    else
      self.digits = {}
      for i = 1, #self.defaultString do
        table.insert(self.digits, tonumber(string.sub(distanceStr or self.defaultString, i, i)))
      end
    end
  else
    -- Control flashing of the score on reaching acheivement
    if self.flashIterations <= self.config.FLASH_ITERATIONS then
      self.flashTimer = self.flashTimer + deltaTime
      
      if self.flashTimer < self.config.FLASH_DURATION then
        self.paint = false
      elseif self.flashTimer > self.config.FLASH_DURATION * 2 then
        self.flashTimer = 0
        self.flashIterations = self.flashIterations + 1
        self.paint = true
      end
    else
      self.acheivement = false
      self.flashIterations = 0
      self.flashTimer = 0
      self.paint = true
    end
  end
  
  return playSound
end

function DistanceMeter:draw()
  if self.paint ~= false then
    for i = #self.digits, 1, -1 do
      self:drawDigit(i - 1, self.digits[i])
    end
  end
  self:drawHighScore()
end

function DistanceMeter:drawHighScore()
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(1, 1, 1, 0.8)
  
  for i = #self.highScore, 1, -1 do
    self:drawDigit(i - 1, self.highScore[i], true)
  end
  
  love.graphics.setColor(r, g, b, a)
end

function DistanceMeter:setHighScore(distance)
  distance = self:getActualDistance(distance)
  local highScoreStr = string.sub(self.defaultString .. distance, -self.maxScoreUnits)
  
  self.highScore = {10, 11, -1} -- H, I, spacer
  for i = 1, #highScoreStr do
    table.insert(self.highScore, tonumber(string.sub(highScoreStr, i, i)))
  end
end

function DistanceMeter:reset(highScore)
  self:update(0, 0)
  self.acheivement = false
end

------------------------------------------------------------
-- Game Over Panel
------------------------------------------------------------
local GameOverPanel = {}
GameOverPanel.__index = GameOverPanel

GameOverPanel.dimensions = {
  TEXT_X = 0,
  TEXT_Y = 13,
  TEXT_WIDTH = 191,
  TEXT_HEIGHT = 11,
  RESTART_WIDTH = 36,
  RESTART_HEIGHT = 32
}

function GameOverPanel:new(canvas, textImgPos, restartImgPos, dimensions)
  local self = setmetatable({}, GameOverPanel)
  self.canvas = canvas
  self.textImgPos = textImgPos
  self.restartImgPos = restartImgPos
  self.canvasDimensions = {WIDTH = dimensions.WIDTH, HEIGHT = dimensions.HEIGHT}
  return self
end

function GameOverPanel:updateDimensions(width, opt_height)
  self.canvasDimensions.WIDTH = width
  if opt_height then
    self.canvasDimensions.HEIGHT = opt_height
  end
end

function GameOverPanel:draw()
  local dimensions = GameOverPanel.dimensions
  local centerX = self.canvasDimensions.WIDTH / 2
  
  -- Game over text
  local textSourceX = dimensions.TEXT_X
  local textSourceY = dimensions.TEXT_Y
  local textSourceWidth = dimensions.TEXT_WIDTH
  local textSourceHeight = dimensions.TEXT_HEIGHT
  
  local textTargetX = math.round(centerX - (dimensions.TEXT_WIDTH / 2))
  local textTargetY = math.round((self.canvasDimensions.HEIGHT - 25) / 3)
  local textTargetWidth = dimensions.TEXT_WIDTH
  local textTargetHeight = dimensions.TEXT_HEIGHT
  
  local restartSourceWidth = dimensions.RESTART_WIDTH
  local restartSourceHeight = dimensions.RESTART_HEIGHT
  local restartTargetX = centerX - (dimensions.RESTART_WIDTH / 2)
  local restartTargetY = self.canvasDimensions.HEIGHT / 2
  
  textSourceX = textSourceX + self.textImgPos.x
  textSourceY = textSourceY + self.textImgPos.y
  
  -- Game over text from sprite
  love.graphics.draw(spritesheet,
    love.graphics.newQuad(textSourceX, textSourceY, textSourceWidth, textSourceHeight,
      spritesheet:getDimensions()),
    textTargetX, textTargetY)
  
  -- Restart button
  love.graphics.draw(spritesheet,
    love.graphics.newQuad(self.restartImgPos.x, self.restartImgPos.y,
      restartSourceWidth, restartSourceHeight,
      spritesheet:getDimensions()),
    restartTargetX, restartTargetY)
end

------------------------------------------------------------
-- Horizon
------------------------------------------------------------
local Horizon = {}
Horizon.__index = Horizon

Horizon.config = {
  BG_CLOUD_SPEED = 0.2,
  BUMPY_THRESHOLD = 0.3,
  CLOUD_FREQUENCY = 0.5,
  HORIZON_HEIGHT = 16,
  MAX_CLOUDS = 6
}

function Horizon:new(canvas, spritePos, dimensions, gapCoefficient)
  local self = setmetatable({}, Horizon)
  self.canvas = canvas
  self.dimensions = dimensions
  self.gapCoefficient = gapCoefficient
  self.obstacles = {}
  self.obstacleHistory = {}
  self.horizonOffsets = {0, 0}
  self.cloudFrequency = Horizon.config.CLOUD_FREQUENCY
  self.spritePos = spritePos
  self.nightMode = nil
  self.clouds = {}
  self.cloudSpeed = Horizon.config.BG_CLOUD_SPEED
  self.horizonLine = nil
  self:init()
  return self
end

function Horizon:init()
  self:addCloud()
  self.horizonLine = HorizonLine:new(self.canvas, self.spritePos.HORIZON)
  self.nightMode = NightMode:new(self.canvas, self.spritePos.MOON, self.dimensions.WIDTH)
end

function Horizon:update(deltaTime, currentSpeed, updateObstacles, showNightMode)
  self.horizonLine:update(deltaTime, currentSpeed)
  self.nightMode:update(showNightMode, deltaTime)
  self:updateClouds(deltaTime, currentSpeed)
  
  if updateObstacles then
    self:updateObstacles(deltaTime, currentSpeed)
  end
end

function Horizon:updateClouds(deltaTime, speed)
  local cloudSpeed = self.cloudSpeed / 1000 * deltaTime * speed
  local numClouds = #self.clouds
  
  if numClouds > 0 then
    for i = numClouds, 1, -1 do
      self.clouds[i]:update(cloudSpeed)
    end
    
    local lastCloud = self.clouds[numClouds]
    
    -- Check for adding a new cloud
    if numClouds < Horizon.config.MAX_CLOUDS and
      (self.dimensions.WIDTH - lastCloud.xPos) > lastCloud.cloudGap and
      self.cloudFrequency > love.math.random() then
      self:addCloud()
    end
    
    -- Remove expired clouds
    local newClouds = {}
    for i, cloud in ipairs(self.clouds) do
      if not cloud.remove then
        table.insert(newClouds, cloud)
      end
    end
    self.clouds = newClouds
  else
    self:addCloud()
  end
end

function Horizon:updateObstacles(deltaTime, currentSpeed)
  -- Update existing obstacles
  local updatedObstacles = {}
  for i, obstacle in ipairs(self.obstacles) do
    obstacle:update(deltaTime, currentSpeed)
    if not obstacle.remove then
      table.insert(updatedObstacles, obstacle)
    end
  end
  self.obstacles = updatedObstacles
  
  if #self.obstacles > 0 then
    local lastObstacle = self.obstacles[#self.obstacles]
    
    if lastObstacle and not lastObstacle.followingObstacleCreated and
      lastObstacle:isVisible() and
      (lastObstacle.xPos + lastObstacle.width + lastObstacle.gap) < self.dimensions.WIDTH then
      self:addNewObstacle(currentSpeed)
      lastObstacle.followingObstacleCreated = true
    end
  else
    -- Create new obstacles
    self:addNewObstacle(currentSpeed)
  end
end

function Horizon:addNewObstacle(currentSpeed)
  local obstacleTypeIndex = getRandomNum(1, #ObstacleTypes)
  local obstacleType = ObstacleTypes[obstacleTypeIndex]
  
  -- Check for multiples of the same type of obstacle
  if self:duplicateObstacleCheck(obstacleType.type) or currentSpeed < obstacleType.minSpeed then
    self:addNewObstacle(currentSpeed)
  else
    local obstacleSpritePos = self.spritePos[obstacleType.type]
    
    table.insert(self.obstacles, Obstacle:new(self.canvas, obstacleType,
      obstacleSpritePos, self.dimensions, self.gapCoefficient, currentSpeed, obstacleType.width))
    
    table.insert(self.obstacleHistory, 1, obstacleType.type)
    
    if #self.obstacleHistory > 1 then
      -- Trim to MAX_OBSTACLE_DUPLICATION
      while #self.obstacleHistory > CONFIG.MAX_OBSTACLE_DUPLICATION do
        table.remove(self.obstacleHistory, #self.obstacleHistory)
      end
    end
  end
end

function Horizon:duplicateObstacleCheck(nextObstacleType)
  local duplicateCount = 0
  
  for i = 1, #self.obstacleHistory do
    if self.obstacleHistory[i] == nextObstacleType then
      duplicateCount = duplicateCount + 1
    else
      duplicateCount = 0
    end
  end
  
  return duplicateCount >= CONFIG.MAX_OBSTACLE_DUPLICATION
end

function Horizon:reset()
  self.obstacles = {}
  self.horizonLine:reset()
  self.nightMode:reset()
end

function Horizon:addCloud()
  table.insert(self.clouds, Cloud:new(self.canvas, self.spritePos.CLOUD, self.dimensions.WIDTH))
end

function Horizon:draw()
  -- Draw clouds
  for _, cloud in ipairs(self.clouds) do
    cloud:draw()
  end
  
  -- Draw night mode
  self.nightMode:draw()
  
  -- Draw horizon line
  self.horizonLine:draw()
  
  -- Draw obstacles
  for _, obstacle in ipairs(self.obstacles) do
    obstacle:draw()
  end
end

------------------------------------------------------------
-- Runner (Main Game Controller)
------------------------------------------------------------
local Runner = {}
Runner.__index = Runner

function Runner:new(outerContainerId, opt_config)
  if Runner.instance then
    return Runner.instance
  end
  
  Runner.instance = self
  local self = setmetatable({}, Runner)
  
  self.config = {
    ACCELERATION = CONFIG.ACCELERATION,
    BG_CLOUD_SPEED = CONFIG.BG_CLOUD_SPEED,
    BOTTOM_PAD = CONFIG.BOTTOM_PAD,
    CLEAR_TIME = CONFIG.CLEAR_TIME,
    CLOUD_FREQUENCY = CONFIG.CLOUD_FREQUENCY,
    GAMEOVER_CLEAR_TIME = CONFIG.GAMEOVER_CLEAR_TIME,
    GAP_COEFFICIENT = CONFIG.GAP_COEFFICIENT,
    GRAVITY = CONFIG.GRAVITY,
    INITIAL_JUMP_VELOCITY = CONFIG.INITIAL_JUMP_VELOCITY,
    INVERT_FADE_DURATION = CONFIG.INVERT_FADE_DURATION,
    INVERT_DISTANCE = CONFIG.INVERT_DISTANCE,
    MAX_BLINK_COUNT = CONFIG.MAX_BLINK_COUNT,
    MAX_CLOUDS = CONFIG.MAX_CLOUDS,
    MAX_OBSTACLE_LENGTH = CONFIG.MAX_OBSTACLE_LENGTH,
    MAX_OBSTACLE_DUPLICATION = CONFIG.MAX_OBSTACLE_DUPLICATION,
    MAX_SPEED = CONFIG.MAX_SPEED,
    MIN_JUMP_HEIGHT = CONFIG.MIN_JUMP_HEIGHT,
    MOBILE_SPEED_COEFFICIENT = CONFIG.MOBILE_SPEED_COEFFICIENT,
    SPEED = CONFIG.SPEED,
    SPEED_DROP_COEFFICIENT = CONFIG.SPEED_DROP_COEFFICIENT,
  }
  
  self.dimensions = {WIDTH = CONFIG.WIDTH, HEIGHT = CONFIG.HEIGHT}
  self.canvas = nil
  self.tRex = nil
  self.distanceMeter = nil
  self.distanceRan = 0
  self.highestScore = 0
  self.time = 0
  self.runningTime = 0
  self.msPerFrame = 1000 / CONFIG.FPS
  self.currentSpeed = self.config.SPEED
  self.obstacles = {}
  self.activated = false
  self.playing = false
  self.crashed = false
  self.paused = false
  self.inverted = false
  self.invertTimer = 0
  self.playCount = 0
  self.soundFx = {}
  self.gameOverPanel = nil
  self.updatePending = false
  self.raqId = 0
  self.playingIntro = false
  
  self:loadImages()
  self:init()
  
  return self
end

function Runner:loadImages()
  -- Spritesheet is already loaded globally
end

function Runner:init()
  -- Create canvas (we'll use the main LÖVE2D canvas)
  self.canvas = {
    width = self.dimensions.WIDTH,
    height = self.dimensions.HEIGHT
  }
  
  -- Horizon contains clouds, obstacles and the ground
  self.horizon = Horizon:new(self.canvas, {
    CLOUD = SPRITES.CLOUD,
    HORIZON = SPRITES.HORIZON,
    MOON = SPRITES.MOON,
    CACTUS_SMALL = SPRITES.CACTUS_SMALL,
    CACTUS_LARGE = SPRITES.CACTUS_LARGE,
    PTERODACTYL = SPRITES.PTERODACTYL
  }, self.dimensions, self.config.GAP_COEFFICIENT)
  
  -- Distance meter
  self.distanceMeter = DistanceMeter:new(self.canvas, SPRITES.TEXT_SPRITE, self.dimensions.WIDTH)
  
  -- Draw t-rex
  self.tRex = Trex:new(self.canvas, SPRITES.TREX)
  
  self:startListening()
  self:update()
end

function Runner:setSpeed(opt_speed)
  local speed = opt_speed or self.currentSpeed
  
  if self.dimensions.WIDTH < CONFIG.WIDTH then
    local mobileSpeed = speed * self.dimensions.WIDTH / CONFIG.WIDTH * self.config.MOBILE_SPEED_COEFFICIENT
    self.currentSpeed = mobileSpeed > speed and speed or mobileSpeed
  elseif opt_speed then
    self.currentSpeed = opt_speed
  end
end

function Runner:playIntro()
  if not self.activated and not self.crashed then
    self.playingIntro = true
    self.tRex.playingIntro = true
    self.playing = true
    self.activated = true
  elseif self.crashed then
    self:restart()
  end
end

function Runner:startGame()
  self.runningTime = 0
  self.playingIntro = false
  self.tRex.playingIntro = false
  self.playCount = self.playCount + 1
end

function Runner:update(opt_deltaTime)
  self.updatePending = false
  
  local now = getTimeStamp()
  local deltaTime = opt_deltaTime or (now - (self.time ~= 0 and self.time or now))
  self.time = now
  
  if self.playing then
    if self.tRex.jumping then
      self.tRex:updateJump(deltaTime, self.currentSpeed)
    end
    
    self.runningTime = self.runningTime + deltaTime
    local hasObstacles = self.runningTime > self.config.CLEAR_TIME
    
    -- First jump triggers the intro
    if self.tRex.jumpCount == 1 and not self.playingIntro then
      self:playIntro()
    end
    
    -- The horizon doesn't move until the intro is over
    if self.playingIntro then
      self.horizon:update(0, self.currentSpeed, hasObstacles, self.inverted)
    else
      deltaTime = not self.activated and 0 or deltaTime
      self.horizon:update(deltaTime, self.currentSpeed, hasObstacles, self.inverted)
    end
    
    -- Check for collisions
    local collision = hasObstacles and #self.horizon.obstacles > 0 and
      checkForCollision(self.horizon.obstacles[1], self.tRex)
    
    if not collision then
      self.distanceRan = self.distanceRan + self.currentSpeed * deltaTime / self.msPerFrame
      
      if self.currentSpeed < self.config.MAX_SPEED then
        self.currentSpeed = self.currentSpeed + self.config.ACCELERATION
      end
    else
      self:gameOver()
    end
    
    local playAchievementSound = self.distanceMeter:update(deltaTime, math.ceil(self.distanceRan))
    
    -- Night mode
    if self.invertTimer > self.config.INVERT_FADE_DURATION then
      self.invertTimer = 0
      self.invertTrigger = false
      self:invert()
    elseif self.invertTimer > 0 then
      self.invertTimer = self.invertTimer + deltaTime
    else
      local actualDistance = self.distanceMeter:getActualDistance(math.ceil(self.distanceRan))
      
      if actualDistance > 0 then
        self.invertTrigger = not (actualDistance % self.config.INVERT_DISTANCE ~= 0)
        
        if self.invertTrigger and self.invertTimer == 0 then
          self.invertTimer = self.invertTimer + deltaTime
          self:invert()
        end
      end
    end
  end
  
  if self.playing or (not self.activated and self.tRex.blinkCount < self.config.MAX_BLINK_COUNT) then
    self.tRex:update(deltaTime)
    self:scheduleNextUpdate()
  end
end

function Runner:gameOver()
  self:stop()
  self.crashed = true
  self.distanceMeter.acheivement = false
  
  self.tRex:update(100, Trex.status.CRASHED)
  
  -- Game over panel
  if not self.gameOverPanel then
    self.gameOverPanel = GameOverPanel:new(self.canvas, SPRITES.TEXT_SPRITE, SPRITES.RESTART, self.dimensions)
  end
  
  -- Update the high score
  if self.distanceRan > self.highestScore then
    self.highestScore = math.ceil(self.distanceRan)
    self.distanceMeter:setHighScore(self.highestScore)
  end
  
  -- Reset the time clock
  self.time = getTimeStamp()
end

function Runner:stop()
  self.playing = false
  self.paused = true
  self.raqId = 0
end

function Runner:play()
  if not self.crashed then
    self.playing = true
    self.paused = false
    self.tRex:update(0, Trex.status.RUNNING)
    self.time = getTimeStamp()
    self:update()
  end
end

function Runner:restart()
  self.playCount = self.playCount + 1
  self.runningTime = 0
  self.playing = true
  self.crashed = false
  self.distanceRan = 0
  self:setSpeed(self.config.SPEED)
  self.time = getTimeStamp()
  self.distanceMeter:reset(self.highestScore)
  self.horizon:reset()
  self.tRex:reset()
  self:invert(true)
  self:update()
end

function Runner:invert(reset)
  if reset then
    self.invertTimer = 0
    self.inverted = false
  else
    self.inverted = not self.inverted
  end
end

function Runner:onKeyDown(key)
  if not self.crashed and (key == "up" or key == "space") then
    if not self.playing then
      self.playing = true
      self:update()
    end
    -- Play sound effect and jump on starting the game for the first time
    if not self.tRex.jumping and not self.tRex.ducking then
      self.tRex:startJump(self.currentSpeed)
    end
  end
  
  if self.playing and not self.crashed and key == "down" then
    if self.tRex.jumping then
      -- Speed drop, activated only when jump key is not pressed
      self.tRex:setSpeedDrop()
    elseif not self.tRex.jumping and not self.tRex.ducking then
      -- Duck
      self.tRex:setDuck(true)
    end
  end
  
  if self.crashed and key == "r" then
    self:restart()
  end
end

function Runner:onKeyUp(key)
  local isJumpKey = key == "up" or key == "space"
  
  if self:isRunning() and isJumpKey then
    self.tRex:endJump()
  elseif key == "down" then
    self.tRex.speedDrop = false
    self.tRex:setDuck(false)
  elseif self.crashed then
    -- Check that enough time has elapsed before allowing jump key to restart
    local deltaTime = getTimeStamp() - self.time
    
    if key == "return" or (deltaTime >= self.config.GAMEOVER_CLEAR_TIME and isJumpKey) then
      self:restart()
    end
  elseif self.paused and isJumpKey then
    -- Reset the jump state
    self.tRex:reset()
    self:play()
  end
end

function Runner:scheduleNextUpdate()
  -- In LÖVE2D, we use the main update loop instead of requestAnimationFrame
  self.updatePending = false
end

function Runner:isRunning()
  return self.playing
end

function Runner:startListening()
  -- Key handling is done through dinoApp:keypressed and dinoApp:keyreleased
end

function Runner:draw()
  -- Clear canvas
  love.graphics.setColor(0.97, 0.97, 0.97)
  love.graphics.rectangle("fill", 0, 0, self.dimensions.WIDTH, self.dimensions.HEIGHT)
  love.graphics.setColor(1, 1, 1)
  
  -- Draw horizon (includes clouds, night mode, ground, obstacles)
  self.horizon:draw()
  
  -- Draw distance meter
  self.distanceMeter:draw()
  
  -- Draw trex
  self.tRex:draw()
  
  -- Draw game over panel
  if self.crashed and self.gameOverPanel then
    self.gameOverPanel:draw()
  end
  
  -- Draw start message
  if not self.activated and not self.crashed then
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.print("Press Space to Start", self.dimensions.WIDTH / 2 - 70, 
      self.dimensions.HEIGHT / 2 - 10)
    love.graphics.setColor(1, 1, 1)
  end
end

------------------------------------------------------------
-- dinoApp Module Methods
------------------------------------------------------------
function dinoApp.new()
  local self = setmetatable({}, dinoApp)
  
  -- Load spritesheet
  spritesheet = love.graphics.newImage("assets/100-offline-sprite.png")
  
  -- Initialize runner
  self.runner = Runner:new('.interstitial-wrapper')
  
  return self
end

function dinoApp:update(dt)
  self.runner:update(dt * 1000)
end

function dinoApp:draw(offsetX, offsetY, width, height)
  -- Draw background
  love.graphics.setColor(0.1, 0.1, 0.1)
  love.graphics.rectangle("fill", offsetX, offsetY, width, height)
  
  love.graphics.push()
  love.graphics.translate(offsetX, offsetY)
  
  -- Scale to fit the window while maintaining aspect ratio
  local scaleX = width / CONFIG.WIDTH
  local scaleY = height / CONFIG.HEIGHT
  local scale = math.min(scaleX, scaleY)
  
  love.graphics.scale(scale, scale)
  
  -- Center the game in the available space
  local scaledWidth = CONFIG.WIDTH * scale
  local scaledHeight = CONFIG.HEIGHT * scale
  local translateX = (width - scaledWidth) / (2 * scale)
  local translateY = (height - scaledHeight) / (2 * scale)
  
  love.graphics.translate(translateX, translateY)
  
  -- Set scissor to prevent drawing outside the window
  local prevScissor = { love.graphics.getScissor() }
  love.graphics.setScissor(offsetX, offsetY, width, height)
  
  self.runner:draw()
  
  love.graphics.setScissor(unpack(prevScissor))
  love.graphics.pop()
end

function dinoApp:keypressed(key)
  self.runner:onKeyDown(key)
end

function dinoApp:keyreleased(key)
  self.runner:onKeyUp(key)
end

function dinoApp:mousepressed(x, y, button)
  if button == 1 then
    self.runner:onKeyDown("space")
  end
end

function dinoApp:mousereleased(x, y, button)
  if button == 1 then
    self.runner:onKeyUp("space")
  end
end

return dinoApp