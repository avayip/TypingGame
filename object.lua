Object = {}

function Object:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    if o.__init then o:__init() end
    return o
end

function Object:setShape(shape)
    self.shape = shape
end

function Object:addToWorld(world, x, y, bodyType)
    if not self.shape then
        error("object has no shape, use Object:setShape to add shape")
    end
    self.body = self.body or phys.newBody(world, x, y, bodyType)
    self.fixture = phys.newFixture(self.body, self.shape)
    self.fixture:setUserData(self)
    return self
end

function Object:destroy()
    if self.fixture then self.fixture:setUserData(nil) end
    if self.body then self.body:destroy() end
    self.body = nil
    self.shape = nil
    self.fixture = nil
end

return Object
