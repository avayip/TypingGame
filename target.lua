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
    flashingColor = { {0,0,255,255} },
    flashingFreq = 0.2,
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
  ps:setColors({255, 128, 32, 255}, {222, 128, 64, 255}, {128, 32, 32, 32}, {90, 12, 12, 92}, {32, 32, 32, 0})
  ps:setDirection(math.rad(90))
  ps:setEmissionRate(500)
  ps:setEmitterLifetime(-1)
  ps:setInsertMode("bottom")
  ps:setLinearAcceleration(0, 0, 0, -800)
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

  if self.frame >= 5 then
    gfx.draw(self.particleSystem, self.body:getWorldPoint(-self.textWidth/4,-self.textHeight/2), 0)
  end
  if self.frame >= 4 then
    gfx.draw(self.particleSystem, self.body:getWorldPoint(self.textWidth/4,-self.textHeight/2), 0)
  end
  if self.frame >= 3 then
    gfx.draw(self.particleSystem, self.body:getWorldPoint(-self.textWidth/2,-self.textHeight/2), 0)
  end
  if self.frame >= 2 then
    gfx.draw(self.particleSystem, self.body:getWorldPoint(self.textWidth/2,-self.textHeight/2), 0)
  end
  if self.frame >= 1 then
    gfx.draw(self.particleSystem, self.body:getWorldPoint(0,-self.textHeight/2), 0)
  end

  -- draw the bounding box
  --gfx.setColor(self.flashingColor[1])
  --gfx.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))

  if self.hitCount > 1 then
    gfx.setColor(scene.targetHitColors[2])
  elseif self.hitCount > 0 then
    gfx.setColor(scene.targetHitColors[1])
  elseif self.flashingColor[1] then
    gfx.setColor(self.flashingColor[1])
  else
    gfx.setColor(self.color)
  end

  gfx.setFont(self.font)
  gfx.print(self.word.spell, x, y, self.body:getAngle())

  if self.partialHitLength > 0 then
    local highlightedText = self.word.spell:sub(1, self.partialHitLength)
    gfx.setColor(255,255,0, 150)
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

  self.flashingFreq = self.flashingFreq - dt
  if self.flashingFreq <= 0 then
    self.flashingColor[1], self.flashingColor[2] = self.flashingColor[2], self.flashingColor[1]
    self.flashingFreq = 0.2
  end
end

function Target:bounce()
  local speed = math.abs(self.speed)
  self.body:applyForce(math.random(-speed*1000, speed*1000), math.random(-speed*10000, speed*100))
  self.speed = math.min(-speed*1.5, -200)
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
