----------------------------------------------------------------------------------
--
-- GuildAdsDB.lua
--
-- Author: Zarkan, Fka� of European Ner'zhul (Horde)
-- URL : http://guildads.sourceforge.net
-- Email : guildads@gmail.com
-- Licence: GPL version 2 (General Public License)
----------------------------------------------------------------------------------

local HourMin = 60;
local DayMin = HourMin * 24;
local MonthMin = DayMin * 30;
local TimeRef = 18467940; 	-- Nombre de minutes entre 1/1/1970 et 11/2/2005

--[[
	doc sur LUA :http://www.lua.org/ftp/refman-5.0.pdf
	doc sur les metatables : cf page 21
	
	TODO : rename .db to .raw
]]

--[[ GuildAdsMagicMT ]]
GuildAdsMagicMT = {

	__index = function(t, n)
		local r = {};
		setmetatable(r, {
			_table = t;
			_key = n;
			__newindex = GuildAdsMagicMT.__newindex;
		});
		return r;
	end;
	
	-- create profile only when a value is set
	__newindex = function(t, n, v)
		rawset(t, n, v);
		local mt = getmetatable(t);
		mt._table[mt._key] = t;
		mt.__newindex = nil;
		mt._table = nil;
		mt._key = nil;
	end;
};

--[[ GuildAdsDBChannel ]]
GuildAdsDBChannel = {
	PLAYER = "PLAYER",
	ALLOWEDPLAYER = "ALLOWEDPLAYER",
	ALLOWEDGUILD = "ALLOWEDGUILD",
	DENIEDPLAYER = "DENIEDPLAYER", 
	DENIEDGUILD = "DENIEDGUILD"
}

function GuildAdsDBChannel:getRaw()
	return self.db;
end

function GuildAdsDBChannel:getPlayers()
	return self.db.Players;
end

function GuildAdsDBChannel:addPlayer(playerName)
	if not self.db.Players[playerName] then
		self.db.Players[playerName] = true;
		self:triggerEvent(self.PLAYER, playerName);
	end
end

function GuildAdsDBChannel:deletePlayer(playerName)
	if self.db.Players[playerName] then
		self.db.Players[playerName] = nil;
		self:triggerEvent(self.PLAYER, playerName);
	end
end

--[[
	event : 
	   - add/delete d'un joueur
	   - add/delete sur whitelist/guild, whitelist/player, blacklist/guild, blacklist/player
]]
function GuildAdsDBChannel:registerEvent(obj, method)
 GuildAds:CustomPrint(1, 0, 0, nil, nil, nil, "re: ");
	self.eventRegistry[obj] = method or true;
end

function GuildAdsDBChannel:unregisterEvent(obj)
	self.eventRegistry[obj] = nil;
end

function GuildAdsDBChannel:triggerEvent(list, name)
	for obj, method in pairs(self.eventRegistry) do
		if method == true then
			obj(self, list, name)
		else
			if( obj[method] ) then 
				obj[method](self, list, name);
			end
		end
	end
end

function GuildAdsDBChannel:isPlayerAllowed(playerName)
	return true;
	--[[
	local guildName;
	if GuildAdsDB.profile.Main then
		guildName = GuildAdsDB.profile.Main:get(playerName, GuildAdsDB.profile.Main.Guild);
	end
	local channelRoot = self.db.Admin;
	if channelRoot.blackList.guilds[guildName] or channelRoot.blackList.players[playerName] then
		return false;
	end;
	if channelRoot.whiteList.guilds[guildName] or channelRoot.whiteList.players[playerName] then
		return true;
	end;
 	return nil;
	]]
end

-- TODO : une guilde peut etre blacklist�e et whitelist�e
--[[
	Type : datatype utilis� :
		["datatype"] = version
	Type d'ACL : 
		- blocage de l'�criture sur certains type de donn�es.
		- blocage de la lecture sur certains type de donn�es.
		- blocage complet de l'acc�s au channel.
	--> ["datatype"] = 3 valeurs possibles : "RW", "R", ""
	
	.guild[guild] = { 
		"TradeOffer" = "RW";
		"_" = 
	}
	
	plugin autoris�e pour guilde
	["plugin"][who] = "RW"|"R"
]]
function GuildAdsDBChannel:addACLEntry(list, name, note)
	local t = self:getACL(list);
	if t[name] then
		t[name] = note or true;
		self:triggerEvent(list, name);
	end	
end

function GuildAdsDBChannel:deleteACLEntry(list, name)
	local t = self:getACL(list);
	if t[name] then
		t[name] = nil;
		self:triggerEvent(list, name);
	end	
end

function GuildAdsDBChannel:getACL(list)
	if list==self.PLAYER then
		return self.db.Players;
	elseif list==self.ALLOWEDPLAYER then
		return self.db.Admin.whiteList.players;
	elseif list==self.ALLOWEDGUILD then
		return self.db.Admin.whiteList.guilds;
	elseif list==self.DENIEDPLAYER then
		return self.db.Admin.blackList.players;
	elseif list==self.DENIEDGUILD then
		return self.db.Admin.blackList.guilds;
	end
end;

GuildAdsDBChannel.__index = GuildAdsDBChannel;

--[[ GuildAdsDBchannelMT ]]
GuildAdsDBchannelMT = {
	__index = function(t, n)
        GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,"Ask channel["..n.."]");
		local db = GuildAdsDBchannelMT.getChannel(n);
		-- TODO : db, eventRegistry invisibles sur une iteration sur t[n]
		t[n] = { 
			db = db;
			eventRegistry = {};
		};
		setmetatable(t[n], GuildAdsDBChannel);
		for name, datatype in pairs(GuildAdsDB._channelDataTypes) do
        GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,name);
			t[n][name] = {
				channelName = n;
				channel = t;
				db = db;
			};
			setmetatable(t[n][name], { __index=datatype } );
			if t[n][name].InitializeChannel then
				t[n][name]:InitializeChannel();
			end
		end
		return t[n];
	end;
	
	-- TODO : gerer le case des noms
	getChannel = function(channelName)
		GuildAds_ChatDebug(GA_DEBUG_STORAGE, "Ask channel["..channelName.."]");
--~         GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,"Ask channel["..channelName.."]");
		channelName = GuildAdsDBchannelMT.getChannelKey(channelName);
        GuildAds_ChatDebug(GA_DEBUG_STORAGE, "Ask channel["..channelName.."]");
        if (not GuildAds.db.profile.channels) then
         GuildAds.db.profile.channels = {};
        end;
		local t = GuildAds.db.profile.channels[channelName];
		if t == nil then
			t = {
				Players = {
				};
			};
			GuildAds.db.profile.channels[channelName] = t;
		end;
		if getmetatable(t) == nil then
			setmetatable(t, {
				__index = GuildAdsMagicMT.__index;
			});
		end
		return t;
	end;
	
	getChannelKey = function(channelName)
		return (channelName or GuildAds.channelName).."@"..GuildAds.factionName;
	end
}

--[[ GuildAdsDBprofileMT ]]
GuildAdsDBprofileMT = {
	__index = {
		getRaw = function(self, playerName)
			if playerName then
				local realm = GuildAdsDB.db;
				local t, mt;
				if realm.profiles[playerName] then
					t = realm.profiles[playerName];
					if getmetatable(t) == nil then
						setmetatable(t, {
							__index = GuildAdsMagicMT.__index;
						});
					end
				else
					t = {};
					setmetatable(t, {
						_table = realm.profiles;
						_key = playerName;
						__newindex = GuildAdsMagicMT.__newindex;
						__index = GuildAdsMagicMT.__index;
					});
				end
				return t;
			end	
		end;
	}
}

--[[ GuildAdsDB ]]
GuildAdsDB = { 
	_load = {};
	_channelDataTypes = {};
	VERSION = "20060512";
	CONFIG_PATH = { "Config" };
	PROFILE_PATH = { "Config", "Profile", GetCVar("realmName"), UnitName("player") };
}

function GuildAdsDB:RegisterDataType(dataType)
	if self._load then
		tinsert(self._load, dataType);
	else
		error("data type must registered at load time", 3);
	end
end

function GuildAdsDB:CreateAccount()
	local str = "";
	for i=1,4,1 do
		str = str .. string.char(math.random(65, 90));
	end
	str = str..self:GetCurrentTime();
	return str;
end

function GuildAdsDB:Initialize()
	-- import from the version 20060311
	if GuildAds.db.profile.Version == "20060311" then
		GuildAds.db.profile.Config.Account = GuildAds.db.Account;
		GuildAds.db.profile.Account = nil;
		GuildAds.db.profile.Version = nil;
		GuildAds.db.profile.Versions.DB = self.VERSION;
	end
	
	-- import from the version 20060426
	if GuildAds.db.profile.Metadata and GuildAds.db.profile.Metadata.Version == "20060426" then
		GuildAds.db.profile.Metadata = nil;
		GuildAds.db.profile.Versions.DB = self.VERSION;
	end
	
	-- check version
	local currentVersion = GuildAds.db.profile.Versions and GuildAds.db.profile.Versions.DB;
	if currentVersion ~= self.VERSION then
--~ 		GuildAds:CustomPrint(1, 0, 0, nil, nil, nil, "All data are deleted (except account ID)");
		local account = GuildAds.db.profile.Config and GuildAds.db.profile.Config.Account;
		GuildAds.db.profile.Data = {};
		GuildAds.db.profile.Config = nil;
		GuildAds.db.profile.Versions = {};
        GuildAds.db.profile.Versions.DataTypes = {};
		GuildAds.db.profile.Config = {};
		GuildAds.db.profile.Versions.DB = self.VERSION;
		
		GuildAds.db.profile.Config.Account = account;
		self.account = GuildAds.db.profile.Config.Account;
	end;

	-- initialize account
	self.account = GuildAds.db.profile.Config.Account;
	if not self.account then
		-- TODO : not defined : try to get it on the network
		GuildAds.db.profile.Config.Account = self:CreateAccount();
		self.account = GuildAds.db.profile.Config.Account;
	end
	
	-- initialize realm
--~     error(self.db);
--~ 	self.db = GuildAds.db.profile.Data[GuildAds.realmName];
	
--~     self.db = GuildAds.db.profile.Data.GuildAds.realmName;
	if not self.db then
     GuildAds.db.profile.Data ={};
--~     GuildAds.db.profile.Data.GuildAds = {};
    GuildAds.db.profile.Data[GuildAds.realmName] = {}
		GuildAds.db.profile.Data[GuildAds.realmName].profiles = {};
        GuildAds.db.profile.Data[GuildAds.realmName].channels = {};
--~         self.db = GuildAds.db.profile.Data;
--~ 		self.db = GuildAds.db.profile:set({"Data"}, GuildAds.realmName, 
--~ 		{
--~ 			profiles = {};
--~ 			channels = {}
--~ 		});
	end
    self.db = GuildAds.db.profile.Data[GuildAds.realmName];
--~     if not self.db then
--~     GuildAds.db.profile.Data ={};
--~     GuildAds.db.profile.Data.GuildAds = {};
--~     GuildAds.db.profile.Data.GuildAds.realmName = {}
--~ 		GuildAds.db.profile.Data.GuildAds.realmName.profiles = {};
--~         GuildAds.db.profile.Data.GuildAds.realmName.channels = {};
--~         self.db = GuildAds.db.profile.Data;
--~         
      
--~ 		{
--~ 			profiles = {};
--~ 			channels = {}
--~ 		});
--~ 	end
	
	-- initialize profile & channel
	self.profile = {};
	self.channel = {};
	setmetatable(GuildAdsDB.channel, GuildAdsDBchannelMT);
	setmetatable(GuildAdsDB.profile, GuildAdsDBprofileMT);
	
	-- initialize data types

	for _, dataType in pairs(self._load) do

		local name = dataType.metaInformations.name;
         GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,name);
		dataType.profile = self.profile;
		if dataType.metaInformations.parent == GuildAdsDataType.PROFILE then
			dataType.db = self.db.profiles;
			self.profile[name] = dataType;
		elseif dataType.metaInformations.parent == GuildAdsDataType.CHANNEL then
			self._channelDataTypes[name] = dataType;
--~              GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,"*" ..name);
		end

--~ GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,name);

		local version = GuildAds.db.profile.Versions.DataTypes[name];
		local current = version and version.Current or 0;
--~         GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,version);
		local mostRecent = version and version.MostRecent or dataType.metaInformations.version;
--~         GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,mostRecent);
		if type(dataType.Initialize)=="function" then
--~          GuildAds:CustomPrint(1, 0, 0, nil, nil, nil,"initialize");
			dataType:Initialize(current);
		end
        GuildAds.db.profile.Versions.DataTypes[name]={}
		GuildAds.db.profile.Versions.DataTypes[name].Current = dataType.metaInformations.version;
		GuildAds.db.profile.Versions.DataTypes[name].MostRecent = mostRecent;
	end
	
	self._load = nil;
end

function GuildAdsDB:ResetAll()
	GuildAds.db.profile.Versions.DB = "Reset";
	ReloadUI();
end

function GuildAdsDB:ResetChannel(channelName)
	GuildAdsDB.db.channels[GuildAdsDBchannelMT.getChannelKey(channelName)] = nil;
	ReloadUI();
end

function GuildAdsDB:ResetOthers()
	GuildAds.cmd:error("Not implemented");
end

--[[ About config ]]
function GuildAdsDB:GetConfigValue(path, key, defaultValue)
local node = GuildAds.db.char;
if (path) then
	for _,current in pairs(path) do 
		if (current) then
			GuildAds:CustomPrint(1, 0, 0, nil, nil, nil, "get"..current);
			if (not node[current]) then 
				node[current]={};
			end
			node = node[current];
		else
			break;
		end;
	end
end 
--~   if (not node[path[1]]) then 
--~     node[path[1]]={};
--~ 	end;
--~   if (not node[path[1]][path[2]] )then
--~  node[path[1]][path[2]]={};
--~  node[path[1]][path[2]][key]= defaultValue;
--~   end
--~   if (not GuildAds.db.char.path[1].path[2]) then 
--~   GuildAds.db.char.path[1].path[2]={};
--~   end
 
 if (not node[key]) then
 node[key]=defaultValue;
  return defaultValue
  else
	return node[key] ;
	end;
end

function GuildAdsDB:SetConfigValue(...)
    --arg = {...}
	local path, key, val = ...; --GuildAds.db:_GetArgs(arg)
	local node = GuildAds.db.char;
	 if (path) then

 for _,current in pairs(path) do 
  if (current)  then 
	if (not node[current]) then 
		GuildAds:CustomPrint(1, 0, 0, nil, nil, nil, "set error"..current);
		node[current]={};
	end;
	node = node[current];
  else
   break;
  end
  
 end
end 

	if( not key ) then error("No key supplied to AceDatabase:set.", 2) end

	local changed = node[key] ~= val;
	node[key] = val
	return changed;
--~ 	local node = GuildAds.db:_GetNode(path, TRUE)
--~ 	if( not key ) then error("No key supplied to AceDatabase:set.", 2) end
--~ 	local changed = node[key] ~= val;
--~ 	node[key] = val
--~ 	return changed;

end
--[[About time]]

--[[
	Provide a common time between different players.
	Return the number of minutes since 11/2/2005 00h00 (date of the WOW release in Europe)
	Get UTC time, using server time and PC date.
	do not use UTC ( !*t ) to avoid to much difference between server and PC time.
]]
function GuildAdsDB:GetCurrentTime()
	local hours,minutes = GetGameTime();
	local t = date("*t");
	t.wday = nil;
	t.yday = nil;
	t.isdst = nil;
	t.sec = nil;
	
	local local_min = t.hour*60+t.min;
	local server_min = hours*60+minutes; 
	
	local TimeShift = server_min-local_min;
	if math.abs(TimeShift)>=12*60 then
		if local_min<server_min then
			TimeShift = TimeShift-DayMin;
		else
			TimeShift = TimeShift+DayMin;
		end
	end
	
	t.hour, t.min = hours, minutes;
	-- local_min+TimeShift : server time not round between 0 and DayMin
	return math.floor(time(t) / 60)+math.floor((local_min+TimeShift)/DayMin)*DayMin-TimeRef;
end

-- A migrer dans GuildAds/ui/GuildAdsUI.lua
function GuildAdsDB:FormatTime(ref, relative)
	local delta;
	local prefix = "";
	if relative then
		delta = tonumber(ref);
	else
		delta = self:GetCurrentTime()-tonumber(ref);
	end
	
	if delta<0 then
		prefix = "-";
		delta = -delta;
	end
	
	month = math.floor(delta / MonthMin);
	deltamonth = math.fmod(delta, MonthMin);
	
	day = math.floor(deltamonth / DayMin);
	deltaday = math.fmod(delta, DayMin);
	
	hour = math.floor(deltaday / HourMin);
	minute = math.fmod(delta, HourMin);
	
	if (month > 0) then
		return prefix..string.format(GetText("LASTONLINE_MONTHS", nil, month), month);
	elseif (day > 0) then
		return prefix..string.format(GetText("LASTONLINE_DAYS", nil, day), day);
	elseif (hour > 0) then
		return prefix..string.format(GetText("LASTONLINE_HOURS", nil, hour), hour);
	else
		return prefix..string.format(GetText("GENERIC_MIN", nil, minute), minute);
	end
end
