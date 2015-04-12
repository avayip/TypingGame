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

scaleFactor = gfx.getWidth()/640

utf8 = require("utf8")
gui = require("gui")
scene = require("scene")
scheduler = require("scheduler")
object = require("object")
target = require("target")

-- buffer for holding current player typed text
local input = ""

function love.load(arg)
    math.randomseed(os.time())
    love.keyboard.setKeyRepeat(true)
    scene:load()
end

function love.update(dt)
    scene:update(dt, input:lower())
    scheduler:update(dt)
end

function love.draw()
    local screenWidth, screenHeight = gfx.getWidth(), gfx.getHeight()

    scene:draw()
    gui:draw()

    gfx.setFont(scene.defaultFont)
    gfx.setColor(255, 255, 255)
    gfx.printf(input, 20*scaleFactor, screenHeight - 30*scaleFactor, screenWidth)
end

function love.textinput(t)
    if t ~= " " then
        input = input..t:lower()
        scheduler:event("input", input)
    end
end

function love.keypressed(key)
    if key == "backspace" then
        local byteoffset = utf8.offset(input, -1)

        if byteoffset then
            input = input:sub(1, byteoffset - 1)
            scheduler:event("input", input)
        end
    elseif key == "return" or key == " " then
        for _, tg in ipairs(scene.targets) do
            if tg:hitTest(input) then
                scene:onScored(tg)
                break
            end
        end
        input = ""
    end
end

function love.mousereleased(x, y, button)
    gui.mousereleased(x, y, button)
end

function love.resize(w, h)
    scene:resize(w, h)
end
