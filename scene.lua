--[[
Authors: Shing Yip, Ava Yip, Natalie Yip
]]

Target = require("Target")

--[[
scene table defines game scene
]]
local scene = {
  targets = {},
  score = 0,
  dictionary = {},
  levels = {
    { name = "Level 1",
      themeMusic = audio.newSource("sound/Spiritual_Moments.mp3"),
      background = gfx.newImage("graphics/background_1.jpg"),
      wordCount = {min=1, max=3},
      speed = {min=1, max=5},
      dropInterval = 3,
      levelUpTarget = 5,
	  maxFrame = 5
    },
    { name = "Level 2",
      themeMusic = audio.newSource("sound/mvrasseli_play_the_game_0.mp3"),
      background = gfx.newImage("graphics/background_1.jpg"),
      wordCount = {min=2, max=5},
      speed = {min=3, max=8},
      dropInterval = 2,
      levelUpTarget = 12
    },
    { name = "Level 3",
      themeMusic = audio.newSource("sound/epic_loop.mp3"),
      background = gfx.newImage("graphics/background_1.jpg"),
      wordCount = {min=3, max=10},
      speed = {min=5, max=12},
      dropInterval = 1,
      levelUpTarget = 20,
	  maxFrame = 5
    },
    { name = "Level 4",
      themeMusic = audio.newSource("sound/Preliminary_Music.mp3"),
      background = gfx.newImage("graphics/background_1.jpg"),
      wordCount = {min=4, max=15},
      speed = {min=7, max=14},
      dropInterval = 0.5,
      levelUpTarget = 35,
	  maxFrame = 5
    },
    { name = "Level 5",
      themeMusic = audio.newSource("sound/Spiritual_Moments.mp3"),
      background = gfx.newImage("graphics/background_1.jpg"),
      wordCount = {min=5, max=20},
      speed = {min=10, max=16},
      dropInterval = 0.5,
      levelUpTarget = 40,
	  maxFrame = 5
    },
    { name = "Level 6",
      themeMusic = audio.newSource("sound/Spiritual_Moments.mp3"),
      background = gfx.newImage("graphics/background_1.jpg"),
      wordCount = {min=10, max=35},
      speed = {min=5, max=20},
      dropInterval = 0.5,
      levelUpTarget = -1,
	  maxFrame = 5
    },
  },
  level = nil,
  nextDrop = 1,
  fonts = {},
  defaultFont = gfx.newFont(20*scaleFactor),
  targetColors = {
    {0,0,0,255},
    {159,54,251,255},
    {254,12,175,255},
    {12,30,255,255},
  },
  targetHitColors = {
    {255,255,0,255},
    {255,0,0,255},
  },
  world = phys.newWorld(0, scaleFactor*10, true),
  ground = {},
  leftWall = {},
  rightWall = {},
  audio = {
    hit = audio.newSource("sound/whistle.wav", "static"),
    levelUp = audio.newSource("sound/magical_1_0.ogg", "static"),
  },

  levelIdx = 1,
  score = 0
}

function scene:load()
  self:loadDictionary("dictionary.txt")

  local screenWidth, screenHeight = gfx.getWidth(), gfx.getHeight()

  self.fonts = {
    gfx.newFont("fonts/armybeans.ttf", 35*scaleFactor),
    gfx.newFont("fonts/charlie_dotted.ttf", 40*scaleFactor),
    gfx.newFont("fonts/EasterBunny.ttf", 30*scaleFactor),
    gfx.newFont("fonts/NORMAL.otf", 16*scaleFactor),
    gfx.newFont("fonts/melting.ttf", 23*scaleFactor),
    gfx.newFont("fonts/orange_juice.ttf", 30*scaleFactor)
  }

  self.world:setCallbacks(self.onColision, nil, nil, nil)

  self:setLevel(1)
  self:addTarget()

  self.ground.body = phys.newBody(self.world, screenWidth/2, screenHeight-20*scaleFactor)
  self.ground.shape = phys.newRectangleShape(screenWidth, 40*scaleFactor)
  self.ground.fixture = phys.newFixture(self.ground.body, self.ground.shape)
  self.ground.fixture:setUserData("[[ground]]")

  self.leftWall.body = phys.newBody(self.world, 1, screenHeight/2)
  self.leftWall.shape = phys.newRectangleShape(2, screenHeight)
  self.leftWall.fixture = phys.newFixture(self.leftWall.body, self.leftWall.shape)

  self.rightWall.body = phys.newBody(self.world, screenWidth - 1, screenHeight/2)
  self.rightWall.shape = phys.newRectangleShape(2, screenHeight)
  self.rightWall.fixture = phys.newFixture(self.rightWall.body, self.rightWall.shape)
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
    target:update(dt)

    -- check if target is out of screen and destroy it
    if target.body:getY() < -50 then
      target:destroy()
      -- insert index to end of disappearedTargets, note that index is in accending order
      table.insert(disappearedTargets, index)
    elseif target.frame == self.level.maxFrame then
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
  self.level.themeMusic:pause()
  self.audio.levelUp:play()
  self.level.themeMusic:play()
end

function scene:loadDictionary(filename)
  logInfo("loading dictionary from %s", filename)
  if love.filesystem.exists(filename) then
    for line in love.filesystem.lines(filename) do
      local word = line:gsub("%s+", "")
      if word and word ~= "" then
        table.insert(self.dictionary, {spell = word:lower(), hitCount = 1})
      end
    end
  else
  	error("open dictionary file failed")
  end
  logInfo("%d words loaded", #self.dictionary)
end

function scene:addTarget()
  local words = {
    self.dictionary[math.random(#self.dictionary)],
    self.dictionary[math.random(#self.dictionary)],
    self.dictionary[math.random(#self.dictionary)],
  }
  table.sort(words, function(w1, w2) return w1.hitCount < w2.hitCount end)
  local target = Target:new(words[1])
  table.insert(scene.targets, target)
end

function scene:draw()
  local screenWidth, screenHeight = gfx.getWidth(), gfx.getHeight()

  local bg = self.level.background
  if bg then
    gfx.draw(bg, 0, 0, 0, screenWidth/bg:getWidth(), screenHeight/bg:getHeight())
  else
    gfx.setBackgroundColor(5, 252, 219, 128)
  end

  for _, target in ipairs(self.targets) do
    target:draw()
  end

  -- draw the ground
  --gfx.setColor(72, 160, 14)
  --gfx.polygon("fill", self.ground.body:getWorldPoints(self.ground.shape:getPoints()))

  -- draw the walls
  --gfx.polygon("fill", self.leftWall.body:getWorldPoints(self.leftWall.shape:getPoints()))
  --gfx.polygon("fill", self.rightWall.body:getWorldPoints(self.rightWall.shape:getPoints()))

  -- use default front for other text
  gfx.setFont(self.defaultFont)

  -- draw the level name and socore
  gfx.setFont(scene.defaultFont)
  gfx.setColor(250, 108, 7)
  gfx.printf(self.level.name, screenWidth - 120*scaleFactor, screenHeight - 40*scaleFactor, 100*scaleFactor, "right", 0)
  gfx.printf("Score:"..self.score, screenWidth - 120*scaleFactor, screenHeight - 20*scaleFactor, 100*scaleFactor, "right", 0)

  if self.gameOver then
    self.gameOver:draw()
  end
  -- for debugging : draw all shapes
  --[[
  gfx.setColor(255, 255, 255)
  self.world:queryBoundingBox(0, 0, screenWidth, screenHeight,
    function(fixture)
      gfx.polygon("line", fixture:getBody():getWorldPoints(fixture:getShape():getPoints()))
    end
  )
  ]]
end

function scene:onGameOver()
  local music = audio.newSource("sound/Target_position.mp3")

  self.level.themeMusic:stop()
  music:play()

  local body = phys.newBody(self.world, gfx.getWidth()/2, 30, "dynamic")
  body:setMass(200)
  local target = Target:new(
    {spell = "GAME OVER", hitCount = 0},
    gfx.newFont(80*scaleFactor),
    body)

  target.flashingDuration = 0
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
