local gfx = love.graphics

local gui = {
    widgets = {},
    defaultButtonFont = gfx.newFont(20)
}

--[=[
Widget Class
]=]

local Widget = {}
function Widget:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    if o.__init then o:__init() end

	if self ~= Widget then
		assert(o.id, "id is required")
		assert(o.x, "x is required")
		assert(o.y, "y is required")
		assert(o.w, "w is required")
		assert(o.h, "h is required")
		o.active = o.active or true
	end

    return o
end

function Widget:isHit(x, y)
    return x >= self.x and y >= self.y and
    x <= (self.x + self.w) and y <= (self.y + self.h)
end

function Widget:clickTest(x, y, btn)
    if not self:isHit(x, y) then
        return
    end

    if self.onClick then
        self:onClick(x, y, btn)
    end
end

--[=[
Button Class
]=]
gui.Button = Widget:new()

function gui.Button:__init()
    self.rotation = self.rotation or 0
    if self.text and self.text ~= "" then
        self.font = self.font or gui.defaultButtonFont
		self:sizeChanged()
    end

    if self.normalImage and type(self.normalImage) == "string" then
        self.normalImage = gfx.newImage(self.normalImage)
    end
end

function gui.Button:sizeChanged()
    if self.text and self.text ~= "" then
        local textWidth = self.font:getWidth(self.text)
        local textHeight = self.font:getHeight(self.text)
        self.textWidthMargin = self.textWidthMargin or textWidth*0.2
        self.textHeightMargin = self.textHeightMargin or textHeight*0.2
        self.fontXScale = self.fontXScale or 1
        if self.fontXScale == -1 then
            self.fontXScale = self.w/(textWidth + self.textWidthMargin*2)
        end
        self.fontYScale = self.fontYScale or self.h/(textHeight + self.textHeightMargin*2)
        self.textXOffset = (self.w - self.fontXScale*(textWidth + self.textWidthMargin*2))/2
    end
end

function gui.Button:draw()
    if self.normalImage then
		gfx.setColor(self.imageColor and self.imageColor or {255,255,255,255})
        gfx.draw(self.normalImage,
            self.x, self.y,
            self.rotation,
            self.w/self.normalImage:getWidth(), self.h/self.normalImage:getHeight())
    end
    if self.text and self.text ~= "" then
		if self.color then
			gfx.setColor(self.color)
		end
        gfx.setFont(self.font)
        gfx.print(self.text,
            self.x + self.textXOffset,
            self.y,
            self.rotation, self.fontXScale, self.fontYScale,
            -self.textWidthMargin,
            -self.textHeightMargin)
    end
end

--[=[
Grid Class
]=]
gui.Grid = Widget:new()

function gui.Grid:__init()
	if self.layout and #self.layout > 0 then
		self:planLayout()
	end
	self.widgets = self.widgets or {}
end

function gui.Grid:planLayout()
	self.widgets = {}
	local y = self.y
	local w = self.w/#self.layout[1]
	local h = self.h/#self.layout
	for _, row in ipairs(self.layout) do
		local x = self.x
		for _, cell in ipairs(row) do
			local maker = cell.maker
			if maker then
				local init = cell.init or {}
				init.x = x
				init.y = y
				init.w = w*(cell.hspan or 1)
				init.h = h*(cell.vspan or 1)
				self.widgets[#self.widgets + 1] = maker(init)
			end
			x = x + w*(cell.hspan or 1)
		end
		y = y + h
	end
end

function gui.Grid:draw()
	self:forward("draw")
end

function gui.Grid:clickTest(...)
	self:forward("clickTest", ...)
end

function gui.Grid:forward(func, ...)
	for _, widget in ipairs(self.widgets) do
		if widget and widget.active then
			widget[func](widget, ...)
		end
	end
end

--[=[
gui module functions
]=]

function gui.add(widget)
	gui.widgets[widget.id] = widget
end

function gui.remove(id, ...)
    if id == nil then
        return
    end
    gui.widgets[id] = nil
    gui.remove(...)
end

function gui.newButton(o)
    return gui.Button:new(o)
end

function gui.draw()
    for _, widget in pairs(gui.widgets) do
        if widget.active then widget:draw() end
    end
end

function gui.mousereleased(x, y, btn)
    for _, widget in pairs(gui.widgets) do
        if widget.active then
            widget:clickTest(x, y, btn)
        end
    end
end

return gui
