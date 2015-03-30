--[[
Authors: Shing Yip, Ava Yip, Natalie Yip
]]

local Target = {}

function Target:new(targetScene, word)
  local windowWidth = love.graphics.getWidth()
  local font = targetScene.fonts[math.random(1, #targetScene.fonts)]
  local target = {
    font = font,
    word = word, 
    textWidth = font:getWidth(word.spell),
    textHeight = font:getHeight(word.spell),
    color = targetScene.targetColors[1],
    speed = math.random(targetScene.level.speed.min, targetScene.level.speed.max),
    partialHitLength = 0,
    hitCount = 0,
    flashingColor = { {0,0,255,255} },
    flashingFreq = 0.2,
  }
  target.body = love.physics.newBody(targetScene.world, math.random(10, windowWidth - 10), 10, "dynamic")
  target.body:setMass(10)
  target.shape = love.physics.newRectangleShape(target.textWidth, target.textHeight)
  target.fixture = love.physics.newFixture(target.body, target.shape, 1)
  target.fixture:setRestitution(0.5)
  target.fixture:setUserData(word)
  setmetatable(target, self)
  self.__index = self
  return target
end

function Target:destroy()
  self.body:destroy()
  self.body = nil
  self.shape = nil
  self.fixture = nil
end

function Target:draw()
  local x, y = self.body:getWorldPoint(-self.textWidth/2, -self.textHeight/2)
 
  -- draw the bounding box
  --love.graphics.setColor(self.flashingColor[1])
  --love.graphics.polygon("fill", self.body:getWorldPoints(self.shape:getPoints()))
  
  if self.hitCount > 1 then
    love.graphics.setColor(scene.targetHitColors[2])
  elseif self.hitCount > 0 then
    love.graphics.setColor(scene.targetHitColors[1])
  elseif self.flashingColor[1] then
    love.graphics.setColor(self.flashingColor[1])
  else
    love.graphics.setColor(self.color)
  end
  love.graphics.setFont(self.font)
  love.graphics.print(self.word.spell, x, y, self.body:getAngle())

  if self.partialHitLength > 0 then 
    local highlightedText = self.word.spell:sub(1, self.partialHitLength)
    love.graphics.setColor(255,255,0, 150)
    love.graphics.print(highlightedText, x, y, self.body:getAngle())
  end

end

function Target:update(dt, input)
  self.body:applyForce(0, self.speed)
  
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

return Target