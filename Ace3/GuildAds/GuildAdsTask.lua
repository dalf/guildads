----------------------------------------------------------------------------------
--
-- GuildAdsTask.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

-- based on http://dongle.googlecode.com/svn/branches/Dongle-1.1/Dongle.lua

local _G = _G
local table_insert = _G.table.insert
local table_remove = _G.table.remove
local table_concat = _G.table.concat
local unpack = _G.unpack
local pairs = _G.pairs
local next = _G.next
local xpcall = xpcall

GuildAdsTask = { }

local emptyArray = {}
local frame
local timers = {}
local heap = {}
local localtime = 0
local lasttime = 0
local _localtime = 0
local eventcount = 0
local disconnected = false

-- Dispatcher ----------------------------------------------
local function errorhandler(err)
	return geterrorhandler()(err)
end

local function CreateDispatcher(argCount)
	local code = [[
		local xpcall, eh = ...	-- our arguments are received as unnamed values in "..." since we don't have a proper function declaration
		local method, ARGS
		local function call() return method(ARGS) end
	
		local function dispatch(func, ...)
			 method = func
			 if not method then return end
			 ARGS = ...
			 return xpcall(call, eh)
		end
	
		return dispatch
	]]
	
	local ARGS = {}
	for i = 1, argCount do ARGS[i] = "arg"..i end
	code = code:gsub("ARGS", table.concat(ARGS, ", "))
	return assert(loadstring(code, "safecall Dispatcher["..argCount.."]"))(xpcall, errorhandler)
end

local Dispatchers = setmetatable({}, {
	__index=function(self, argCount)
		local dispatcher = CreateDispatcher(argCount)
		rawset(self, argCount, dispatcher)
		return dispatcher
	end
})
Dispatchers[0] = function(func)
	return xpcall(func, errorhandler)
end
 
local function safecall(func, ...)
	return Dispatchers[select('#', ...)](func, ...)
end

-- Scheduler -----------------------------------------------

local function HeapSwap(i1, i2)
	heap[i1], heap[i2] = heap[i2], heap[i1]
end

local function HeapBubbleUp(index)
	while index > 1 do
		local parentIndex = math.floor(index / 2)
		if heap[index].timeToFire < heap[parentIndex].timeToFire then
			HeapSwap(index, parentIndex)
			index = parentIndex
		else
			break
		end
	end
end

local function HeapBubbleDown(index)
	while 2 * index <= heap.lastIndex do
		local leftIndex = 2 * index
		local rightIndex = leftIndex + 1
		local current = heap[index]
		local leftChild = heap[leftIndex]
		local rightChild = heap[rightIndex]

		if not rightChild then
			if leftChild.timeToFire < current.timeToFire then
				HeapSwap(index, leftIndex)
				index = leftIndex
			else
				break
			end
		else
			if leftChild.timeToFire < current.timeToFire or
			   rightChild.timeToFire < current.timeToFire then
				if leftChild.timeToFire < rightChild.timeToFire then
					HeapSwap(index, leftIndex)
					index = leftIndex
				else
					HeapSwap(index, rightIndex)
					index = rightIndex
				end
			else
				break
			end
		end
	end
end

local function OnUpdate(self, elapsed)
	localtime = localtime + elapsed;
	local schedule = heap[1]
	--if not fake then
	--	eventcount = 0
	--end
	if disconnected then
		GuildAds_ChatDebug(GA_DEBUG_GLOBAL, "Reconnecting (maybe).", elapsed)
		if GuildAdsComm and not GuildAdsComm.channelName then
		-- rejoin if GuildAds was previously disconnected
		GuildAds_ChatDebug(GA_DEBUG_GLOBAL, "Reconnecting.", elapsed)
		GuildAds:JoinChannel()
		disconnected = false
	end
	end
	while schedule and schedule.timeToFire < localtime do
		-- if there is lag, get back in time, and exit for now
		if elapsed>0.5 then
			GuildAds_ChatDebug(GA_DEBUG_GLOBAL, "lag, delay for scheduled tasks")
			localtime = localtime - elapsed
			return
		end
		-- 
		if schedule.cancelled then
			HeapSwap(1, heap.lastIndex)
			heap[heap.lastIndex] = nil
			heap.lastIndex = heap.lastIndex - 1
			HeapBubbleDown(1)
		else
			safecall(schedule.func, unpack(schedule.args or emptyArray))
			
			if schedule.repeating then
				schedule.timeToFire = schedule.timeToFire + schedule.repeating
				HeapBubbleDown(1)
			else
				HeapSwap(1, heap.lastIndex)
				heap[heap.lastIndex] = nil
				heap.lastIndex = heap.lastIndex - 1
				HeapBubbleDown(1)
				timers[schedule.name] = nil
			end
			
		end
		schedule = heap[1]
	end
	if not schedule then self:Hide() end
end

GuildAdsTask.HeapSwap = HeapSwap
GuildAdsTask.HeapBubbleUp = HeapBubbleUp
GuildAdsTask.HeapBubbleDown = HeapBubbleDown

function GuildAdsTask:AddNamedSchedule(name, t, r, count, func, ...)
	assert(count==nil, "count~=nil not implemented");
	assert(type(func)=="function", "function cannot be nil");
	self:ScheduleTimer(name, func, t, ...)
	if r then
		timers[name].repeating = t
	end
end

function GuildAdsTask:ScheduleTimer(name, func, delay, ...)
	if GuildAdsTask:NamedScheduleCheck(name) then
		GuildAdsTask:DeleteNamedSchedule(name)
	end

	local schedule = {}
	timers[name] = schedule
	schedule.timeToFire = localtime + delay
	schedule.func = func
	schedule.name = name
	if select('#', ...) ~= 0 then
		schedule.args = { ... }
	end

	if heap.lastIndex then
		heap.lastIndex = heap.lastIndex + 1
	else
		heap.lastIndex = 1
	end
	heap[heap.lastIndex] = schedule
	HeapBubbleUp(heap.lastIndex)
	if not frame:IsShown() then
		frame:Show()
	end
end

function GuildAdsTask:NamedScheduleCheck(name)
	local schedule = timers[name]
	if schedule then
		return true, schedule.timeToFire - localtime
	else
		return false
	end
end

function GuildAdsTask:DeleteNamedSchedule(name)
	local schedule = timers[name]
	if not schedule then return end
	schedule.cancelled = true
	timers[name] = nil
end

function GuildAdsTask:GetTasks()
	return timers, heap;
end

function GuildAdsTask:GetOnUpdate()
	return OnUpdate;
end


local function OnEvent(self, event, ...)
	local time = GetTime()
	if _localtime == localtime then
		-- according to OnUpdate, no time has passed since last event
		-- this can be ok: Several events can happen at the same time

		if time - lasttime > 1 then
			-- according to events, some time (1 second) has passed

			if eventcount > 0 and disconnected == false then
				-- 1 events has passed, all with time elapsed between them, yet no OnUpdate call:
				-- wow is probably minimized and we will have to simulate OnUpdate calls from the OnEvent calls.
				--GuildAds_ChatDebug(GA_DEBUG_GLOBAL, "Fake OnUpdate (%s)", time - lasttime)
				GuildAds_ChatDebug(GA_DEBUG_GLOBAL, "OnUpdate not being called. Disconnecting. (%s)", time - lasttime)
				disconnected = true
				-- 
				
				GuildAds:LeaveChannel()
				
				-- Send D> message directly as the send queue is driven by OnUpdate (and hence not running)
				-- This REALLY needs to be put the correct place. This is an ugly hack!
				--SendAddonMessage(GUILDADS_MSG_PREFIX, "D>", "GUILD");
				--OnUpdate(self, time - lasttime, true)
			else
				eventcount = eventcount + 1
			end
		end
	end
	lasttime = time
	_localtime = localtime
end

function GuildAdsTask:Initialize()
	frame = CreateFrame("Frame")
	frame:SetScript("OnUpdate", OnUpdate)

	lasttime = GetTime()
	frame:RegisterEvent("CHAT_MSG_ADDON")
	frame:RegisterEvent("CHAT_MSG_CHANNEL")
	--frame:RegisterAllEvents()
	frame:SetScript("OnEvent", OnEvent)
end
