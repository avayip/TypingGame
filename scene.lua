--[[
Authors: Shing Yip, Ava Yip, Natalie Yip
]]

--[[
scene table defines game scene
]]
local scene = {
    targets = {},
    score = 0,
    dictionary = {},
    warningflame = 2,
    maxflame = 5,
    levels = {
        { name = "Level 1",
            themeMusic = audio.newSource("sound/Spiritual_Moments.mp3"),
            background = gfx.newImage("graphics/summer-landscape-illustration.jpg"),
            wordCount = {min=1, max=3},
            wordLengthLimit = 6,
            speed = {min=1, max=5},
            dropInterval = 3,
            levelUpTarget = 5,
            flameSpreadSpeed = 5
        },
        { name = "Level 2",
            themeMusic = audio.newSource("sound/mvrasseli_play_the_game_0.mp3"),
            background = gfx.newImage("graphics/summer-landscape-illustration.jpg"),
            wordCount = {min=2, max=5},
            wordLengthLimit = 8,
            speed = {min=3, max=8},
            dropInterval = 2,
            levelUpTarget = 12,
            flameSpreadSpeed = 4
        },
        { name = "Level 3",
            themeMusic = audio.newSource("sound/epic_loop.mp3"),
            background = gfx.newImage("graphics/summer-landscape-illustration.jpg"),
            wordCount = {min=3, max=10},
            speed = {min=5, max=12},
            dropInterval = 1,
            levelUpTarget = 20,
            flameSpreadSpeed = 3
        },
        { name = "Level 4",
            themeMusic = audio.newSource("sound/Preliminary_Music.mp3"),
            background = gfx.newImage("graphics/summer-landscape-illustration.jpg"),
            wordCount = {min=4, max=15},
            speed = {min=7, max=14},
            dropInterval = 0.5,
            levelUpTarget = 35,
            flameSpreadSpeed = 2
        },
        { name = "Level 5",
            themeMusic = audio.newSource("sound/Spiritual_Moments.mp3"),
            background = gfx.newImage("graphics/summer-landscape-illustration.jpg"),
            wordCount = {min=5, max=20},
            speed = {min=10, max=16},
            dropInterval = 0.5,
            levelUpTarget = 40,
            flameSpreadSpeed = 2
        },
        { name = "Level 6",
            themeMusic = audio.newSource("sound/Spiritual_Moments.mp3"),
            background = gfx.newImage("graphics/summer-landscape-illustration.jpg"),
            wordCount = {min=10, max=35},
            speed = {min=5, max=20},
            dropInterval = 0.5,
            levelUpTarget = -1,
            flameSpreadSpeed = 1
        },
    },
    level = nil,
    gameOverMusic = audio.newSource("sound/Target_position.mp3"),
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
    audio = {
        hit = audio.newSource("sound/whistle.wav", "static"),
        levelUp = audio.newSource("sound/magical_1_0.ogg", "static"),
        explosion = audio.newSource("sound/explosion.ogg", "static"),
        siren = audio.newSource("sound/air_raid_siren.ogg", "static")
    },
	rainDropImg = gfx.newImage("graphics/raindrop.png"),
    levelIdx = 1,
    score = 0,
    superPower = {}
}

function scene:load()
    self:loadDictionary("dictionary.txt")

    self.fonts = {
        gfx.newFont("fonts/charlie_dotted.ttf", 40*scaleFactor),
        gfx.newFont("fonts/sans_plate_caps.ttf", 24*scaleFactor),
        gfx.newFont("fonts/alpaca_scarlett_demo.ttf", 24*scaleFactor),
        gfx.newFont("fonts/chock_a_block.ttf", 24*scaleFactor),

        --gfx.newFont("fonts/cut_me_out.ttf", 40*scaleFactor),
        gfx.newFont("fonts/cut_me_out2.ttf", 24*scaleFactor),
        gfx.newFont("fonts/cut_me_out3.ttf", 24*scaleFactor),

    }

    self.world:setCallbacks(self.onCollision, nil, nil, nil)

    self:createStaticObjects(screenWidth, screenHeight)
    self:reset()
end

function scene:resize(w, h)
    self:createStaticObjects(w, h)
end

function scene:createStaticObjects(screenWidth, screenHeight)
    if self.ground then self.ground:destroy() end
    self.ground = object:new{shape = phys.newRectangleShape(screenWidth, 40*scaleFactor)}
    self.ground:addToWorld(self.world, screenWidth/2, screenHeight-20*scaleFactor)

    if self.staticObjects then
        for _, obj in pairs(self.staticObjects) do obj:destroy() end
    end
    local wallShape = phys.newRectangleShape(1, screenHeight*2)
    local ceilingShape = phys.newRectangleShape(screenWidth, 1)
    self.staticObjects = {
        leftWall = object:new{shape = wallShape}:addToWorld(self.world, 1, screenHeight),
        rightWall = object:new{shape = wallShape}:addToWorld(self.world, screenWidth - 1, screenHeight),
        ceiling = object:new{shape = ceilingShape}:addToWorld(self.world, screenWidth/2, -screenHeight/2)
    }

end

function scene:reset(level)
    level = level or 1
    logInfo("reset to level %d", level)
    self.score = 0
    for _, tg in ipairs(self.targets) do
        tg:destroy()
    end
    if self.gameOver then
        self.gameOverMusic:stop()
        self.gameOver:destroy()
        self.gameOver = nil
    end
    self.targets = {}
    self:setLevel(level)
    self:addTarget()
    
    self.superPower = {self:newRainPower(), self:newRainPower(), self:newRainPower()}
end

function scene:update(dt)
    self.world:update(dt)
	if self.powerPartSys then
		self.powerPartSys:update(dt)
	end

    if self.gameOver then
        self.gameOver:update(dt)
        for index, tg in ipairs(self.targets) do
            tg:update(dt)
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
    local turnOnSiren = false
    for index, tg in ipairs(self.targets) do
        tg:update(dt)

        -- check if target is out of screen and destroy it
        if tg.body:getY() < -50 then
            tg:destroy()
            -- insert index to end of disappearedTargets, note that index is in accending order
            table.insert(disappearedTargets, index)
        elseif tg.flame > self.warningflame then
            turnOnSiren = true
            if tg.flame == self.maxflame then
                self:onGameOver()
                return
            end
        end
    end

    if not turnOnSiren then
        self.audio.siren:stop()
    elseif not self.sirenOn then
        self.audio.siren:setLooping(true)
        self.audio.siren:play()
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

function scene:onScored(tg)
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
    local words = {}
    logInfo("adding target")
    for wordCnt = 1, 5 do
        local word
        for tryCnt = 1, 10 do
            word = self.dictionary[math.random(#self.dictionary)]
            if self.level.wordLengthLimit == nil or #word.spell < self.level.wordLengthLimit then
                logInfo("word within limit %d %s", (self.level.wordLengthLimit or -1), word.spell)
                break
            end
        end
        logInfo("word candidate %s", word.spell)
        table.insert(words, word)
    end
    table.sort(words, function(w1, w2) return w1.hitCount < w2.hitCount end)
    table.insert(scene.targets, target:new{word = words[1]})
end

function scene:draw()
    local bg = self.level.background
    if bg then
        gfx.draw(bg, 0, 0, 0, screenWidth/bg:getWidth(), screenHeight/bg:getHeight())
    else
        gfx.setBackgroundColor(5, 252, 219, 128)
    end

    for _, tg in ipairs(self.targets) do
        tg:draw()
    end

	if self.powerPartSys then
        gfx.draw(self.powerPartSys, self.powerPartSysLoc.x, self.powerPartSysLoc.y, 0,
		self.powerPartSysScale.x, self.powerPartSysScale.y)
	end

    -- draw the ground
    --gfx.setColor(72, 160, 14)
    --gfx.polygon("fill", self.ground.body:getWorldPoints(self.ground.shape:getPoints()))

    -- draw the level name and socore
    gfx.setFont(scene.defaultFont)
    gfx.setColor(250, 128, 70, 255)
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
    self.level.themeMusic:stop()
    self.gameOverMusic:play()

    local body = phys.newBody(self.world, screenWidth/2, 30, "dynamic")
    body:setMass(200)
    local tg = target:new{
        word = {spell = "GAME OVER", hitCount = 0},
        font = gfx.newFont(80*scaleFactor),
        body = body,
        speed = 3000*scaleFactor}

    tg.flashingDuration = 0
    self.gameOver = tg

    gui.add(gui.newButton{
        id="new_game",
        x=screenWidth/8*2, y=screenHeight/2,
        w=200, h=40,
        color={200,255,200,255},
        textColor={0,0,255,255},
        text="New Game",
        normalImage="graphics/green_button.png",
        onClick = function() scene:reset(); gui.remove("new_game", "quit_game") end})
    gui.add(gui.newButton{
        id="quit_game",
        x=screenWidth/8*4, y=screenHeight/2,
        w=200, h=40,
        color={200,255,200,255},
        textColor={0,0,255,255},
        text="Quit",
        fontXScale=1,
        normalImage="graphics/green_button.png",
        onClick = function() love.event.quit(); gui.remove("quit_game") end})
end

function scene.onCollision(a, b, contact)
    local tg
    if a:getUserData() == scene.ground then
        tg = b:getUserData()
    elseif b:getUserData() == scene.ground then
        tg = a:getUserData()
    end
    if type(tg) == "table" and tg.onHitGround then
        tg:onHitGround()
    end
end

function scene:newRainPower()
    local body = phys.newBody(self.world, screenWidth/2, 30, "dynamic")
    body:setMass(200)
    return power:new{
        word = {spell = "rain", hitCount = 0},
        font = gfx.newFont(20*scaleFactor),
        body = body,
        speed = 3000*scaleFactor,
		powerFunc = self.rain}
end

function scene:onPower()
    if #self.superPower >= 1 then
        table.insert(scene.targets, self.superPower[1])
        table.remove(self.superPower, 1)
    end
end

function scene.rain()
	local rainScale = screenWidth/2000
    local ps = gfx.newParticleSystem(scene.rainDropImg, 5000)
    ps:setColors({220, 220, 255, 255}, {200, 200, 255, 255}, {220, 220, 255, 32}, {32, 32, 32, 0})
	ps:setAreaSpread("uniform", screenWidth*1.5, 0)
    ps:setEmissionRate(500)
    ps:setEmitterLifetime(-1)
    ps:setInsertMode("bottom")
    ps:setLinearAcceleration(0, 0, 0, 10000)
    ps:setParticleLifetime(1, 3)
    ps:setRadialAcceleration(0, 0)
    ps:setRotation(0, math.rad(15))
    ps:setSizeVariation(1.0)
    ps:setSizes(1, 1, 1, 1, 0.75, 0.5, 0.25)
    ps:setSpeed(0, 50)
    --ps:setSpin(math.rad(0), math.rad(0))
    ps:setSpinVariation(1)
    ps:setSpread(math.rad(360))
    ps:setTangentialAcceleration(0, 0)
	scene.powerPartSys = ps
	scene.powerPartSysLoc = {x = screenWidth/2, y = -50}
	scene.powerPartSysScale = {x = rainScale, y = rainScale}
	scheduler.start(scene.rainingRoutine)
end

function scene.rainingRoutine()
	for i = 1, 50 do
        for index, tg in ipairs(scene.targets) do
			tg.flame = tg.flame - 1
        end
		scheduler:waitSeconds(0.2)
	end
	scene.powerPartSys = nil
end

return scene
