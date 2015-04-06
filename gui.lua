local Widget = {}
function Widget:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    if o.__init then o:__init() end
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

local gui = {
    widgets = {},
    defaultButtonFont = gfx.newFont(20)
}

gui.Button = Widget:new()

function gui.Button:__init()
    assert(self.id, "id is required")
    assert(self.x, "x is required")
    assert(self.y, "y is required")
    assert(self.w, "w is required")
    assert(self.h, "h is required")

    self.active = self.active or true

    self.rotation = self.rotation or 0
    if self.text and self.tex ~= "" then
        self.font = self.font or gui.defaultButtonFont
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

    if self.normalImage and type(self.normalImage) == "string" then
        self.normalImage = gfx.newImage(self.normalImage)
    end

    gui.widgets[self.id] = self
end

function gui.Button:draw()
    if self.color then
        gfx.setColor(self.color)
    end
    if self.normalImage then
        gfx.draw(self.normalImage,
            self.x, self.y,
            self.rotation,
            self.w/self.normalImage:getWidth(), self.h/self.normalImage:getHeight())
    end
    if self.text then
        gfx.setFont(self.font)
        gfx.print(self.text, 
            self.x + self.textXOffset, 
            self.y, 
            self.rotation, self.fontXScale, self.fontYScale,
            -self.textWidthMargin,
            -self.textHeightMargin)
    end
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
