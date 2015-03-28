utf8 = require("utf8")

local scene = {
  bottom = 400
}

local input = ""

local Target = {}

function Target:new(o)
	o = o or {}
  o.speed = o.speed or 5
	setmetatable(o, self)
	self.__index = self
	return o
end

function Target:draw()
  love.graphics.setColor(self.color)
  love.graphics.print(self.text, self.x, self.y)
end

function Target:update(dt)
  if self.y < scene.bottom then self.y = self.y + self.speed*dt end
end

function Target:hitTest(text)
  if text:lower() == self.text:lower() then
    -- TODO: play some sound here
    return true
  end
  return false
end

function love.load(arg)
  math.randomseed(os.time())
  love.keyboard.setKeyRepeat(true)
  
  local windowWidth = love.graphics.getWidth()
  
  local initTargetStrings = {"ava", "natalie", "shing", "yubei"}
  scene.targets = {}
  for _, str in ipairs(initTargetStrings) do
    local target = Target:new{
      x = math.random(1, windowWidth), 
      y = 10, 
      text = str, 
      color={math.random(50, 255), math.random(50, 255), math.random(50, 255)}
    }
    table.insert(scene.targets, target)
  end
end

function love.textinput(t)
  input = input..t
end

function love.keypressed(key)
  if key == "backspace" then
    local byteoffset = utf8.offset(input, -1)
    
    if byteoffset then
      input = input:sub(1, byteoffset - 1)
    end
  elseif key == "return" then
    for targetIdx, target in ipairs(scene.targets) do
      if target:hitTest(input) then
        table.remove(scene.targets, targetIdx)
        break
      end
    end
    input = ""
  end
end

function love.update(dt)
  for _, target in ipairs(scene.targets) do
    target:update(dt)
  end
end

function love.draw()
  for _, target in ipairs(scene.targets) do
    target:draw()
  end
  
  love.graphics.printf(input, 0, 400, love.graphics.getWidth())
end

