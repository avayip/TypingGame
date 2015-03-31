--[[
Authors: Shing Yip, Ava Yip, Natalie Yip
]]

function logInfo(fmt,...)
	print("INFO:"..fmt:format(...))
end
function logErr(fmt,...)
	print("ERR:"..fmt:format(...))
end

gfx = love.graphics
phys = love.physics
audio = love.audio

utf8 = require("utf8")
scene = require("scene")

-- buffer for holding current player typed text
local input = ""

function love.load(arg)
  math.randomseed(os.time())
  love.keyboard.setKeyRepeat(true)

  scene:load()
end

function love.update(dt)
  scene:update(dt, input:lower())
end

function love.draw()
  local screenWidth, screenHeight = gfx.getWidth(), gfx.getHeight()

  scene:draw()

  gfx.setColor(255, 255, 255)
  gfx.setFont(scene.defaultFont)
  gfx.printf(input, 20, screenHeight - 30, screenWidth)
end

function love.textinput(t)
  if t ~= " " then
    input = input..t
  end
end

function love.keypressed(key)
  if key == "backspace" then
    local byteoffset = utf8.offset(input, -1)

    if byteoffset then
      input = input:sub(1, byteoffset - 1)
    end
  elseif key == "return" or key == " " then
    local lowercaseInput = input:lower() -- targets always store spelling in lower case
    for targetIdx, target in ipairs(scene.targets) do
      if target:hitTest(lowercaseInput) then
        scene:onScored(target)
        break
      end
    end
    input = ""
  end
end
