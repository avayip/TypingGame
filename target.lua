--[[
Authors: Shing Yip, Ava Yip, Natalie Yip
]]

local fireImg = gfx.newImage("graphics/circle.png")
local Target = {}

function Target:new(targetScene, word, font, body)
  local windowWidth = gfx.getWidth()
  font = font or targetScene.fonts[math.random(1, #targetScene.fonts)]
  local target = {
    font = font,
    word = word,
    textWidth = font:getWidth(word.spell),
    textHeight = font:getHeight(word.spell),
    color = targetScene.targetColors[math.random(1, #targetScene.targetColors)],
    speed = math.random(targetScene.level.speed.min, targetScene.level.speed.max),
    partialHitLength = 0,
    hitCount = 0,
    flashingColor = {255,255,0,128},
    flashingFreq = 0.0,
    flashingTimer = 0.0,
    flashingDuration = 0.0,
    flashingDurationTimer = 0.0,
    frame = 0,
    hitGround = false,
    fuseLength = 10,
    fuseBurn = 0,
  }

  target.body = body or phys.newBody(targetScene.world, math.random(10, windowWidth - 10), 10, "dynamic")
  target.body:setMass(10)
  target.shape = phys.newRectangleShape(target.textWidth, target.textHeight)
  target.fixture = phys.newFixture(target.body, target.shape, 1)
  target.fixture:setRestitution(0.5)
  target.fixture:setUserData(target)

  local ps = gfx.newParticleSystem(fireImg, 32)
  ps:setColors({255, 128, 32, 255}, {222, 128, 32, 255}, {128, 32, 32, 32}, {90, 12, 12, 92}, {32, 32, 32, 0})
  ps:setDirection(math.rad(90))
  ps:setEmissionRate(500)
  ps:setEmitterLifetime(-1)
  ps:setInsertMode("bottom")
  ps:setLinearAcceleration(0, 0, 0, -100)
  ps:setParticleLifetime(1, 3)
  ps:setRadialAcceleration(0, 0)
  ps:setRotation(0, math.rad(360))
  ps:setSizeVariation(0)
  ps:setSizes(1, 1, 1, 1, 0.75, 0.5, 0.25)
  ps:setSpeed(0, 50)
  ps:setSpin(math.rad(0), math.rad(360))
  ps:setSpinVariation(1)
  ps:setSpread(math.rad(360))
  ps:setTangentialAcceleration(0, 0)

  target.particleSystem = ps

  setmetatable(target, self)
  self.__index = self
  return target
end

function Target:destroy()
  self.fixture:setUserData(nil)
  self.body:destroy()
  self.body = nil
  self.shape = nil
  self.fixture = nil
end

function Target:draw()
  local screenWidth, screenHeight = gfx.getWidth(), gfx.getHeight()
  local x, y = self.body:getWorldPoint(-self.textWidth/2, -self.textHeight/2)
  local frameScale = self.textWidth/70
  logInfo("%s at %f,%f frameScale=%f", self.word.spell, x, y, frameScale)
  
  if self.frame >= 5 then
    local xx, yy = self.body:getWorldPoint(-self.textWidth/4,-self.textHeight/2)
    gfx.draw(self.particleSystem, xx, yy , 0, frameScale, frameScale)
  end
  if self.frame >= 4 then
    local xx, yy = self.body:getWorldPoint(self.textWidth/4,-self.textHeight/2)
    gfx.draw(self.particleSystem, xx, yy , 0, frameScale, frameScale)
  end
  if self.frame >= 3 then
    local xx, yy = self.body:getWorldPoint(-self.textWidth/2,-self.textHeight/2)
    gfx.draw(self.particleSystem, xx, yy , 0, frameScale, frameScale)
  end
  if self.frame >= 2 then
    local xx, yy = self.body:getWorldPoint(self.textWidth/2,-self.textHeight/2)
    gfx.draw(self.particleSystem, xx, yy, 0, frameScale, frameScale)
  end
  if self.frame >= 1 then
    local xx, yy =self.body:getWorldPoint(0,-self.textHeight/2)
    gfx.draw(self.particleSystem, xx, yy, 0, frameScale, frameScale)
  end

  -- draw the bounding box
  --[[
  gfx.setColor(255,255,0, 128)
  local boxX1, boxY1, boxX2, boxY2, boxX3, boxY3, boxX4, boxY4 = self.body:getWorldPoints(self.shape:getPoints())
  gfx.polygon("fill", 
    boxX1 - 5, boxY1 - 2, 
    boxX2 + 5, boxY2 - 3, 
    boxX3 + 5, boxY3 + 2, 
    boxX4 - 5, boxY4 + 3)
  ]]

  gfx.setFont(self.font)

  gfx.setColor(self.flashingDurationTimer > 0.0 and self.flashingColor or {0,0,0,128})
  gfx.print(self.word.spell, x, y, self.body:getAngle(), 1.05, 1.05, 2, 2)
  
  local textColor
  if self.hitCount > 1 then
    textColor = scene.targetHitColors[2]
  elseif self.hitCount > 0 then
    textColor = scene.targetHitColors[1]
  else
    textColor = self.color
  end
  gfx.setColor(textColor)
  gfx.print(self.word.spell, x, y, self.body:getAngle())

  if self.partialHitLength > 0 then
    local highlightedText = self.word.spell:sub(1, self.partialHitLength)
    local highlightColor = {
      textColor[1] > 200 and 0 or 255, 
      200,
      (textColor[3] + 150) % 255, 
      180}
    gfx.setColor(highlightColor)
    gfx.print(highlightedText, x, y, self.body:getAngle())
  end

end

function Target:update(dt, input)
  self.body:applyForce(0, self.speed)
  self.particleSystem:update(dt)

  if self.hitGround then
    self.fuseBurn = self.fuseBurn + dt
    self.frame = self.fuseBurn * (5/self.fuseLength)
  end

  self.partialHitLength = 0
  if string.sub(self.word.spell, 1, string.len(input)) == input then
    self.partialHitLength = string.len(input)
  end

  if self.flashingDuration > 0 then
    self.flashingDuration = self.flashingDuration - dt
  else
    self.flashingTimer = self.flashingTimer - dt
    if self.flashingTimer <= 0 then
      self.flashingTimer = self.flashingFreq
      self.flashingDurationTimer = self.flashingDuration
    end
  end
end

function Target:bounce()
  local speed = math.abs(self.speed)
  self.body:applyForce(math.random(-speed*1000, speed*1000), math.random(-speed*10000, speed*100))
  self.speed = math.min(-speed*1.5, -200)
  self.fuseBurn = -5
end

function Target:hitTest(text)
  if self.word.spell == text then
    scene.audio.hit:stop()
    scene.audio.hit:play()
    self:bounce()
    self.hitCount = self.hitCount + 1
    self.word.hitCount = self.word.hitCount + 1
    return self.hitCount == 1 -- only return true on first hit
  end
  return false
end

function Target:onHitGround()
  self.hitGround = true
end

return Target
