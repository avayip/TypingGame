--[[
Authors: Shing Yip, Ava Yip, Natalie Yip
]]

Target = require("Target")

local scene = {
  targets = {},
  score = 0,
  dictionary = {},
  levels = {
    { name = "Level 1", 
      themeMusic = love.audio.newSource("sound/Spiritual_Moments.mp3"),
      background = love.graphics.newImage("graphics/background_1.jpg"),
      wordCount = {min=3, max=5}, 
      speed = {min=1, max=5}, 
      dropInterval = 3,
      levelUpTarget = 5 
    },  
    { name = "Level 2", 
      themeMusic = love.audio.newSource("sound/mvrasseli_play_the_game_0.mp3"),
      background = love.graphics.newImage("graphics/background_1.jpg"),
      wordCount = {min=5, max=7}, 
      speed = {min=3, max=8}, 
      dropInterval = 2,
      levelUpTarget = 12
    },  
    { name = "Level 4", 
      themeMusic = love.audio.newSource("sound/epic_loop.mp3"),
      background = love.graphics.newImage("graphics/background_1.jpg"),
      wordCount = {min=7, max=14}, 
      speed = {min=5, max=12}, 
      dropInterval = 1,
      levelUpTarget = 20 
    },
    { name = "Level 5", 
      themeMusic = love.audio.newSource("sound/Preliminary_Music.mp3"),
      background = love.graphics.newImage("graphics/background_1.jpg"),
      wordCount = {min=10, max=20}, 
      speed = {min=7, max=14}, 
      dropInterval = 0.5,
      levelUpTarget = 35 
    },
    { name = "Level 6", 
      themeMusic = love.audio.newSource("sound/Spiritual_Moments.mp3"),
      background = love.graphics.newImage("graphics/background_1.jpg"),
      wordCount = {min=10, max=30}, 
      speed = {min=10, max=16}, 
      dropInterval = 0.5,
      levelUpTarget = 40 
    },
    { name = "Level Hell", 
      themeMusic = love.audio.newSource("sound/Spiritual_Moments.mp3"),
      background = love.graphics.newImage("graphics/background_1.jpg"),
      wordCount = {min=10, max=35}, 
      speed = {min=5, max=20}, 
      dropInterval = 0.5,
      levelUpTarget = -1 
    },
  },
  level = nil,
  nextDrop = 1,
  fonts = {},
  defaultFont = love.graphics.newFont(20),
  targetColors = {
    {0,0,0,255},
    {30,20,20,255},
    {30,50,50,255},
  },
  targetHitColors = {
    {255,255,0,255},
    {255,0,0,255},
  },
  world = love.physics.newWorld(0, 10, true),
  ground = {},
  leftWall = {},
  rightWall = {},
  audio = {
    hit = love.audio.newSource("sound/whistle.wav", "static"),
    levelUp = love.audio.newSource("sound/magical_1_0.ogg", "static"),
  },

  levelIdx = 1,
  score = 0
}

function scene:load()
  self:loadDictionary("dictionary.txt")

  self.fonts = {
    --love.graphics.newFont("fonts/armybeans.ttf", 60),
    love.graphics.newFont("fonts/charlie_dotted.ttf", 40),    
    love.graphics.newFont("fonts/EasterBunny.ttf", 40),    
    love.graphics.newFont("fonts/NORMAL.otf", 25),
    love.graphics.newFont("fonts/melting.ttf", 40),
    love.graphics.newFont("fonts/orange_juice.ttf", 40)
  }
  
  self.world:setCallbacks(self.onColision, nil, nil, nil)

  self:setLevel(1)
  self:addTarget()

  local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()

  self.ground.body = love.physics.newBody(self.world, screenWidth/2, screenHeight-20)
  self.ground.shape = love.physics.newRectangleShape(screenWidth, 40)
  self.ground.fixture = love.physics.newFixture(self.ground.body, self.ground.shape)
  self.ground.fixture:setUserData("[[ground]]")

  self.leftWall.body = love.physics.newBody(self.world, 1, screenHeight/2)
  self.leftWall.shape = love.physics.newRectangleShape(2, screenHeight)
  self.leftWall.fixture = love.physics.newFixture(self.leftWall.body, self.leftWall.shape)

  self.rightWall.body = love.physics.newBody(self.world, screenWidth - 1, screenHeight/2)
  self.rightWall.shape = love.physics.newRectangleShape(2, screenHeight)
  self.rightWall.fixture = love.physics.newFixture(self.rightWall.body, self.rightWall.shape)
end

function scene:update(dt, input)
  self.world:update(dt)

  if self.gameOver then
    for index, target in ipairs(self.targets) do
      target:update(dt, input)
    end
    return
  end
  
  if #self.targets < self.level.wordCount.min then
    self:addTarget()
  end

  if self.nextDrop > 0.1 then 
    self.nextDrop = self.nextDrop - dt
  end
  
  if #self.targets < self.level.wordCount.max and self.nextDrop <= 0.1 then
    self:addTarget()
    self.nextDrop = self.level.dropInterval
  end

  local disappearedTargets = {}
  for index, target in ipairs(self.targets) do
    target:update(dt, input)
    
    -- check if target is out of screen and destroy it
    if target.body:getY() < -50 then
      target:destroy()  
      -- insert index to end of disappearedTargets, note that index is in accending order
      table.insert(disappearedTargets, index)
    elseif target.fuseBurn > (target.fuseLength + 3) then
      self:onGameOver()
      return
    end
  end
  
  -- remove targets from self.targets in reverse order
  for index = #disappearedTargets, 1, -1 do
    table.remove(self.targets, disappearedTargets[index])
  end

  if self.score > self.level.levelUpTarget and self.level.levelUpTarget > 0 then
    self:setLevel(self.levelIdx + 1)
    self:onLevelUp()
  end
end

function scene:setLevel(newLevel)
  if newLevel > #self.levels then
    error("cannot set level "..newLevel)
  end
  
  if self.level and self.level.themeMusic then
    self.level.themeMusic:stop()
  end
  self.levelIdx = newLevel
  self.level = self.levels[self.levelIdx]
  if self.level.themeMusic then
    self.level.themeMusic:setLooping(true)
    self.level.themeMusic:play()
  end
end

function scene:onScored(target)
  self.score = self.score + 1
end

function scene:onLevelUp()
  self.level.themeMusic:stop()
  self.audio.levelUp:play()
end

function scene:loadDictionary(filename)
  local dictionaryFile = io.open(filename)
  if dictionaryFile then
    for line in dictionaryFile:lines() do
      local word = line:gsub("%s+", "")
      if word and word ~= "" then
        table.insert(self.dictionary, {spell = word:lower(), hitCount = 1})
      end
    end
  end
end

function scene:addTarget()
  local words = {
    self.dictionary[math.random(#self.dictionary)],    
    self.dictionary[math.random(#self.dictionary)],
    self.dictionary[math.random(#self.dictionary)],
  }
  table.sort(words, function(w1, w2) return w1.hitCount < w2.hitCount end)
  local target = Target:new(self, words[1])
  table.insert(scene.targets, target)
end

function scene:draw()
  local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
  local bg = self.level.background
  if bg then
    love.graphics.draw(bg, 0, 0, 0, screenWidth/bg:getWidth(), screenHeight/bg:getHeight())
  else
    love.graphics.setBackgroundColor(155, 183, 242)
  end
  
  for _, target in ipairs(self.targets) do
    target:draw()
  end

  -- draw the ground 
  --love.graphics.setColor(72, 160, 14)
  --love.graphics.polygon("fill", self.ground.body:getWorldPoints(self.ground.shape:getPoints()))

  -- draw the walls
  --love.graphics.polygon("fill", self.leftWall.body:getWorldPoints(self.leftWall.shape:getPoints()))
  --love.graphics.polygon("fill", self.rightWall.body:getWorldPoints(self.rightWall.shape:getPoints()))
 
  -- use default front for other text
  love.graphics.setFont(self.defaultFont)
  -- draw the input
  love.graphics.setColor(255, 255, 255)

  -- draw the level name and socore
  love.graphics.setColor(250, 108, 7)
  love.graphics.printf(self.level.name, screenWidth - 120, screenHeight - 40, 100, "right")
  love.graphics.printf("Score:"..self.score, screenWidth - 120, screenHeight - 20, 100, "right")
  
  if self.gameOver then
    self.gameOver:draw()
  end
  -- for debugging : draw all shapes
  --[[
  love.graphics.setColor(255, 255, 255)
  self.world:queryBoundingBox(0, 0, screenWidth, screenHeight, 
    function(fixture) 
      love.graphics.polygon("line", fixture:getBody():getWorldPoints(fixture:getShape():getPoints()))
    end
  )
  ]]
end

function scene:onGameOver()
  local music = love.audio.newSource("sound/Target_position.mp3")
  
  self.level.themeMusic:stop()
  music:play()
  
  local target = Target:new(
    self, 
    {spell = "GAME OVER", hitCount = 0}, 
    love.graphics.newFont(60),
    love.physics.newBody(self.world, love.graphics.getWidth()/2, 30, "dynamic"))

  target.flashingFreq = 0
  self.gameOver = target
end

function scene.onColision(a, b, contact)
  local target
  if a:getUserData() == "[[ground]]" then
    target = b:getUserData()
  elseif b:getUserData() == "[[ground]]" then
    target = a:getUserData()
  end
  if target then
    target:onHitGround()
  end
end


return scene