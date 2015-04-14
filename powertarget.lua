local Target = require("target")

PowerTarget = Target:prototype()

local boxImg = gfx.newImage("graphics/wood.png")

function PowerTarget:__init()
	self.super.__init(self)
	self.boxWidth = self.textWidth + 4
	self.boxHeight = self.textHeight + 4
	self.boxXScale = self.boxWidth/boxImg:getWidth()
	self.boxYScale = self.boxHeight/boxImg:getHeight()
end

function PowerTarget:draw()
    local x, y = self.body:getWorldPoint(-self.boxWidth/2, -self.boxHeight/2)
	gfx.setColor(colors.white)
	gfx.draw(boxImg,
		x, y,
		self.body:getAngle(),
		self.boxXScale, self.boxYScale)
	self.super.draw(self)
end

function PowerTarget:hitTest(text)
	local hit = self.super.hitTest(self, text)
	if hit and self.powerFunc then
		self.powerFunc()
	end
	return hit
end

return PowerTarget
