----------------------------------------------------------------------------------
--
-- GuildAdsDataType.lua
--
-- Author: Zarkan, Fka� of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local AceEvent = AceLibrary("AceEvent-2.0");
local AceOO = AceLibrary("AceOO-2.0");

-- GuildAdsDataTypeInterface
GuildAdsDataTypeInterface = AceOO.Interface {
	iterator = "function",
	set = "function",
	get = "function",
	clear = "function",
	getRevision = "function",
	setRevision = "function",
	setRaw = "function",
	delete = "function",
	getMostRecentVersion = "function",
	setMostRecentVersion = "function",
	triggerEvent = "function"
};

-- GuildAdsDataType
GuildAdsDataType = AceOO.Class(GuildAdsDataTypeInterface, AceEvent);
GuildAdsDataType.CHANNEL = "CHANNEL";
GuildAdsDataType.PROFILE = "PROFILE";
function GuildAdsDataType:ToString()
	return "GuildAdsDataType";
end

function GuildAdsDataType.prototype:init(o)
	GuildAdsDataType.super.prototype.init(self)
	if type(o)=="table" then
		for k,v in pairs(o) do
			self[k] = v
		end
	end
	-- o.eventRegistry utile ?
	self.eventRegistry = {};
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
function GuildAdsDataType.prototype:iterator(playerName, id)
	error("GuildAdsDataType:iterator not implemented", 2);
end

function GuildAdsDataType.prototype:set(playerName, id, data)
	error("GuildAdsDataType:set not implemented", 2);
end

function GuildAdsDataType.prototype:clear()
	error("GuildAdsDataType:deleteAll not implemented", 2);
end

function GuildAdsDataType.prototype:getRevision(playerName)
	error("GuildAdsDataType:getRevision not implemented", 2);
end

function GuildAdsDataType.prototype:setRevision(playerName, revisionNumber)
	error("GuildAdsDataType:setRevision not implemented", 2);
end

function GuildAdsDataType.prototype:setRaw(playerName, id, data, revisionNumber)
	error("GuildAdsDataType:setRaw not implemented", 2);
end

function GuildAdsDataType.prototype:delete(playerName, id)
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

--[[ iterator ]]
GuildAdsDataType.prototype.iteratorAuthor = function(state, playerName)
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
function GuildAdsDataType.prototype:getMostRecentVersion()
	return GuildAds.db:get({ "Versions", "DataTypes", self.metaInformations.name }, "MostRecent");
end

function GuildAdsDataType.prototype:setMostRecentVersion(version)
	return GuildAds.db:set({ "Versions", "DataTypes", self.metaInformations.name }, "MostRecent", version);
end

--[[ about events ]]
function GuildAdsDataType.prototype:triggerEvent(playerName, id)
	if self.eventRegistry then
		GuildAds_ChatDebug(GA_DEBUG_STORAGE, "["..self.metaInformations.name..","..playerName..","..tostring(id).."] triggerEvent - begin");
		for obj, method in pairs(self.eventRegistry) do
			if method == true then
				GuildAds_ChatDebug(GA_DEBUG_STORAGE, "  - function");
				obj(self, playerName, id)
			else
				if( obj[method] ) then 
					GuildAds_ChatDebug(GA_DEBUG_STORAGE, "  - method");
					obj[method](obj, self, playerName, id);
				end
			end
		end
		GuildAds_ChatDebug(GA_DEBUG_STORAGE, "["..self.metaInformations.name..","..playerName..","..tostring(id).."] triggerUpdate - end");
	end
end


function GuildAdsDataType.prototype:registerEvent(obj, method)
	if not self.eventRegistry then
		self.eventRegistry = {};
	end
	self.eventRegistry[obj] = method or true;
end


function GuildAdsDataType.prototype:unregisterEvent(obj)
	if self.eventRegistry then
		self.eventRegistry[obj] = nil;
	end
end

function GuildAdsDataType.prototype:registerUpdate(obj, method)
	if not self.eventRegistry then
		self.eventRegistry = {};
	end
	self.eventRegistry[obj] = method or true;
end

function GuildAdsDataType.prototype:unregisterUpdate(obj)
	if self.eventRegistry then
		self.eventRegistry[obj] = nil;
	end
end

--[[ isValid() returns true if the data type is valid ]]
function GuildAdsDataType.prototype:isValid()
    -- Check metainformations
    if type(self.metaInformations) == "table" then
		local metainfo = self.metaInformations;
		
		-- check name
		if type(metainfo.name)~="string" then
			return false, "Data type name check failed.";
		end
		
		-- check version
		if type(metainfo.guildadsCompatible)~="number" or metainfo.guildadsCompatible>GUILDADS_VERSION then
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
function GuildAdsDataType.prototype:register()
	local status, errorMessage = self:isValid();
	if status then
		GuildAdsDB:RegisterDataType(self);
	else
		GuildAds:Print("Invalid datatype : "..errorMessage);
	end;
end