local scheduler = {
	clock = 0,
	sleepOnTimerCoroutines = {}, -- key = coroutine, value = time
	sleepOnEventCoroutines = {}, -- key = event name, value = table of coroutines
}

function scheduler:waitSeconds(sec)
	local co = coroutine.running()
	assert(co, "only coroutines can wait")
	self.sleepOnTimerCoroutines[co] = self.clock + sec
	return coroutine.yield(co)
end

function scheduler:update(dt)
	self.clock = self.clock + dt

	local awake = {}
	for co, wakeTime in pairs(self.sleepOnTimerCoroutines) do
		if wakeTime < self.clock then
			table.insert(awake, co)
		end
	end

	for _, co in ipairs(awake) do
		self.sleepOnTimerCoroutines[co] = nil
		coroutine.resume(co)
	end
end

function scheduler:waitEvent(eventName)
	local co = coroutine.running()
	assert(co, "only coroutines can wait")

	if not self.sleepOnEventCoroutines[eventName] then
		self.sleepOnEventCoroutines[eventName] = {co}
	else
		table.insert(self.sleepOnEventCoroutines[eventName], co)
	end
	local ret = coroutine.yield(co)
	return ret
end

function scheduler:event(eventName, ...)
	local waitingCoroutines = self.sleepOnEventCoroutines[eventName]
	if waitingCoroutines then
		self.sleepOnEventCoroutines[eventName] = nil
		for _, co in ipairs(waitingCoroutines) do
			coroutine.resume(co,...)
		end
	end
end

function scheduler.wrap(func)
	return coroutine.wrap(func)
end

function scheduler.start(func, ...)
	local co = coroutine.create(func)
	coroutine.resume(co,...)
end

return scheduler
