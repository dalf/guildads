----------------------------------------------------------------------------------
--
-- GuildAdsDataType.lua
--
-- Author: Zarkan, Fkaï of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

-- GuildAdsDataType
GuildAdsDataType = { 
	PROFILE = "PROFILE",
	CHANNEL = "CHANNEL",
};

function GuildAdsDataType:new(o)
	self.__index = self
	return setmetatable(o or {}, self)
end

--[[ 
	GuildAdsDataType:Initialize()
	GuildAdsDataType:InitializeChannel()
]]

--[[
	iterator(playerName, nil)	playerName, id, data, revision
	iterator(nil, id)			id, playerName, data, revision
	iterator()					_, playerName, id, data, revision

	------------------------------------------------------------------
	for var_1, ..., var_n in explist do block end
		is equivalent to the code:
	do
		local _f, _s, var_1 = explist
		local var_2, ... , var_n
		while true do
			var_1, ..., var_n = _f(_s, var_1)
			if var_1 == nil then break end
			block
		end
	end
	return 
]]
function GuildAdsDataType:iterator(playerName, id)
	error("GuildAdsDataType:iterator not implemented", 2);
end

function GuildAdsDataType:set(playerName, id, data)
	error("GuildAdsDataType:set not implemented", 2);
end

function GuildAdsDataType:clear()
	error("GuildAdsDataType:deleteAll not implemented", 2);
end

function GuildAdsDataType:getRevision(playerName)
	error("GuildAdsDataType:getRevision not implemented", 2);
end

function GuildAdsDataType:setRevision(playerName, revisionNumber)
	error("GuildAdsDataType:setRevision not implemented", 2);
end

function GuildAdsDataType:setRaw(playerName, id, data, revisionNumber)
	error("GuildAdsDataType:setRaw not implemented", 2);
end

function GuildAdsDataType:delete(playerName, id)
	if playerName and id then
		self:set(playerName, id);
		return 1;
	elseif playerName and not id then
		local tmp = {};
		for currentId in self:iterator(playerName) do
			tinsert(tmp, currentId);
		end
		for _, currentId in ipairs(tmp) do
			self:set(playerName, currentId);
		end
		return table.getn(tmp);
	elseif not playerName and id then
		local tmp = {};
		for currentPlayerName in self:iterator(nil, id) do
			tinsert(tmp, currentPlayerName);
		end
		for _, currentPlayerName in ipairs(tmp) do
			self:set(currentPlayerName, id);
		end
		return table.getn(tmp);		
	end
end

function GuildAdsDataType:clear(playerName)
	if (not playerName) then
		error("GuildAdsDataType:clear(nil) not implemented", 2);
	end
	local tmp = {};
	for currentId in self:iterator(playerName) do
		tinsert(tmp, currentId);
	end
	for _, currentId in ipairs(tmp) do
		self:setRaw(playerName, currentId);
	end
	self:setRevision(playerName);
	GuildAdsHash:UpdateHashTree(self, playerName, nil);
	return table.getn(tmp);
end

--[[ iterator ]]
GuildAdsDataType.iteratorAuthor = function(state, playerName)
	-- state = { self, id }
	-- iteration sur la liste des joueurs
	local players;
	if state[1].channel then
		players = state[1].channel:getPlayers();
	else
		players = GuildAdsDB.channel[GuildAds.channelName]:getPlayers();
	end
	local data;
	
	
	playerName = next(players, playerName);
	if playerName then
		data = state[1]:get(playerName, state[2]);
	end;
	
	while playerName and data==nil do
		playerName = next(players, playerName);
		if playerName then
			data = state[1]:get(playerName, state[2]);
		end;
	end
	
	if data then
		return playerName, state[2], data, data._u;
	end
end

--[[ about version ]]
function GuildAdsDataType:getMostRecentVersion()
	return GuildAds.db:get({ "Versions", "DataTypes", self.metaInformations.name }, "MostRecent");
end

function GuildAdsDataType:setMostRecentVersion(version)
	return GuildAds.db:set({ "Versions", "DataTypes", self.metaInformations.name }, "MostRecent", version);
end

--[[ about events ]]
local errorLog = {}
local function errorHandler(msg)
	tinsert(errorLog, msg .. "\nCall stack: \n" .. debugstack());
	GuildAdsTask:AddNamedSchedule("causeErrors", 0.01, nil, nil, causeErrors, nil)
end

local function causeErrors()
	local errorText = errorLog[1]
	if errorText then
		tremove(errorLog,1)
		GuildAdsTask:AddNamedSchedule("causeErrors", 0.01, nil, nil, causeErrors, nil)
		geterrorhandler()(errorText)
	end
end
GuildAdsDataType.causeErrors = causeErrors;

function GuildAdsDataType:triggerUpdate(playerName, id)
	if self.eventRegistry then
		GuildAds_ChatDebug(GA_DEBUG_STORAGE, "["..self.metaInformations.name..","..playerName..","..tostring(id).."] triggerUpdate - begin");
		for obj, method in pairs(self.eventRegistry) do
			if method == true then
				GuildAds_ChatDebug(GA_DEBUG_STORAGE, "  - function");
				xpcall(function() obj(self, playerName, id) end, errorHandler)
				--obj(self, playerName, id)
			else
				if( obj[method] ) then 
					GuildAds_ChatDebug(GA_DEBUG_STORAGE, "  - method");
					xpcall(function() obj[method](obj, self, playerName, id) end, errorHandler)
					--obj[method](obj, self, playerName, id);
				end
			end
		end
		GuildAds_ChatDebug(GA_DEBUG_STORAGE, "["..self.metaInformations.name..","..playerName..","..tostring(id).."] triggerUpdate - end");
	end
end

function GuildAdsDataType:registerUpdate(obj, method)
	if not self.eventRegistry then
		self.eventRegistry = {};
	end
	self.eventRegistry[obj] = method or true;
end

function GuildAdsDataType:unregisterUpdate(obj)
	if self.eventRegistry then
		self.eventRegistry[obj] = nil;
	end
end

--[[ triggered when valid transactions are received ]]
function GuildAdsDataType:triggerTransactionReceived(playerName, newKeys, deletedKeys)
	if self.transactionReceivedRegistry then
		GuildAds_ChatDebug(GA_DEBUG_STORAGE, "["..self.metaInformations.name..","..playerName..","..tostring(id).."] triggerTransactionReceived - begin");
		for obj, method in pairs(self.transactionReceivedRegistry) do
			if method == true then
				GuildAds_ChatDebug(GA_DEBUG_STORAGE, "  - function");
				xpcall(function() obj(self, playerName, newKeys, deletedKeys) end, errorHandler)
				--obj(self, playerName, newKeys, deletedKeys)
			else
				if( obj[method] ) then 
					GuildAds_ChatDebug(GA_DEBUG_STORAGE, "  - method");
					xpcall(function() obj[method](obj, self, playerName, newKeys, deletedKeys) end, errorHandler)
					--obj[method](obj, self, playerName, newKeys, deletedKeys);
				end
			end
		end
		GuildAds_ChatDebug(GA_DEBUG_STORAGE, "["..self.metaInformations.name..","..playerName..","..tostring(id).."] triggerTransactionReceived - end");
	end
end

function GuildAdsDataType:registerTransactionReceived(obj, method)
	if not self.transactionReceivedRegistry then
		self.transactionReceivedRegistry= {};
	end
	self.transactionReceivedRegistry[obj] = method or true;
end

function GuildAdsDataType:unregisterTransactionReceived(obj)
	if self.transactionReceivedRegistry then
		self.transactionReceivedRegistry[obj] = nil;
	end
end

--[[ isValid() returns true if the data type is valid ]]
function GuildAdsDataType:isValid()
    -- Check metainformations
    if type(self.metaInformations) == "table" then
		local metainfo = self.metaInformations;
		
		-- check name
		if type(metainfo.name)~="string" then
			return false, "Data type name check failed.";
		end
		
		-- check dependency
		if type(metainfo.depend)~="table" then
			return false, "Dependency table missing.";
		end
		
		-- check version
		if type(metainfo.guildadsCompatible)~="number" or metainfo.guildadsCompatible>GUILDADS_REVISION_NUMBER then
			return false, "Data type incompatible with this version of GuildAds";
		end
		
		-- check parent
		if metainfo.parent ~= GuildAdsDataType.PROFILE and metainfo.parent ~= GuildAdsDataType.CHANNEL then
			return false, "Invalid metainformations.parent";
		end
		
		-- check schema for network
		if type(self.schema)~="table" then
			return false, "No schema";
		end
		
		if not((type(self.schema.id)=="string" and type(self.schema.data)=="table") or type(self.schema.keys)=="table") then
			return false, "Invalid schema";
		end
	else
		return false, "Data type Metainformations check failed.";
    end
		
	return true;
end

--[[ register the data type ]]
function GuildAdsDataType:register()
	local status, errorMessage = self:isValid();
	if status then
		GuildAdsDB:RegisterDataType(self);
	else
		GuildAds:Print("invalid datatype : "..errorMessage);
	end;
end